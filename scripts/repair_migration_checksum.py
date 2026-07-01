#!/usr/bin/env python3
"""Update stored migration checksum when file content changed but DB state is already correct.

Use after regenerating a seed file that was previously applied (dev/staging only).
"""

from __future__ import annotations

import hashlib
import os
import sys
from pathlib import Path

import psycopg


def _checksum(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def _load_dotenv(root: Path) -> None:
    env_file = root / ".env"
    if not env_file.is_file():
        return
    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: python scripts/repair_migration_checksum.py <migration_version>", file=sys.stderr)
        print("Example: python scripts/repair_migration_checksum.py 017_commercial_compliance", file=sys.stderr)
        return 1

    version = sys.argv[1]
    root = Path(__file__).resolve().parents[1]
    _load_dotenv(root)

    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print("ERROR: DATABASE_URL is not set", file=sys.stderr)
        return 1

    path = root / "migrations" / f"{version}.sql"
    if not path.is_file():
        print(f"ERROR: migration file not found: {path}", file=sys.stderr)
        return 1

    content = path.read_text(encoding="utf-8")
    digest = _checksum(content)

    with psycopg.connect(database_url) as conn:
        conn.autocommit = True
        with conn.cursor() as cur:
            cur.execute(
                "SELECT checksum FROM platform.schema_migrations WHERE version = %s",
                (version,),
            )
            row = cur.fetchone()
            if not row:
                print(f"ERROR: {version} is not in platform.schema_migrations", file=sys.stderr)
                return 1
            stored = row[0]
            if stored == digest:
                print(f"Checksum already matches for {version}")
                return 0
            cur.execute(
                """
                UPDATE platform.schema_migrations
                SET checksum = %s
                WHERE version = %s
                """,
                (digest, version),
            )
            print(f"Updated checksum for {version}")
            print(f"  was:    {stored[:12]}…")
            print(f"  now:    {digest[:12]}…")
            print("Only do this when the migration SQL already ran and the file change is cosmetic.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
