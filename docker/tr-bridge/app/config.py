from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="", case_sensitive=False)

    tr_bridge_api_key: str = ""
    tr_state_dir: str = "/app/data/tr_state"
    allowed_origins: str = "*"
    request_timeout: float = 30.0
    ws_timeout: float = 90.0

    @property
    def state_path(self) -> Path:
        p = Path(self.tr_state_dir)
        p.mkdir(parents=True, exist_ok=True)
        return p


settings = Settings()
