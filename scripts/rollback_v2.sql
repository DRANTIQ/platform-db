-- Roll back Platform V2 schemas only.
-- NEVER touches legacy public.* or compliance.* (legacy Steampipe stack).

DROP SCHEMA IF EXISTS compliance_v2 CASCADE;
DROP SCHEMA IF EXISTS findings CASCADE;
DROP SCHEMA IF EXISTS policy CASCADE;
DROP SCHEMA IF EXISTS assets CASCADE;
DROP SCHEMA IF EXISTS platform CASCADE;
