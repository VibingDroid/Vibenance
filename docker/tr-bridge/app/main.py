import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .routers import auth, portfolio

logger = logging.getLogger("uvicorn.error")


async def _session_keepalive_loop():
    """
    Trade Republic idle session expires after ~5 minutes.
    A periodic GET to /api/v1/auth/web/session every ~270s keeps the session alive.
    """
    while True:
        try:
            await asyncio.sleep(270)
            import tr_api.profiles as tr_profiles
            from tr_api.auth import refresh_session
            from tr_api.exceptions import NoActiveProfile

            try:
                prof = tr_profiles.get_active()
                if prof.cookies_file.is_file() and prof.cookies_file.stat().st_size > 0:
                    logger.info("Executing background TR session keep-alive refresh...")
                    res = refresh_session(prof)
                    if res.ok:
                        logger.info(f"TR session refreshed successfully. Changed: {res.cookies_changed}")
                    else:
                        logger.warning(f"TR session refresh rejected: {res.error}")
            except (NoActiveProfile, Exception) as inner_e:
                logger.debug(f"No active profile for keep-alive: {inner_e}")
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"Error in session keep-alive loop: {e}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    task = asyncio.create_task(_session_keepalive_loop())
    try:
        yield
    finally:
        task.cancel()
        try:
            await task
        except asyncio.CancelledError:
            pass


app = FastAPI(
    title="Vibenance Trade Republic Bridge",
    description="Microservice bridge connecting Vibenance with Trade Republic API via cdamken/tr-api",
    version="0.1.0",
    lifespan=lifespan,
)

# Configure CORS for Flutter Web compatibility
origins = [o.strip() for o in settings.allowed_origins.split(",") if o.strip()]
if not origins:
    origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins if "*" not in origins else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(portfolio.router)


@app.get("/")
def root():
    return {"service": "vibenance-tr-bridge", "version": "0.1.0", "docs": "/docs"}
