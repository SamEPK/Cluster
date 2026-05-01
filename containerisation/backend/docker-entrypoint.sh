#!/bin/bash
set -e

echo "=== LottoTi API — Starting ==="

# Wait for database to be ready
echo "Waiting for database..."
for i in $(seq 1 30); do
    if python -c "
from sqlalchemy import text
from app import create_app
from app.extensions import db
app = create_app()
with app.app_context():
    with db.engine.connect() as conn:
        conn.execute(text('SELECT 1'))
" 2>/dev/null; then
        echo "Database is ready."
        break
    fi
    echo "  Attempt $i/30 — waiting 2s..."
    sleep 2
done

# Run database migrations
echo "Running database migrations..."
flask db upgrade 2>/dev/null || {
    echo "No migrations to run or migration system not initialized."
    echo "Creating tables directly..."
    python -c "
from app import create_app
from app.extensions import db
app = create_app()
with app.app_context():
    db.create_all()
    print('Tables created successfully.')
"
}

# Seed database if empty (first run only)
if [ "${SEED_DB:-false}" = "true" ]; then
    echo "Seeding database..."
    python seed.py || echo "Seeding skipped or already done."
fi

echo "=== Starting Gunicorn ==="
exec gunicorn -c gunicorn.conf.py run:app
