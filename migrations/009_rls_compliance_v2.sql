-- platform-db migration 009
-- RLS for compliance_v2 tenant-scoped tables

CREATE OR REPLACE FUNCTION compliance_v2.current_tenant_id()
RETURNS UUID
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(current_setting('app.tenant_id', true), '')::uuid;
$$;

ALTER TABLE compliance_v2.control_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_v2.control_results FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_control_results ON compliance_v2.control_results
  FOR ALL
  USING (tenant_id = compliance_v2.current_tenant_id())
  WITH CHECK (tenant_id = compliance_v2.current_tenant_id());

ALTER TABLE compliance_v2.scan_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_v2.scan_scores FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_scan_scores ON compliance_v2.scan_scores
  FOR ALL
  USING (tenant_id = compliance_v2.current_tenant_id())
  WITH CHECK (tenant_id = compliance_v2.current_tenant_id());

-- Framework catalog is global read
ALTER TABLE compliance_v2.frameworks ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_v2.frameworks FORCE ROW LEVEL SECURITY;
CREATE POLICY frameworks_read ON compliance_v2.frameworks FOR SELECT USING (true);

ALTER TABLE compliance_v2.framework_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_v2.framework_versions FORCE ROW LEVEL SECURITY;
CREATE POLICY framework_versions_read ON compliance_v2.framework_versions FOR SELECT USING (true);

ALTER TABLE compliance_v2.controls ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_v2.controls FORCE ROW LEVEL SECURITY;
CREATE POLICY controls_read ON compliance_v2.controls FOR SELECT USING (true);

ALTER TABLE compliance_v2.policy_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_v2.policy_mappings FORCE ROW LEVEL SECURITY;
CREATE POLICY policy_mappings_read ON compliance_v2.policy_mappings FOR SELECT USING (true);
