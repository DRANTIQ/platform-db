#!/usr/bin/env bash
# Apply platform-db migrations in order. Requires DATABASE_URL.
set -euo pipefail

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: DATABASE_URL is not set" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MIGRATIONS="$ROOT/migrations"

shopt -s nullglob
files=("$MIGRATIONS"/*.sql)
IFS=$'\n' files=($(sort <<<"${files[*]}"))
unset IFS

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No migrations found in $MIGRATIONS" >&2
  exit 1
fi

for f in "${files[@]}"; do
  version="$(basename "$f" .sql)"
  echo "Applying $version ..."
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"
done

echo "Done."