#!/usr/bin/env python3
"""Verify legacy schemas still present after V2 migration."""

from __future__ import annotations

import os
import sys

import psycopg


def main() -> int:
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print("ERROR: DATABASE_URL not set", file=sys.stderr)
        return 1

    with psycopg.connect(database_url) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT table_schema, count(*)
                FROM information_schema.tables
                WHERE table_schema IN ('public', 'compliance', 'platform', 'assets')
                GROUP BY 1
                ORDER BY 1
                """
            )
            for schema, count in cur.fetchall():
                print(f"{schema}: {count} tables")

            cur.execute(
                """
                SELECT 1 FROM information_schema.tables
                WHERE table_schema = 'compliance' AND table_name = 'control_results'
                """
            )
            legacy_ok = cur.fetchone() is not None
            print(f"legacy compliance.control_results: {'OK' if legacy_ok else 'MISSING'}")

    return 0 if legacy_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
