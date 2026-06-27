-- platform-db migration 007
-- RLS for policy + findings (tenant-scoped findings; policy catalog is global read)

CREATE OR REPLACE FUNCTION policy.current_tenant_id()
RETURNS UUID
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(current_setting('app.tenant_id', true), '')::uuid;
$$;

-- findings.findings
ALTER TABLE findings.findings ENABLE ROW LEVEL SECURITY;
ALTER TABLE findings.findings FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_findings ON findings.findings
  FOR ALL
  USING (tenant_id = policy.current_tenant_id())
  WITH CHECK (tenant_id = policy.current_tenant_id());

-- findings.evaluation_runs
ALTER TABLE findings.evaluation_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE findings.evaluation_runs FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_evaluation_runs ON findings.evaluation_runs
  FOR ALL
  USING (tenant_id = policy.current_tenant_id())
  WITH CHECK (tenant_id = policy.current_tenant_id());

-- policy catalog: global read for authenticated app sessions (no tenant column)
ALTER TABLE policy.policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE policy.policies FORCE ROW LEVEL SECURITY;
CREATE POLICY policy_catalog_read ON policy.policies FOR SELECT USING (true);

ALTER TABLE policy.policy_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE policy.policy_versions FORCE ROW LEVEL SECURITY;
CREATE POLICY policy_versions_read ON policy.policy_versions FOR SELECT USING (true);

ALTER TABLE policy.policy_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE policy.policy_packs FORCE ROW LEVEL SECURITY;
CREATE POLICY policy_packs_read ON policy.policy_packs FOR SELECT USING (true);

ALTER TABLE policy.policy_pack_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE policy.policy_pack_members FORCE ROW LEVEL SECURITY;
CREATE POLICY policy_pack_members_read ON policy.policy_pack_members FOR SELECT USING (true);
