"""
Gunicorn configuration for LottoTi production.

Tuning rationale:
- workers = 1 (required for WebSocket — single async worker)
- gevent worker class with gevent-websocket for Flask-SocketIO
- Graceful timeout to allow in-flight requests to complete
"""
import os

# --- Server socket ---
bind = f"0.0.0.0:{os.getenv('PORT', '5000')}"
backlog = 2048

# --- Workers ---
# gevent async worker — handles many concurrent connections
workers = 1
worker_class = "geventwebsocket.gunicorn.workers.GeventWebSocketWorker"
worker_connections = 1000

# --- Timeouts ---
timeout = 30          # Kill worker if request takes > 30s
graceful_timeout = 10  # Allow 10s for in-flight requests on restart
keepalive = 5          # Keep-alive for reverse proxy connections

# --- Restart workers periodically to prevent memory leaks ---
# High value to avoid killing active WebSocket connections (eventlet single worker)
max_requests = 10000
max_requests_jitter = 500

# --- Logging ---
accesslog = "-"  # stdout
errorlog = "-"   # stderr
loglevel = os.getenv("LOG_LEVEL", "info")
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# --- Process naming ---
proc_name = "lottoit-api"

# --- Security ---
limit_request_line = 8190
limit_request_fields = 100
limit_request_field_size = 8190

# --- Preload app ---
# Disabled: gevent monkey-patching must happen before app import
preload_app = False

# --- Hooks ---
def on_starting(server):
    server.log.info("LottoTi API starting...")

def post_fork(server, worker):
    server.log.info(f"Worker spawned (pid: {worker.pid})")

def worker_exit(server, worker):
    server.log.info(f"Worker exited (pid: {worker.pid})")
