# Multi-stage build for security and optimization
FROM python:3.10-alpine AS builder

# Set working directory
WORKDIR /app

# Copy only requirements first (layer caching)
COPY requirements.txt .

# Install dependencies in a virtual environment
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# Final stage - minimal runtime image
FROM python:3.10-alpine

# Security: Create non-root user
RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup && \
    mkdir -p /app && \
    chown -R appuser:appgroup /app

# Set working directory
WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder --chown=appuser:appgroup /opt/venv /opt/venv

# Copy application code
COPY --chown=appuser:appgroup calculator/ ./calculator/

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Switch to non-root user
USER appuser

# Health check (optional but recommended)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "from calculator.calculator import add; assert add(1,1) == 2" || exit 1

# Run the application
CMD ["python", "calculator/calculator.py"]
