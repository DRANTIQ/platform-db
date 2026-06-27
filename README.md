# platform-db

Version-controlled **Postgres schemas and migrations** for Platform V2.

## Purpose

| This repo | Other repos |
|-----------|-------------|
| **All DDL** — CREATE SCHEMA, tables, indexes, RLS | **No DDL** — application code only |
| Single migration history | `compliance-engine` (→ `platform-backend`) uses the DB |

**Database:** Shared Supabase Postgres (session pooler, `sslmode=require`)  
**Phase 1 schemas:** `platform`, `assets` only  
**Rule:** Never alter legacy schemas (`public.*`, legacy `compliance.*`).

## Layout

```
migrations/     Sequential SQL (001_, 002_, …)
seeds/          Optional dev bootstrap (tenant only)
scripts/        migrate.py, check_schema.py, rollback_v2.sql
docs/           Schema reference
```

## Apply migrations

Copy credentials locally (never commit):

```bash
cp .env.example .env
# edit DATABASE_URL
```

**Python (recommended — tracks checksums):**

```bash
python -m venv .venv && source .venv/bin/activate  # or .venv\Scripts\activate on Windows
pip install -r requirements.txt
export DATABASE_URL="postgresql://...@pooler.supabase.com:6543/postgres?sslmode=require"
python scripts/migrate.py
python scripts/check_schema.py
```

**PowerShell:**

```powershell
$env:DATABASE_URL = "postgresql://...@pooler.supabase.com:6543/postgres?sslmode=require"
.\scripts\migrate.ps1
python scripts\check_schema.py
```

## Rollback (dev only)

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/rollback_v2.sql
```

Drops **only** `platform` and `assets` schemas. Legacy data is untouched.

## Migration rules

1. Forward-only in production — never edit applied migration files.
2. One numbered file per change; record in `platform.schema_migrations`.
3. PR review required for all DDL.
4. Phase 1 excludes `policy`, `findings`, and a V2 `compliance` schema.

## Related repos

| Repo | Role |
|------|------|
| **platform-db** | Owns all DDL |
| **compliance-engine** | Platform V2 backend API + workers |
| **platform-collectors** | No Postgres access |

## Status

Phase 1 migrations: `001`–`004` (schemas, core tables, assets, RLS).
