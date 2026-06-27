-- platform-db migration 014
-- Asset lineage metadata + soft-delete columns on platform entities

ALTER TABLE assets.resources
  ADD COLUMN IF NOT EXISTS lineage JSONB NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN assets.resources.lineage IS
  'Provenance: collector_version, collection_run_id, manifest_s3_uri, snapshot_s3_uri, plugin. '
  'policy_run_id lives on findings.evaluation_runs (scan-scoped).';

CREATE INDEX IF NOT EXISTS assets_resources_lineage_gin
  ON assets.resources USING gin (lineage);

ALTER TABLE platform.tenants
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

ALTER TABLE platform.integrations
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

ALTER TABLE platform.users
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

COMMENT ON COLUMN platform.tenants.deleted_at IS
  'Soft delete — never hard-delete tenant rows; GDPR purge is a documented future workflow.';

COMMENT ON COLUMN platform.integrations.deleted_at IS
  'Soft delete — integrations are deactivated, not removed.';

-- Recreate assets.current to expose lineage column (must drop — CREATE OR REPLACE cannot add columns)
DROP VIEW IF EXISTS assets.current;

CREATE VIEW assets.current AS
SELECT DISTINCT ON (r.tenant_id, r.resource_id)
  r.tenant_id,
  r.scan_id,
  r.resource_id,
  r.resource_type,
  r.provider,
  r.provider_type,
  r.integration_id,
  r.account_id,
  r.region,
  r.properties,
  r.tags,
  r.collected_at,
  r.first_seen_at,
  r.last_seen_at,
  r.ingested_at,
  r.lineage,
  s.completed_at AS source_scan_completed_at
FROM assets.resources r
JOIN platform.scans s
  ON s.id = r.scan_id
 AND s.tenant_id = r.tenant_id
WHERE s.status IN ('completed', 'completed_with_errors')
ORDER BY
  r.tenant_id,
  r.resource_id,
  s.completed_at DESC NULLS LAST,
  r.ingested_at DESC;

INSERT INTO platform.schema_migrations (version)
VALUES ('014_lineage_soft_delete')
ON CONFLICT (version) DO NOTHING;
