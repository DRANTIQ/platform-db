-- Dev bootstrap: one tenant (local only). Register integrations via POST /v1/integrations/aws.
--
-- Example:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
--     -v dev_tenant_name="'Drantiq Sandbox'" \
--     -v dev_tenant_slug="'drantiq-sandbox'" \
--     -f seeds/dev_bootstrap.sql

INSERT INTO platform.tenants (name, slug)
VALUES (:'dev_tenant_name', :'dev_tenant_slug')
ON CONFLICT (slug) DO UPDATE
  SET name = EXCLUDED.name, updated_at = now();
