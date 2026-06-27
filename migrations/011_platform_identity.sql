-- platform-db migration 011
-- Identity: users + tenant memberships (IdP subject → tenant + role)

CREATE TABLE platform.users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT,
  display_name  TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX users_email_idx ON platform.users (lower(email)) WHERE email IS NOT NULL;

CREATE TABLE platform.tenant_memberships (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES platform.users(id) ON DELETE CASCADE,
  tenant_id     UUID NOT NULL REFERENCES platform.tenants(id) ON DELETE CASCADE,
  role          TEXT NOT NULL
                CHECK (role IN ('tenant_admin', 'viewer', 'super_admin')),
  auth_issuer   TEXT NOT NULL,
  auth_subject  TEXT NOT NULL,
  status        TEXT NOT NULL DEFAULT 'active'
                CHECK (status IN ('active', 'disabled')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (auth_issuer, auth_subject)
);

CREATE INDEX tenant_memberships_tenant_idx ON platform.tenant_memberships (tenant_id);
CREATE INDEX tenant_memberships_user_idx ON platform.tenant_memberships (user_id);

-- Identity lookups run before tenant context is set; enforce access in application layer.
