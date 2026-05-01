# ============================================================
# LottoTi Backend — Multi-stage Production Dockerfile
# ============================================================
# Stage 1: Build dependencies in a temporary layer
# Stage 2: Slim runtime image with non-root user
# ============================================================

# --- Stage 1: Builder ---
FROM python:3.12-slim AS builder

WORKDIR /build

# Install build dependencies for psycopg2 and Pillow
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev libjpeg62-turbo-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# --- Stage 2: Runtime ---
FROM python:3.12-slim AS runtime

# Security: non-root user
RUN groupadd -r lottoit && useradd -r -g lottoit -d /app -s /sbin/nologin lottoit

# Runtime dependencies only (no compiler)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 libjpeg62-turbo curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder
COPY --from=builder /install /usr/local

WORKDIR /app

# Copy application code
COPY --chown=lottoit:lottoit . .

# Make entrypoint executable
RUN chmod +x /app/docker-entrypoint.sh

# Create necessary directories
RUN mkdir -p /app/instance /app/uploads /app/logs \
    && chown -R lottoit:lottoit /app

# Switch to non-root user
USER lottoit

# Environment defaults
ENV FLASK_ENV=production
ENV FLASK_APP=run.py
ENV PORT=5000

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:5000/api/health || exit 1

# Entrypoint handles migrations + startup
ENTRYPOINT ["/app/docker-entrypoint.sh"]
