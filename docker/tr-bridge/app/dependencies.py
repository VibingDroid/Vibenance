import os
from pathlib import Path
from typing import Optional
from fastapi import Header, HTTPException, status

from .config import settings

# Configure tr_api profile base directory to point to persistent state
os.environ["TR_API_DIR"] = str(settings.state_path)
import tr_api.profiles as tr_profiles
tr_profiles.BASE_DIR = Path(settings.tr_state_dir)
tr_profiles.PROFILES_DIR = tr_profiles.BASE_DIR / "profiles"
tr_profiles.ACTIVE_FILE = tr_profiles.BASE_DIR / "active"

from tr_api import TrClient
from tr_api.exceptions import NoActiveProfile, ProfileNotFound, SessionExpired


async def verify_api_key(x_bridge_api_key: Optional[str] = Header(None)) -> None:
    if not settings.tr_bridge_api_key:
        # Si no se configuró clave en el bridge, se permite el acceso
        return
    if not x_bridge_api_key or x_bridge_api_key != settings.tr_bridge_api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "INVALID_BRIDGE_API_KEY", "message": "Invalid or missing X-Bridge-Api-Key"},
        )


def get_tr_client() -> TrClient:
    try:
        return TrClient.from_active()
    except (NoActiveProfile, ProfileNotFound) as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "TR_NOT_AUTHENTICATED", "message": str(e)},
        )
    except SessionExpired as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "TR_SESSION_EXPIRED", "message": str(e)},
        )
