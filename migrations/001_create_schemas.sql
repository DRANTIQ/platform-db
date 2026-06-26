-- platform-db migration 001
-- Platform V2 — create schemas only (Supabase shared Postgres)
-- DO NOT alter legacy schemas (public Steampipe tables, etc.)

CREATE SCHEMA IF NOT EXISTS platform;
CREATE SCHEMA IF NOT EXISTS assets;
CREATE SCHEMA IF NOT EXISTS policy;
CREATE SCHEMA IF NOT EXISTS findings;
CREATE SCHEMA IF NOT EXISTS compliance;

COMMENT ON SCHEMA platform IS 'Platform V2: tenants, users, scans, integrations';
COMMENT ON SCHEMA assets IS 'Platform V2: inventory, relationships, collection_events';
COMMENT ON SCHEMA policy IS 'Platform V2: unified policy library';
COMMENT ON SCHEMA findings IS 'Platform V2: findings and workflow';
COMMENT ON SCHEMA compliance IS 'Platform V2: framework mappings and scores';

CREATE TABLE IF NOT EXISTS platform.schema_migrations (
  version     TEXT PRIMARY KEY,
  applied_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  checksum    TEXT
);

INSERT INTO platform.schema_migrations (version)
VALUES ('001_create_schemas')
ON CONFLICT (version) DO NOTHING;
