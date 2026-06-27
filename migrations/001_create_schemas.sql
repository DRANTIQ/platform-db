-- platform-db migration 001
-- Platform V2 — create schemas only (Supabase shared Postgres)
-- DO NOT alter legacy schemas (public Steampipe tables, compliance.*, etc.)

CREATE SCHEMA IF NOT EXISTS platform;
CREATE SCHEMA IF NOT EXISTS assets;

COMMENT ON SCHEMA platform IS 'Platform V2: tenants, integrations, scans, collection_runs';
COMMENT ON SCHEMA assets IS 'Platform V2: inventory resources, relationships, collection_events';

CREATE TABLE IF NOT EXISTS platform.schema_migrations (
  version     TEXT PRIMARY KEY,
  applied_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  checksum    TEXT
);

INSERT INTO platform.schema_migrations (version)
VALUES ('001_create_schemas')
ON CONFLICT (version) DO NOTHING;
