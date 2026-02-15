#!/bin/sh

# Wait for database (optional, but good practice in some setups, though depends checks in compose usually handle this)
# A more robust wait-for-it script might be needed if depends_on isn't sufficient for the DB being *ready* vs just *started*

echo "Running migrations..."
prisma migrate deploy


echo "Starting application..."
exec "$@"

