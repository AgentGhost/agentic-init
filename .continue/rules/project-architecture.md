# Project Architecture & Vibe Guidelines

This document provides context for the AI Agent regarding the structure and coding standards of this project. Always adhere to these rules when generating, refactoring, or applying code.

---

## Core Tech Stack

| Category | Technology |
|----------|------------|
| Language | TypeScript (Strict mode enabled) |
| Frontend | Next.js (App Router) |
| Styling | Tailwind CSS |
| Backend/API | Next.js Route Handlers (or Hono/NestJS if running separately) |
| Database | PostgreSQL (via Drizzle ORM or Prisma) |

### PostgreSQL Extensions

- **pgvector** — AI/vector search
- **pg_trgm & TSVECTOR** — full-text and fuzzy search
- **JSONB** — unstructured data
- **PostGIS** — geo-routing (if needed)

> Maximize native PostgreSQL features to minimize external dependencies.

---

## Folder Structure

Our codebase is organized as follows. Always place new files in the correct directory:

| Directory | Purpose |
|-----------|---------|
| `/src/app` | Next.js App Router pages, layouts, and route handlers (`route.ts`) |
| `/src/components` | Reusable UI components |
| `/src/components/ui` | Dumb/Stateless components (buttons, inputs, cards) |
| `/src/components/features` | Complex components tied to specific business logic |
| `/src/lib` | Utility functions, helpers, and shared constants |
| `/src/db` | Database schema definitions, connection setup, and queries |
| `/src/types` | Global TypeScript interfaces and types |

---

## Coding Standards & "The Vibe"

### Strict TypeScript

Never use `any`. Always define explicit interfaces or types for props, API responses, and database models. Use `unknown` if the type is truly dynamic.

### Functional & Immutable

Prefer functional programming concepts. Avoid mutating state directly. Use pure functions where possible.

### Tailwind First

Use Tailwind CSS for all styling. Do not create separate `.css` modules unless absolutely necessary for complex animations. Use utility classes efficiently.

### Early Returns

Write code with early returns (guard clauses) to avoid deep nesting and improve readability.

```typescript
// BAD
if (user) {
  if (user.isActive) {
    doSomething();
  }
}

// GOOD
if (!user || !user.isActive) return;
doSomething();
```

### Modern Syntax

Use modern ES6+ features (optional chaining, nullish coalescing, destructuring).

### Error Handling

Use try/catch blocks for asynchronous operations. Always log errors descriptively and return proper HTTP status codes in API routes.

---

## "Just Use Postgres" Philosophy

Do not introduce new infrastructure dependencies (like Redis, RabbitMQ, ElasticSearch, MongoDB, or Pinecone) unless extreme horizontal scaling explicitly demands it.

| Use Case | Native Solution |
|---------|----------------|
| Message Queues/Workers | Standard Postgres tables with `FOR UPDATE SKIP LOCKED` |
| Full-Text & Typo-Tolerant Search | `TSVECTOR`, `TSQUERY`, and `pg_trgm` indexes |
| Vector Search / AI | `pgvector` extension with HNSW indexes |
| Unstructured Data | `JSONB` with GIN indexes |
| Dashboards & Heavy Analytics | `MATERIALIZED VIEWS` with `REFRESH MATERIALIZED VIEW CONCURRENTLY` |

---

## Agent Instructions

- **UI Components**: Default to a functional React component using Tailwind classes. Use named exports, not default exports.
- **Database Logic**: Ensure queries are type-safe and protect against SQL injection (using the ORM).
- **Complex Backend Features**: ALWAYS default to a native PostgreSQL implementation first based on the "Just Use Postgres" philosophy.
- **Explaining Code**: Be concise. Focus on the why rather than just reading the code back. Keep the flow fast and efficient.