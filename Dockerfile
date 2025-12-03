FROM python:3.10-alpine AS builder

WORKDIR /app

RUN apk add --no-cache gcc python3-dev musl-dev linux-headers

COPY requirements.txt .

RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

FROM python:3.10-alpine

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup && \
    mkdir -p /app && \
    chown -R appuser:appgroup /app

WORKDIR /app

COPY --from=builder --chown=appuser:appgroup /opt/venv /opt/venv

COPY --chown=appuser:appgroup calculator/ ./calculator/

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "from calculator.calculator import add; assert add(1,1) == 2" || exit 1

CMD ["python", "calculator/calculator.py"]
