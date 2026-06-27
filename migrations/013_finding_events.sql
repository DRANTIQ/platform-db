-- platform-db migration 013
-- Finding lifecycle audit trail (API writes deferred to Phase 4)

CREATE TABLE findings.finding_events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL,
  finding_id      UUID NOT NULL REFERENCES findings.findings(id) ON DELETE CASCADE,
  event_type      TEXT NOT NULL
                  CHECK (event_type IN (
                    'OPENED', 'ASSIGNED', 'SUPPRESSED', 'REOPENED', 'RESOLVED'
                  )),
  actor_subject   TEXT,
  actor_email     TEXT,
  payload         JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX finding_events_finding_idx
  ON findings.finding_events (tenant_id, finding_id, created_at);

CREATE INDEX finding_events_type_idx
  ON findings.finding_events (tenant_id, event_type, created_at DESC);

COMMENT ON TABLE findings.finding_events IS
  'Append-only audit trail for finding lifecycle. Status on findings.findings is current state; '
  'this table is history. Future notification worker subscribes here.';

INSERT INTO platform.schema_migrations (version)
VALUES ('013_finding_events')
ON CONFLICT (version) DO NOTHING;
