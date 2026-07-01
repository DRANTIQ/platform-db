-- platform-db migration 021
-- Remove internal_reference from policy catalog (engineering-only field; P3 re-scope).

ALTER TABLE policy.policies DROP COLUMN IF EXISTS internal_reference;
