-- platform-db migration 008
-- Platform V2 compliance layer (compliance_v2 schema — NOT legacy compliance.*)

CREATE SCHEMA IF NOT EXISTS compliance_v2;

COMMENT ON SCHEMA compliance_v2 IS
  'Platform V2 compliance mapping (frameworks, control results). Legacy Steampipe uses compliance.*';

CREATE TABLE compliance_v2.frameworks (
  framework_id    TEXT PRIMARY KEY,
  title           TEXT NOT NULL,
  provider        TEXT NOT NULL DEFAULT 'aws',
  version_label   TEXT NOT NULL,
  enabled         BOOLEAN NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE compliance_v2.framework_versions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  framework_id    TEXT NOT NULL REFERENCES compliance_v2.frameworks(framework_id),
  version_name    TEXT NOT NULL,
  published_at    TIMESTAMPTZ,
  source_uri      TEXT,
  UNIQUE (framework_id, version_name)
);

CREATE TABLE compliance_v2.controls (
  framework_id    TEXT NOT NULL REFERENCES compliance_v2.frameworks(framework_id),
  control_id      TEXT NOT NULL,
  control_ref     TEXT,
  title           TEXT NOT NULL,
  domain          TEXT,
  severity        TEXT NOT NULL DEFAULT 'medium'
                  CHECK (severity IN ('critical', 'high', 'medium', 'low', 'info')),
  assessment_type TEXT NOT NULL DEFAULT 'automated'
                  CHECK (assessment_type IN ('automated', 'manual')),
  enabled         BOOLEAN NOT NULL DEFAULT true,
  PRIMARY KEY (framework_id, control_id)
);

CREATE INDEX compliance_v2_controls_domain_idx
  ON compliance_v2.controls (framework_id, domain);

CREATE TABLE compliance_v2.policy_mappings (
  framework_id    TEXT NOT NULL,
  control_id      TEXT NOT NULL,
  policy_id       TEXT NOT NULL,
  PRIMARY KEY (framework_id, control_id, policy_id),
  FOREIGN KEY (framework_id, control_id)
    REFERENCES compliance_v2.controls (framework_id, control_id)
);

CREATE INDEX compliance_v2_policy_mappings_policy_idx
  ON compliance_v2.policy_mappings (policy_id);

CREATE TABLE compliance_v2.control_results (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           UUID NOT NULL,
  scan_id             UUID NOT NULL,
  framework_id        TEXT NOT NULL,
  control_id          TEXT NOT NULL,
  status              TEXT NOT NULL
                      CHECK (status IN ('pass', 'fail', 'not_assessed', 'manual', 'error')),
  severity            TEXT,
  title               TEXT NOT NULL,
  domain              TEXT,
  mapped_policy_ids   TEXT[] NOT NULL DEFAULT '{}',
  fail_count          INTEGER NOT NULL DEFAULT 0,
  pass_count          INTEGER NOT NULL DEFAULT 0,
  finding_ids         UUID[] NOT NULL DEFAULT '{}',
  evidence            JSONB NOT NULL DEFAULT '{}'::jsonb,
  evaluated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, scan_id, framework_id, control_id)
);

CREATE INDEX compliance_v2_control_results_scan_idx
  ON compliance_v2.control_results (tenant_id, scan_id, framework_id);

CREATE TABLE compliance_v2.scan_scores (
  tenant_id           UUID NOT NULL,
  scan_id             UUID NOT NULL,
  framework_id        TEXT NOT NULL,
  score               NUMERIC(5, 2) NOT NULL,
  pass_count          INTEGER NOT NULL DEFAULT 0,
  fail_count          INTEGER NOT NULL DEFAULT 0,
  not_assessed_count  INTEGER NOT NULL DEFAULT 0,
  manual_count        INTEGER NOT NULL DEFAULT 0,
  error_count         INTEGER NOT NULL DEFAULT 0,
  total_controls      INTEGER NOT NULL,
  evaluated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, scan_id, framework_id)
);

-- CIS AWS v6 framework + controls (from cis_aws_v6_controls.json)
INSERT INTO compliance_v2.frameworks (framework_id, title, provider, version_label)
VALUES ('cis_aws_v6', 'CIS Amazon Web Services Foundations Benchmark', 'aws', 'v6.0.0')
ON CONFLICT (framework_id) DO NOTHING;

INSERT INTO compliance_v2.framework_versions (framework_id, version_name, published_at)
VALUES ('cis_aws_v6', 'v6.0.0', now())
ON CONFLICT (framework_id, version_name) DO NOTHING;

INSERT INTO compliance_v2.controls (framework_id, control_id, control_ref, title, domain, severity)
VALUES
  ('cis_aws_v6', '2.3', 'iam-root-access-keys', 'Ensure no root user access keys exist', 'iam', 'critical'),
  ('cis_aws_v6', '2.4', 'iam-root-mfa', 'Ensure MFA is enabled for the root user', 'iam', 'critical'),
  ('cis_aws_v6', '2.7', 'iam-password-min-length', 'Ensure IAM password policy requires minimum length', 'iam', 'medium'),
  ('cis_aws_v6', '2.8', 'iam-password-reuse', 'Ensure IAM password policy prevents reuse', 'iam', 'medium'),
  ('cis_aws_v6', '2.9', 'iam-user-mfa', 'Ensure MFA is enabled for all IAM users with console access', 'iam', 'high'),
  ('cis_aws_v6', '2.11', 'iam-credentials-unused', 'Ensure credentials unused for 45 days are disabled', 'iam', 'medium'),
  ('cis_aws_v6', '2.12', 'iam-single-access-key', 'Ensure there is only one active access key per IAM user', 'iam', 'medium'),
  ('cis_aws_v6', '2.13', 'iam-access-key-rotation', 'Ensure access keys are rotated every 90 days', 'iam', 'medium'),
  ('cis_aws_v6', '2.14', 'iam-permissions-via-groups', 'Ensure IAM users receive permissions via groups', 'iam', 'medium'),
  ('cis_aws_v6', '2.15', 'iam-admin-policies', 'Ensure IAM policies with admin access are not attached', 'iam', 'high'),
  ('cis_aws_v6', '2.16', 'iam-support-role', 'Ensure a support role has been created to manage incidents', 'iam', 'low'),
  ('cis_aws_v6', '2.17', 'iam-instance-roles', 'Ensure IAM instance roles are used for EC2', 'iam', 'medium'),
  ('cis_aws_v6', '2.18', 'iam-expired-certificates', 'Ensure expired SSL/TLS certificates are removed', 'iam', 'medium'),
  ('cis_aws_v6', '2.19', 'iam-access-analyzer', 'Ensure IAM Access Analyzer is enabled', 'iam', 'medium'),
  ('cis_aws_v6', '3.1.1', 's3-deny-http', 'Ensure S3 bucket policy denies HTTP requests', 's3', 'medium'),
  ('cis_aws_v6', '3.1.4', 's3-public-access', 'Ensure S3 buckets block public access', 's3', 'critical'),
  ('cis_aws_v6', '3.2.1', 'rds-encryption', 'Ensure RDS instances are encrypted', 'rds', 'high'),
  ('cis_aws_v6', '3.2.2', 'rds-auto-upgrade', 'Ensure auto minor version upgrade is enabled on RDS', 'rds', 'medium'),
  ('cis_aws_v6', '3.2.3', 'rds-public', 'Ensure RDS instances are not publicly accessible', 'rds', 'critical'),
  ('cis_aws_v6', '3.3.1', 'efs-encryption', 'Ensure EFS file systems are encrypted', 'efs', 'high'),
  ('cis_aws_v6', '4.2', 'cloudtrail-validation', 'Ensure CloudTrail log file validation is enabled', 'logging', 'medium'),
  ('cis_aws_v6', '4.3', 'config-enabled', 'Ensure AWS Config is enabled', 'logging', 'medium'),
  ('cis_aws_v6', '4.5', 'cloudtrail-kms', 'Ensure CloudTrail logs are encrypted with KMS', 'logging', 'medium'),
  ('cis_aws_v6', '4.6', 'kms-rotation', 'Ensure KMS key rotation is enabled', 'logging', 'medium'),
  ('cis_aws_v6', '4.7', 'vpc-flow-logs', 'Ensure VPC flow logging is enabled', 'logging', 'medium'),
  ('cis_aws_v6', '4.8', 's3-write-logging', 'Ensure S3 bucket write events are logged', 's3', 'medium'),
  ('cis_aws_v6', '4.9', 's3-read-logging', 'Ensure S3 bucket read events are logged', 's3', 'medium'),
  ('cis_aws_v6', '5.16', 'security-hub-enabled', 'Ensure AWS Security Hub is enabled', 'logging', 'medium'),
  ('cis_aws_v6', '6.1.1', 'ebs-encryption-default', 'Ensure EBS default encryption is enabled', 'network', 'high'),
  ('cis_aws_v6', '6.1.2', 'cifs-restricted', 'Ensure CIFS access is restricted to trusted networks', 'network', 'medium'),
  ('cis_aws_v6', '6.2', 'nacl-admin-ports', 'Ensure no NACL allows unrestricted admin ports', 'network', 'high'),
  ('cis_aws_v6', '6.3', 'sg-admin-ports-ipv4', 'Ensure no SG allows unrestricted admin ports (IPv4)', 'network', 'high'),
  ('cis_aws_v6', '6.4', 'sg-admin-ports-ipv6', 'Ensure no SG allows unrestricted admin ports (IPv6)', 'network', 'high'),
  ('cis_aws_v6', '6.5', 'default-sg-restricts-traffic', 'Ensure default SG restricts all traffic', 'network', 'medium'),
  ('cis_aws_v6', '6.7', 'ec2-imdsv2', 'Ensure EC2 instance metadata requires IMDSv2', 'network', 'high')
ON CONFLICT (framework_id, control_id) DO NOTHING;

-- Map Phase 2 starter policies to CIS controls
INSERT INTO compliance_v2.policy_mappings (framework_id, control_id, policy_id)
VALUES
  ('cis_aws_v6', '3.1.4', 'AWS_S3_001'),
  ('cis_aws_v6', '3.1.4', 'AWS_S3_002'),
  ('cis_aws_v6', '2.9', 'AWS_IAM_001')
ON CONFLICT DO NOTHING;
