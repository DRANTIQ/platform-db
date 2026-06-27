-- platform-db migration 005
-- Policy library schema (Phase 2) — NOT legacy compliance schema

CREATE SCHEMA IF NOT EXISTS policy;

CREATE TABLE policy.policies (
  policy_id       TEXT PRIMARY KEY,
  title           TEXT NOT NULL,
  provider        TEXT NOT NULL DEFAULT 'aws',
  resource_type   TEXT NOT NULL,
  provider_type   TEXT,
  default_severity TEXT NOT NULL DEFAULT 'medium'
                  CHECK (default_severity IN ('critical', 'high', 'medium', 'low', 'info')),
  enabled         BOOLEAN NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE policy.policy_versions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id       TEXT NOT NULL REFERENCES policy.policies(policy_id),
  version         INTEGER NOT NULL,
  logic           JSONB NOT NULL,
  definition_hash TEXT NOT NULL,
  effective_from  TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (policy_id, version)
);

CREATE TABLE policy.policy_packs (
  pack_id         TEXT PRIMARY KEY,
  title           TEXT NOT NULL,
  description     TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE policy.policy_pack_members (
  pack_id         TEXT NOT NULL REFERENCES policy.policy_packs(pack_id),
  policy_id       TEXT NOT NULL REFERENCES policy.policies(policy_id),
  PRIMARY KEY (pack_id, policy_id)
);

INSERT INTO policy.policy_packs (pack_id, title, description)
VALUES ('pack_aws_cis_v6', 'AWS CIS v6 Starter', 'Phase 2 starter policy pack')
ON CONFLICT (pack_id) DO NOTHING;
