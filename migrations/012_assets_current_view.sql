-- platform-db migration 012
-- Derived current inventory view (NOT source of truth — scan-scoped assets.resources is)

CREATE OR REPLACE VIEW assets.current AS
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

COMMENT ON VIEW assets.current IS
  'Latest resource row per (tenant_id, resource_id) from most recent successful scan. '
  'Policy evaluation uses scan-scoped assets.resources, not this view.';

INSERT INTO platform.schema_migrations (version)
VALUES ('012_assets_current_view')
ON CONFLICT (version) DO NOTHING;
