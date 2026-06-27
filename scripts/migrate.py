#!/usr/bin/env python3
"""Apply platform-db migrations in order with checksum tracking."""

from __future__ import annotations

import hashlib
import os
import sys
from pathlib import Path

import psycopg


def _checksum(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def _migration_version(path: Path) -> str:
    return path.stem


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
    root = Path(__file__).resolve().parents[1]
    _load_dotenv(root)

    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print(
            "ERROR: DATABASE_URL is not set. Set it in the environment or platform-db/.env",
            file=sys.stderr,
        )
        return 1
    if "sslmode=" not in database_url and "ssl=" not in database_url:
        sep = "&" if "?" in database_url else "?"
        database_url = f"{database_url}{sep}sslmode=require"

    migrations_dir = root / "migrations"
    files = sorted(migrations_dir.glob("*.sql"))
    if not files:
        print(f"ERROR: no migrations in {migrations_dir}", file=sys.stderr)
        return 1

    with psycopg.connect(database_url) as conn:
        conn.autocommit = True
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE SCHEMA IF NOT EXISTS platform;
                CREATE TABLE IF NOT EXISTS platform.schema_migrations (
                  version TEXT PRIMARY KEY,
                  applied_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                  checksum TEXT
                );
                """
            )
            cur.execute("SELECT version, checksum FROM platform.schema_migrations")
            applied = {row[0]: row[1] for row in cur.fetchall()}

        for path in files:
            version = _migration_version(path)
            content = path.read_text(encoding="utf-8")
            digest = _checksum(content)

            if version in applied:
                if applied[version] and applied[version] != digest:
                    print(
                        f"ERROR: migration {version} was modified after apply "
                        f"(stored={applied[version][:12]}… current={digest[:12]}…)",
                        file=sys.stderr,
                    )
                    return 1
                print(f"Skip {version} (already applied)")
                continue

            print(f"Applying {version} …")
            with conn.cursor() as cur:
                cur.execute(content)
                cur.execute(
                    """
                    INSERT INTO platform.schema_migrations (version, checksum)
                    VALUES (%s, %s)
                    ON CONFLICT (version) DO UPDATE SET checksum = EXCLUDED.checksum
                    """,
                    (version, digest),
                )

    print("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
