-- platform-db migration 020
-- Remove policy_sources if a prior P3 draft migration was applied (engineering-only provenance).

DROP TABLE IF EXISTS policy.policy_sources;
