import logging
from datetime import datetime, timezone
from typing import Any, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status

from ..config import settings
from ..dependencies import get_tr_client, verify_api_key
from ..schemas import (
    PortfolioSnapshotResponse,
    PortfolioSummary,
    PositionItem,
    SavingsPlanItem,
    TransactionItem,
    TransactionsResponse,
)
from tr_api import TrClient
from tr_api.exceptions import SessionExpired

logger = logging.getLogger("uvicorn.error")
router = APIRouter(prefix="/api/v1", tags=["portfolio"], dependencies=[Depends(verify_api_key)])


def _auto_refresh_session_if_needed(client: TrClient) -> bool:
    """Try refreshing session via /api/v1/auth/web/session if WebSocket or REST fails with 401."""
    try:
        from tr_api.auth import refresh_session
        res = refresh_session(client.profile)
        if res.ok:
            client._load_cookies()
            return True
    except Exception as e:
        logger.warning(f"Automatic session refresh failed: {e}")
    return False


@router.get("/portfolio/snapshot", response_model=PortfolioSnapshotResponse)
def get_portfolio_snapshot(
    enrich: bool = Query(True, description="Enrich holdings with realtime quotes and names"),
    include_savings_plans: bool = Query(True, description="Include active savings plans"),
    client: TrClient = Depends(get_tr_client),
):
    import tr_api.portfolio as tr_portfolio
    import tr_api.savings_plans as tr_savings

    try:
        # Obtain snapshot with live prices and cash
        raw_data = tr_portfolio.snapshot_full(client, timeout=settings.ws_timeout)
    except Exception as first_exc:
        # Check if error is due to session expiration (WebSocket 401 or SessionExpired)
        err_str = str(first_exc)
        if "401" in err_str or isinstance(first_exc, SessionExpired):
            logger.info("TR session rejected with 401, attempting auto-refresh...")
            if _auto_refresh_session_if_needed(client):
                try:
                    raw_data = tr_portfolio.snapshot_full(client, timeout=settings.ws_timeout)
                except Exception as retry_exc:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail={"error_code": "TR_SESSION_EXPIRED", "message": str(retry_exc)},
                    )
            else:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail={"error_code": "TR_SESSION_EXPIRED", "message": err_str},
                )
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={"error_code": "SNAPSHOT_FETCH_FAILED", "message": err_str},
            )

    # Extract positions and cash
    positions_raw = []
    portfolio_obj = raw_data.get("portfolio") or {}
    if isinstance(portfolio_obj, dict):
        positions_raw = portfolio_obj.get("positions") or []

    cash_raw = raw_data.get("cash")
    cash_balance = 0.0
    currency = "EUR"
    iban = None

    if isinstance(cash_raw, list):
        for c in cash_raw:
            if isinstance(c, dict):
                cash_balance += float(c.get("amount", 0.0) or 0.0)
                currency = c.get("currencyId", currency)
    elif isinstance(cash_raw, dict):
        cash_balance = float(cash_raw.get("amount", 0.0) or 0.0)
        currency = cash_raw.get("currencyId", currency)
        iban = cash_raw.get("iban")

    parsed_positions: list[PositionItem] = []
    total_invested = 0.0
    current_invested_value = 0.0

    for p in positions_raw:
        if not isinstance(p, dict):
            continue
        isin = str(p.get("instrumentId", ""))
        name = str(p.get("name", isin))
        
        # Net quantity / shares
        qty = float(p.get("netSize", 0.0) or 0.0)
        avg_buy_in = float(p.get("averageBuyIn", 0.0) or 0.0)
        
        # Current ticker price
        current_price = 0.0
        ticker_data = p.get("currentPrice")
        if isinstance(ticker_data, (int, float)):
            current_price = float(ticker_data)
        elif isinstance(ticker_data, dict):
            current_price = float(ticker_data.get("last", {}).get("price", 0.0) or 0.0)
        elif isinstance(ticker_data, str):
            try:
                current_price = float(ticker_data)
            except ValueError:
                current_price = 0.0
        
        if current_price <= 0.0 and avg_buy_in > 0.0:
            current_price = avg_buy_in

        invested_amt = qty * avg_buy_in
        cur_val = qty * current_price
        p_l_abs = cur_val - invested_amt
        p_l_pct = (p_l_abs / invested_amt * 100.0) if invested_amt > 0 else 0.0

        total_invested += invested_amt
        current_invested_value += cur_val

        # Determine instrument type
        instrument_type = "stock"
        if tr_portfolio._is_bond_name(name):
            instrument_type = "bond"
        elif "ETF" in name.upper() or "UCITS" in name.upper():
            instrument_type = "etf"
        elif "CRYPTO" in name.upper() or isin.startswith("XF"):
            instrument_type = "crypto"

        parsed_positions.append(
            PositionItem(
                isin=isin,
                name=name,
                instrument_type=instrument_type,
                quantity=round(qty, 6),
                average_buy_in=round(avg_buy_in, 4),
                current_price=round(current_price, 4),
                current_value=round(cur_val, 2),
                profit_loss_abs=round(p_l_abs, 2),
                profit_loss_pct=round(p_l_pct, 2),
            )
        )

    # Sort positions by portfolio weight descending
    parsed_positions.sort(key=lambda x: x.current_value, reverse=True)

    # Savings plans
    parsed_savings: list[SavingsPlanItem] = []
    if include_savings_plans:
        try:
            plans_raw = tr_savings.list_plans(client)
            for sp in plans_raw:
                if isinstance(sp, dict):
                    s_id = str(sp.get("id", ""))
                    s_isin = str(sp.get("instrumentId", ""))
                    s_name = str(sp.get("name", s_isin))
                    s_amount = float(sp.get("amount", 0.0) or 0.0)
                    s_interval = str(sp.get("interval", "monthly"))
                    next_date = sp.get("nextExecutionDate")
                    if isinstance(sp.get("startDate"), dict):
                        next_date = next_date or sp["startDate"].get("nextExecutionDate")
                    s_paused = bool(sp.get("paused", False))

                    parsed_savings.append(
                        SavingsPlanItem(
                            id=s_id,
                            isin=s_isin,
                            name=s_name,
                            amount=s_amount,
                            interval=s_interval,
                            next_execution_date=str(next_date) if next_date else None,
                            paused=s_paused,
                        )
                    )
        except Exception:
            pass

    total_pl_abs = current_invested_value - total_invested
    total_pl_pct = (total_pl_abs / total_invested * 100.0) if total_invested > 0 else 0.0

    summary = PortfolioSummary(
        total_invested=round(total_invested, 2),
        current_value=round(current_invested_value, 2),
        profit_loss_abs=round(total_pl_abs, 2),
        profit_loss_pct=round(total_pl_pct, 2),
        cash_balance=round(cash_balance, 2),
        currency=currency,
        iban=iban,
    )

    return PortfolioSnapshotResponse(
        summary=summary,
        positions=parsed_positions,
        savings_plans=parsed_savings,
        fetched_at=datetime.now(timezone.utc).isoformat(),
    )


@router.get("/transactions", response_model=TransactionsResponse)
def get_transactions(
    since: Optional[str] = Query(None, description="Optional ISO datetime or date threshold"),
    client: TrClient = Depends(get_tr_client),
):
    import tr_api.transactions as tr_tx

    def _fetch_tx():
        if since:
            since_dt = datetime.fromisoformat(since.replace("Z", "+00:00"))
            return tr_tx.fetch_since(client, since_dt)
        return tr_tx.fetch_all(client, max_pages=10)

    try:
        raw_items = _fetch_tx()
    except Exception as first_exc:
        err_str = str(first_exc)
        if "401" in err_str or isinstance(first_exc, SessionExpired):
            logger.info("TR session rejected with 401 in tx, attempting auto-refresh...")
            if _auto_refresh_session_if_needed(client):
                try:
                    raw_items = _fetch_tx()
                except Exception as retry_exc:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail={"error_code": "TR_SESSION_EXPIRED", "message": str(retry_exc)},
                    )
            else:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail={"error_code": "TR_SESSION_EXPIRED", "message": err_str},
                )
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={"error_code": "TX_FETCH_FAILED", "message": err_str},
            )

    items: list[TransactionItem] = []
    for it in raw_items:
        if not isinstance(it, dict):
            continue
        tx_id = str(it.get("id", ""))
        timestamp = str(it.get("timestamp", ""))
        event_type = str(it.get("eventType", "UNKNOWN"))
        title = str(it.get("title", it.get("header", event_type)))
        subtitle = it.get("subtitle", it.get("subHeader"))
        
        # Amount
        amount = 0.0
        amt_obj = it.get("amount")
        if isinstance(amt_obj, (int, float)):
            amount = float(amt_obj)
        elif isinstance(amt_obj, dict):
            amount = float(amt_obj.get("value", 0.0) or 0.0)
        
        currency = "EUR"
        if isinstance(amt_obj, dict):
            currency = amt_obj.get("currency", "EUR")

        items.append(
            TransactionItem(
                id=tx_id,
                timestamp=timestamp,
                title=title,
                subtitle=str(subtitle) if subtitle else None,
                amount=amount,
                currency=currency,
                event_type=event_type,
                status=it.get("status"),
                isin=it.get("instrumentId"),
            )
        )

    return TransactionsResponse(items=items, count=len(items))
