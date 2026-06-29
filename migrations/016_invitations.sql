-- platform-db migration 016
-- Team invitations (pending → accepted | expired | revoked)

CREATE TABLE platform.invitations (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID NOT NULL REFERENCES platform.tenants(id) ON DELETE CASCADE,
  email         TEXT NOT NULL,
  role          TEXT NOT NULL CHECK (role IN ('tenant_admin', 'viewer')),
  token_hash    TEXT NOT NULL UNIQUE,
  status        TEXT NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'accepted', 'expired', 'revoked')),
  invited_by    UUID REFERENCES platform.users(id) ON DELETE SET NULL,
  expires_at    TIMESTAMPTZ NOT NULL,
  accepted_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX invitations_tenant_idx ON platform.invitations (tenant_id);
CREATE INDEX invitations_email_idx ON platform.invitations (lower(email));
CREATE INDEX invitations_status_idx ON platform.invitations (status) WHERE status = 'pending';
