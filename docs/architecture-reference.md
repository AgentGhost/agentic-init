# Project Architecture Reference

## Tech Stack
- **Language:** TypeScript (Strict mode)
- **Frontend:** Next.js (App Router) + Tailwind CSS
- **Backend:** Next.js Route Handlers (or Hono/NestJS)
- **Database:** PostgreSQL (via Drizzle ORM or Prisma)
- **Postgres Extensions:** pgvector, pg_trgm, TSVECTOR, JSONB, PostGIS

## Folder Structure
| Path | Contents |
|------|----------|
| `/src/app` | Next.js App Router pages, layouts, route handlers |
| `/src/components/ui` | Dumb components (buttons, inputs, cards) |
| `/src/components/features` | Complex business-logic components |
| `/src/lib` | Utilities, helpers, constants |
| `/src/db` | Schema, connection, queries |
| `/src/types` | Global TS interfaces |

## "Just Use Postgres" Philosophy
Do not introduce new infrastructure dependencies (Redis, RabbitMQ, ElasticSearch, MongoDB, Pinecone) unless extreme scaling demands it.

| Use Case | Native Solution |
|----------|----------------|
| Message Queues | Postgres `FOR UPDATE SKIP LOCKED` |
| Full-Text Search | `TSVECTOR`, `TSQUERY`, `pg_trgm` |
| Vector/AI Search | `pgvector` with HNSW indexes |
| Unstructured Data | `JSONB` with GIN indexes |
| Analytics | `MATERIALIZED VIEWS` with `REFRESH MATERIALIZED VIEW CONCURRENTLY` |
