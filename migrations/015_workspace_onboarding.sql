-- platform-db migration 015
-- Workspace onboarding state, tenant lifecycle, billing hooks

ALTER TABLE platform.tenants
  DROP CONSTRAINT IF EXISTS tenants_status_check;

ALTER TABLE platform.tenants
  ADD CONSTRAINT tenants_status_check
  CHECK (status IN ('provisioning', 'active', 'suspended', 'deleted'));

ALTER TABLE platform.tenants
  ADD COLUMN IF NOT EXISTS onboarding_state TEXT;

UPDATE platform.tenants
SET onboarding_state = 'ONBOARDING_COMPLETE'
WHERE onboarding_state IS NULL;

ALTER TABLE platform.tenants
  ALTER COLUMN onboarding_state SET DEFAULT 'WORKSPACE_CREATED';

ALTER TABLE platform.tenants
  ALTER COLUMN onboarding_state SET NOT NULL;

ALTER TABLE platform.tenants
  DROP CONSTRAINT IF EXISTS tenants_onboarding_state_check;

ALTER TABLE platform.tenants
  ADD CONSTRAINT tenants_onboarding_state_check
  CHECK (onboarding_state IN (
    'WORKSPACE_CREATED',
    'AWS_CONNECTED',
    'FIRST_SCAN_STARTED',
    'FIRST_SCAN_COMPLETE',
    'ONBOARDING_COMPLETE'
  ));

ALTER TABLE platform.tenants
  ADD COLUMN IF NOT EXISTS plan TEXT;

UPDATE platform.tenants
SET plan = 'trial'
WHERE plan IS NULL;

ALTER TABLE platform.tenants
  ALTER COLUMN plan SET DEFAULT 'trial';

ALTER TABLE platform.tenants
  ALTER COLUMN plan SET NOT NULL;

ALTER TABLE platform.tenants
  DROP CONSTRAINT IF EXISTS tenants_plan_check;

ALTER TABLE platform.tenants
  ADD CONSTRAINT tenants_plan_check
  CHECK (plan IN ('trial', 'starter', 'growth', 'enterprise'));

ALTER TABLE platform.tenants
  ADD COLUMN IF NOT EXISTS trial_end TIMESTAMPTZ;

ALTER TABLE platform.users
  ADD COLUMN IF NOT EXISTS onboarding_state TEXT;

UPDATE platform.users
SET onboarding_state = 'WORKSPACE_CREATED'
WHERE onboarding_state IS NULL;

ALTER TABLE platform.users
  ALTER COLUMN onboarding_state SET DEFAULT 'ACCOUNT_CREATED';

ALTER TABLE platform.users
  ALTER COLUMN onboarding_state SET NOT NULL;

ALTER TABLE platform.users
  DROP CONSTRAINT IF EXISTS users_onboarding_state_check;

ALTER TABLE platform.users
  ADD CONSTRAINT users_onboarding_state_check
  CHECK (onboarding_state IN (
    'ACCOUNT_CREATED',
    'EMAIL_VERIFIED',
    'WORKSPACE_CREATED'
  ));
