-- platform-db migration 004
-- Row-level security for tenant isolation (ADR-007)

CREATE OR REPLACE FUNCTION platform.set_tenant(p_tenant_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = platform, public
AS $$
BEGIN
  IF p_tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant_id is required';
  END IF;
  PERFORM set_config('app.tenant_id', p_tenant_id::text, true);
END;
$$;

REVOKE ALL ON FUNCTION platform.set_tenant(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION platform.set_tenant(UUID) TO PUBLIC;

CREATE OR REPLACE FUNCTION platform.current_tenant_id()
RETURNS UUID
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(current_setting('app.tenant_id', true), '')::uuid;
$$;

-- platform.integrations
ALTER TABLE platform.integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.integrations FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_integrations ON platform.integrations
  FOR ALL
  USING (tenant_id = platform.current_tenant_id())
  WITH CHECK (tenant_id = platform.current_tenant_id());

-- platform.scans
ALTER TABLE platform.scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.scans FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_scans ON platform.scans
  FOR ALL
  USING (tenant_id = platform.current_tenant_id())
  WITH CHECK (tenant_id = platform.current_tenant_id());

-- platform.collection_runs
ALTER TABLE platform.collection_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.collection_runs FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_collection_runs ON platform.collection_runs
  FOR ALL
  USING (tenant_id = platform.current_tenant_id())
  WITH CHECK (tenant_id = platform.current_tenant_id());

-- assets.resources
ALTER TABLE assets.resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets.resources FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_resources ON assets.resources
  FOR ALL
  USING (tenant_id = platform.current_tenant_id())
  WITH CHECK (tenant_id = platform.current_tenant_id());

-- assets.relationships
ALTER TABLE assets.relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets.relationships FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_relationships ON assets.relationships
  FOR ALL
  USING (tenant_id = platform.current_tenant_id())
  WITH CHECK (tenant_id = platform.current_tenant_id());

-- assets.collection_events
ALTER TABLE assets.collection_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets.collection_events FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_collection_events ON assets.collection_events
  FOR ALL
  USING (tenant_id = platform.current_tenant_id())
  WITH CHECK (tenant_id = platform.current_tenant_id());
