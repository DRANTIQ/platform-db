# platform-db

Version-controlled **Postgres schemas and migrations** for Platform V2.

## Purpose

| This repo | Other repos |
|-----------|-------------|
| **All DDL** — CREATE SCHEMA, tables, indexes | **No DDL** — only application code |
| Single migration history | `compliance-engine` uses the DB |

**Database:** Shared Supabase Postgres (Session pooler)  
**Schemas:** `platform`, `assets`, `policy`, `findings`, `compliance`  
**Rule:** Never alter legacy schemas (e.g. Steampipe `public.*` tables).

## Layout

```
migrations/     Sequential SQL (001_, 002_, …)
seeds/          Optional dev/reference data
scripts/        migrate.sh
docs/           Schema documentation
```

## Apply migrations

```bash
export DATABASE_URL="postgresql://...@pooler.supabase.com:6543/postgres?sslmode=require"
./scripts/migrate.sh
```

Never commit `DATABASE_URL` or `.env`.

## Related repos

| Repo | Uses DB |
|------|---------|
| **platform-db** | **Owns migrations** |
| **compliance-engine** | Reads/writes all V2 schemas |
| **platform-collectors** | No DB access |

## Planning

**infra-state-docs/new arch/docs/PLATFORM_DB_REPO.md**

## Migration rules

1. Forward-only in production — never edit applied migration files.
2. One file per change, numbered sequentially.
3. PR review required for all DDL.
4. Only touch V2 schemas listed above.

## Status

Migration `001_create_schemas.sql` ready — run once on Supabase before Phase 1.
