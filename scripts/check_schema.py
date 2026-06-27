#!/usr/bin/env python3
"""Verify Platform V2 schema objects exist (Phase 1 + Phase 2)."""

from __future__ import annotations

import os
import sys

import psycopg

EXPECTED_TABLES = [
    ("platform", "schema_migrations"),
    ("platform", "tenants"),
    ("platform", "integrations"),
    ("platform", "scans"),
    ("platform", "collection_runs"),
    ("assets", "resources"),
    ("assets", "relationships"),
    ("assets", "collection_events"),
    ("policy", "policies"),
    ("policy", "policy_versions"),
    ("policy", "policy_packs"),
    ("findings", "findings"),
    ("findings", "evaluation_runs"),
    ("compliance_v2", "frameworks"),
    ("compliance_v2", "controls"),
    ("compliance_v2", "policy_mappings"),
    ("compliance_v2", "control_results"),
    ("compliance_v2", "scan_scores"),
]

FORBIDDEN_SCHEMAS: list[str] = []


def main() -> int:
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print("ERROR: DATABASE_URL is not set", file=sys.stderr)
        return 1

    errors: list[str] = []

    with psycopg.connect(database_url) as conn:
        with conn.cursor() as cur:
            for schema in FORBIDDEN_SCHEMAS:
                cur.execute(
                    "SELECT 1 FROM information_schema.schemata WHERE schema_name = %s",
                    (schema,),
                )
                if cur.fetchone():
                    errors.append(f"unexpected V2 schema present: {schema}")

            for schema, table in EXPECTED_TABLES:
                cur.execute(
                    """
                    SELECT 1 FROM information_schema.tables
                    WHERE table_schema = %s AND table_name = %s
                    """,
                    (schema, table),
                )
                if not cur.fetchone():
                    errors.append(f"missing table: {schema}.{table}")

            cur.execute(
                """
                SELECT 1 FROM pg_proc p
                JOIN pg_namespace n ON n.oid = p.pronamespace
                WHERE n.nspname = 'platform' AND p.proname = 'set_tenant'
                """
            )
            if not cur.fetchone():
                errors.append("missing function: platform.set_tenant()")

    if errors:
        for err in errors:
            print(f"FAIL: {err}", file=sys.stderr)
        return 1

    print("Schema check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
