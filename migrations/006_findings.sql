-- platform-db migration 006
-- Findings schema (Phase 2)

CREATE SCHEMA IF NOT EXISTS findings;

CREATE TABLE findings.findings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL,
  scan_id         UUID NOT NULL,
  policy_id       TEXT NOT NULL,
  resource_id     TEXT NOT NULL,
  resource_type   TEXT NOT NULL,
  result          TEXT NOT NULL CHECK (result IN ('pass', 'fail', 'error', 'skip')),
  status          TEXT NOT NULL DEFAULT 'open'
                  CHECK (status IN ('open', 'resolved', 'suppressed')),
  severity        TEXT NOT NULL
                  CHECK (severity IN ('critical', 'high', 'medium', 'low', 'info')),
  title           TEXT NOT NULL,
  description     TEXT,
  evidence        JSONB NOT NULL DEFAULT '{}'::jsonb,
  evaluated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, scan_id, policy_id, resource_id)
);

CREATE INDEX findings_scan_idx ON findings.findings (tenant_id, scan_id);
CREATE INDEX findings_policy_idx ON findings.findings (tenant_id, scan_id, policy_id);
CREATE INDEX findings_status_idx ON findings.findings (tenant_id, scan_id, status);
CREATE INDEX findings_result_idx ON findings.findings (tenant_id, scan_id, result);

CREATE TABLE findings.evaluation_runs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL,
  scan_id         UUID NOT NULL,
  status          TEXT NOT NULL CHECK (status IN ('running', 'completed', 'failed')),
  policies_run    INTEGER NOT NULL DEFAULT 0,
  findings_count  INTEGER NOT NULL DEFAULT 0,
  fail_count      INTEGER NOT NULL DEFAULT 0,
  error           JSONB,
  started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at    TIMESTAMPTZ,
  UNIQUE (tenant_id, scan_id)
);

CREATE INDEX findings_eval_runs_scan_idx ON findings.evaluation_runs (tenant_id, scan_id);
