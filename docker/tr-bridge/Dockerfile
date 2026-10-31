FROM python:3.12-slim

# Install system dependencies (git required for git+ dependencies, curl for healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first to leverage Docker layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ /app/app/

# Create persistent state directory with appropriate permissions
RUN mkdir -p /app/data/tr_state && chmod 700 /app/data/tr_state

ENV PYTHONUNBUFFERED=1 \
    TR_STATE_DIR=/app/data/tr_state \
    ALLOWED_ORIGINS=*

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/v1/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
