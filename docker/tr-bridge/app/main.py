import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .routers import auth, portfolio

logger = logging.getLogger("uvicorn.error")

app = FastAPI(
    title="Vibenance Trade Republic Bridge",
    description="Microservice bridge connecting Vibenance with Trade Republic API via cdamken/tr-api",
    version="0.1.0",
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
