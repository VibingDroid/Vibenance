import json
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, status

from ..config import settings
from ..dependencies import verify_api_key
from ..schemas import (
    HealthResponse,
    LoginRequest,
    LoginResponse,
    LogoutResponse,
    VerifyRequest,
    VerifyResponse,
)

router = APIRouter(prefix="/api/v1", tags=["auth"])

# Global in-memory cache for ongoing login flows: {process_id: phone_number}
_PENDING_LOGINS: dict[str, str] = {}


@router.get("/health", response_model=HealthResponse, dependencies=[Depends(verify_api_key)])
def health_check():
    import tr_api.profiles as tr_profiles
    from tr_api.exceptions import NoActiveProfile

    try:
        active_phone = tr_profiles.get_active_phone()
        prof = tr_profiles.get_active()
        has_cookies = prof.cookies_file.is_file() and prof.cookies_file.stat().st_size > 0
        return HealthResponse(
            status="ok",
            authenticated=bool(has_cookies),
            active_phone=active_phone,
        )
    except (NoActiveProfile, Exception):
        return HealthResponse(
            status="ok",
            authenticated=False,
            active_phone=None,
        )


@router.post("/auth/login", response_model=LoginResponse, dependencies=[Depends(verify_api_key)])
def initiate_login(req: LoginRequest):
    from tr_api.auth import initiate_login as tr_initiate, InvalidCredentials, RateLimited, LoginError

    try:
        init_res = tr_initiate(req.phone_number, req.pin)
        _PENDING_LOGINS[init_res.process_id] = req.phone_number
        return LoginResponse(
            process_id=init_res.process_id,
            countdown_seconds=init_res.countdown_in_seconds,
            message="Código enviado a la app de Trade Republic",
        )
    except InvalidCredentials as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "INVALID_CREDENTIALS", "message": str(e)},
        )
    except RateLimited as e:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={"error_code": "RATE_LIMITED", "message": str(e)},
        )
    except LoginError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error_code": "LOGIN_ERROR", "message": str(e)},
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error_code": "LOGIN_FAILED", "message": str(e)},
        )


@router.post("/auth/verify", response_model=VerifyResponse, dependencies=[Depends(verify_api_key)])
def verify_login(req: VerifyRequest):
    import tr_api.profiles as tr_profiles
    from tr_api.auth import complete_login as tr_complete, LoginError
    from tr_api.client import TrClient
    from tr_api.accounts import account_pairs

    phone = req.phone_number or _PENDING_LOGINS.get(req.process_id)
    if not phone:
        try:
            phone = tr_profiles.get_active_phone()
        except Exception:
            phone = None

    if not phone:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error_code": "PHONE_REQUIRED", "message": "phone_number must be provided or match login session"},
        )

    try:
        prof = tr_profiles.create(phone)
        tr_complete(req.process_id, req.code, prof)
        tr_profiles.set_active(phone)
        _PENDING_LOGINS.pop(req.process_id, None)

        # Verify credentials by discovering accounts
        client = TrClient.from_profile(prof)
        accounts_list = []
        try:
            pairs = account_pairs(client)
            accounts_list = [
                {
                    "securitiesAccountNumber": p.securities_account_number,
                    "cashAccountNumber": p.cash_account_number,
                    "productType": p.product_type,
                    "currency": p.currency,
                }
                for p in pairs
            ]
        except Exception:
            pass

        return VerifyResponse(
            authenticated=True,
            accounts=accounts_list,
            message="Sesión iniciada y verificada correctamente",
        )
    except LoginError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "VERIFY_FAILED", "message": str(e)},
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error_code": "VERIFY_ERROR", "message": str(e)},
        )


@router.post("/auth/logout", response_model=LogoutResponse, dependencies=[Depends(verify_api_key)])
def logout():
    import tr_api.profiles as tr_profiles
    from tr_api.exceptions import NoActiveProfile

    try:
        active_phone = tr_profiles.get_active_phone()
        tr_profiles.remove(active_phone)
    except NoActiveProfile:
        pass
    except Exception:
        pass

    return LogoutResponse(
        status="ok",
        message="Sesión cerrada y credenciales eliminadas",
    )
