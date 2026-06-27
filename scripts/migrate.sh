#!/usr/bin/env bash
# Apply platform-db migrations in order. Requires DATABASE_URL and psql.
set -euo pipefail

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: DATABASE_URL is not set" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIGRATIONS_DIR="${ROOT}/migrations"

if ! command -v psql >/dev/null 2>&1; then
  echo "ERROR: psql not found on PATH" >&2
  exit 1
fi

shopt -s nullglob
files=("${MIGRATIONS_DIR}"/*.sql)
if (( ${#files[@]} == 0 )); then
  echo "ERROR: no migrations in ${MIGRATIONS_DIR}" >&2
  exit 1
fi

for file in "${files[@]}"; do
  echo "Applying $(basename "${file}") …"
  psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -f "${file}"
done

echo "Done."
