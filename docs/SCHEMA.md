# Platform V2 — Phase 1 schema

**Schemas:** `platform`, `assets` (Phase 1 only)

## ER (Phase 1)

```mermaid
erDiagram
  tenants ||--o{ integrations : has
  tenants ||--o{ scans : runs
  integrations ||--o{ scans : target
  scans ||--o{ collection_runs : produces
  scans ||--o{ resources : snapshot
  scans ||--o{ relationships : snapshot
  scans ||--o{ collection_events : audit

  tenants {
    uuid id PK
    text name
    text slug UK
    text status
  }

  integrations {
    uuid id PK
    uuid tenant_id FK
    text account_id
    text role_arn
    text external_id
    jsonb regions
  }

  scans {
    uuid id PK
    uuid tenant_id FK
    uuid integration_id FK
    text status
    uuid trace_id
  }

  collection_runs {
    uuid id PK
    uuid scan_id FK
    text account_id
    text manifest_s3_uri
  }

  resources {
    uuid tenant_id PK
    uuid scan_id PK
    text resource_id PK
    text resource_type
    jsonb properties
    timestamptz first_seen_at
    timestamptz last_seen_at
  }

  relationships {
    uuid tenant_id PK
    uuid scan_id PK
    text from_resource_id PK
    text to_resource_id PK
    text relationship_type PK
  }
```

## Scan status lifecycle

```
created → queued → collecting → collected → ingesting → inventory_ready
  → evaluating → completed | completed_with_errors | failed
```

Phase 2+ backend transitions `evaluating` → terminal states when policy runs.

## RLS

Every tenant-scoped table uses `platform.set_tenant(uuid)` per request/worker session.

Policies compare `tenant_id = platform.current_tenant_id()`.

## Tables

| Schema | Table | Notes |
|--------|-------|-------|
| platform | tenants | No RLS (bootstrap/admin) |
| platform | integrations | AWS v1; `external_id` encrypted at app layer |
| platform | scans | Full status enum |
| platform | collection_runs | One row per scan/account |
| assets | resources | Immutable per scan; INSERT only |
| assets | relationships | Graph edges per scan |
| assets | collection_events | Append-only audit |
