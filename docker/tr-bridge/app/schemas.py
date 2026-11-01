from typing import Any, List, Optional
from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str = "ok"
    authenticated: bool
    active_phone: Optional[str] = None


class LoginRequest(BaseModel):
    phone_number: str = Field(..., description="E.164 phone number, e.g. +34600000000")
    pin: str = Field(..., description="4-digit app PIN")


class LoginResponse(BaseModel):
    process_id: str
    countdown_seconds: int = 60
    message: str = "Código enviado a la app de Trade Republic"


class VerifyRequest(BaseModel):
    process_id: str
    code: Optional[str] = Field(default="", description="4-digit code from TR SMS/push or empty if push notification confirmed in-app")
    phone_number: Optional[str] = None


class VerifyResponse(BaseModel):
    authenticated: bool
    accounts: List[Any] = []
    message: str = "Sesión iniciada correctamente"


class LogoutResponse(BaseModel):
    status: str = "ok"
    message: str = "Sesión cerrada y credenciales eliminadas"


class PositionItem(BaseModel):
    isin: str
    name: str
    instrument_type: str = "stock"
    quantity: float
    average_buy_in: float
    current_price: float
    current_value: float
    profit_loss_abs: float
    profit_loss_pct: float


class SavingsPlanItem(BaseModel):
    id: str
    isin: str
    name: str
    amount: float
    interval: str
    next_execution_date: Optional[str] = None
    paused: bool = False


class PortfolioSummary(BaseModel):
    total_invested: float
    current_value: float
    profit_loss_abs: float
    profit_loss_pct: float
    cash_balance: float
    currency: str = "EUR"
    iban: Optional[str] = None


class PortfolioSnapshotResponse(BaseModel):
    summary: PortfolioSummary
    positions: List[PositionItem]
    savings_plans: List[SavingsPlanItem] = []
    fetched_at: str


class TransactionItem(BaseModel):
    id: str
    timestamp: str
    title: str
    subtitle: Optional[str] = None
    amount: float
    currency: str = "EUR"
    event_type: str
    status: Optional[str] = None
    isin: Optional[str] = None


class TransactionsResponse(BaseModel):
    items: List[TransactionItem]
    count: int
