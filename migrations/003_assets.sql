-- platform-db migration 003
-- Platform V2 asset inventory (immutable per scan — INSERT only in application code)

CREATE TABLE assets.resources (
  tenant_id       UUID NOT NULL,
  scan_id         UUID NOT NULL,
  resource_id     TEXT NOT NULL,
  resource_type   TEXT NOT NULL,
  provider        TEXT NOT NULL DEFAULT 'aws',
  provider_type   TEXT NOT NULL,
  integration_id  UUID NOT NULL,
  account_id      TEXT NOT NULL CHECK (account_id ~ '^[0-9]{12}$'),
  region          TEXT,
  properties      JSONB NOT NULL DEFAULT '{}'::jsonb,
  tags            JSONB NOT NULL DEFAULT '{}'::jsonb,
  collected_at    TIMESTAMPTZ NOT NULL,
  first_seen_at   TIMESTAMPTZ NOT NULL,
  last_seen_at    TIMESTAMPTZ NOT NULL,
  ingested_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, scan_id, resource_id)
);

CREATE INDEX assets_resources_scan_type_idx
  ON assets.resources (tenant_id, scan_id, resource_type);
CREATE INDEX assets_resources_resource_id_idx
  ON assets.resources (tenant_id, resource_id);
CREATE INDEX assets_resources_properties_gin
  ON assets.resources USING gin (properties);

CREATE TABLE assets.relationships (
  tenant_id           UUID NOT NULL,
  scan_id             UUID NOT NULL,
  from_resource_id    TEXT NOT NULL,
  to_resource_id      TEXT NOT NULL,
  relationship_type   TEXT NOT NULL,
  properties          JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, scan_id, from_resource_id, to_resource_id, relationship_type)
);

CREATE INDEX assets_relationships_from_idx
  ON assets.relationships (tenant_id, scan_id, from_resource_id);
CREATE INDEX assets_relationships_to_idx
  ON assets.relationships (tenant_id, scan_id, to_resource_id);

CREATE TABLE assets.collection_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID NOT NULL,
  scan_id     UUID NOT NULL,
  event_type  TEXT NOT NULL,
  payload     JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX assets_collection_events_scan_idx
  ON assets.collection_events (tenant_id, scan_id, created_at);
