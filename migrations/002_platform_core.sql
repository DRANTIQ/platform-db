-- platform-db migration 002
-- Platform V2 core: tenants, integrations, scans, collection_runs

CREATE TABLE platform.tenants (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  slug          TEXT NOT NULL UNIQUE,
  status        TEXT NOT NULL DEFAULT 'active'
                CHECK (status IN ('active', 'suspended')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE platform.integrations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES platform.tenants(id),
  provider        TEXT NOT NULL DEFAULT 'aws' CHECK (provider = 'aws'),
  account_id      TEXT NOT NULL CHECK (account_id ~ '^[0-9]{12}$'),
  role_arn        TEXT NOT NULL,
  external_id     TEXT NOT NULL,
  regions         JSONB NOT NULL DEFAULT '[]'::jsonb,
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active', 'invalid', 'disabled')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, provider, account_id)
);

CREATE INDEX integrations_tenant_idx ON platform.integrations (tenant_id);

CREATE TABLE platform.scans (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES platform.tenants(id),
  integration_id  UUID NOT NULL REFERENCES platform.integrations(id),
  status          TEXT NOT NULL DEFAULT 'created'
                  CHECK (status IN (
                    'created', 'queued', 'collecting', 'collected',
                    'ingesting', 'inventory_ready', 'evaluating',
                    'completed', 'completed_with_errors', 'failed'
                  )),
  error           JSONB,
  trace_id        UUID NOT NULL DEFAULT gen_random_uuid(),
  started_at      TIMESTAMPTZ,
  completed_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX scans_tenant_created_idx ON platform.scans (tenant_id, created_at DESC);
CREATE INDEX scans_tenant_status_idx ON platform.scans (tenant_id, status);
CREATE INDEX scans_integration_idx ON platform.scans (integration_id);

CREATE TABLE platform.collection_runs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES platform.tenants(id),
  scan_id         UUID NOT NULL REFERENCES platform.scans(id) ON DELETE CASCADE,
  integration_id  UUID NOT NULL REFERENCES platform.integrations(id),
  account_id      TEXT NOT NULL CHECK (account_id ~ '^[0-9]{12}$'),
  status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'running', 'completed', 'failed', 'completed_with_errors')),
  manifest_s3_uri TEXT,
  resource_count  INTEGER,
  error           JSONB,
  started_at      TIMESTAMPTZ,
  completed_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, scan_id, account_id)
);

CREATE INDEX collection_runs_scan_idx ON platform.collection_runs (tenant_id, scan_id);
