# Docker Setup for Backend

This guide explains how to run the backend application, including PostgreSQL and Redis, using Docker.

## Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Quick Start

1. **Start the services:**

   ```bash
   docker-compose up --build
   ```

   This command builds the backend image and starts Node.js, Postgres, and Redis containers.
   - The backend runs on port **3001**.
   - Postgres runs on port **5432**.
   - Redis runs on port **6379**.

2. **Database Migrations:**
   The backend container is configured to automatically run `prisma migrate deploy` on startup.

   If you need to reset the database or seed it:

   ```bash
   # Enter the backend container
   docker-compose exec backend sh

   # Run seed
   npx prisma db seed
   ```

## Configuration

The `docker-compose.yml` sets the following environment variables for the containerized application:

- `DATABASE_URL`: `postgresql://postgres:postgres@postgres:5432/mylifepartner?schema=public`
- `REDIS_HOST`: `redis`
- `REDIS_PORT`: `6379`
- `NODE_ENV`: `development` (in compose) or `production` (in built image)

These allow the backend to communicate with the `postgres` and `redis` services within the docker network.

## Troubleshooting

- **Check Logs:**

   ```bash
   docker-compose logs -f
   ```

- **Rebuild:**
  If you install new dependencies, rebuild the images:

   ```bash
   docker-compose up --build
   ```

- **Database Persistence:**
  Postgres and Redis data are persisted in docker volumes (`postgres-data` and `redis-data`). To wipe data:
   ```bash
   docker-compose down -v
   ```
