#!/usr/bin/env bash
# Run SQL migrations for one project folder under migrator/<project>/
# Usage:
#   ./migrator/migrate.sh <project> [up|down|version|force VERSION]
# Examples:
#   ./migrator/migrate.sh splitbill up
#   ./migrator/migrate.sh splitbill down 1
#   ./migrator/migrate.sh splitbill version

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "error: .env not found in $ROOT (copy from .env.example)" >&2
  exit 1
fi

# shellcheck disable=SC1091
set -a
source .env
set +a

PROJECT="${1:-}"
ACTION="${2:-up}"
EXTRA="${3:-}"

if [[ -z "$PROJECT" ]]; then
  echo "usage: $0 <project> [up|down|version|force] [args...]" >&2
  echo "projects:" >&2
  ls -1 migrator | grep -vE '^(migrate\.sh|README\.md)$' >&2 || true
  exit 1
fi

DIR="$ROOT/migrator/$PROJECT"
if [[ ! -d "$DIR" ]]; then
  echo "error: project folder not found: migrator/$PROJECT" >&2
  exit 1
fi

if ! ls "$DIR"/*.up.sql >/dev/null 2>&1; then
  echo "error: no *.up.sql in migrator/$PROJECT" >&2
  exit 1
fi

# Folder name = database name (convention)
DB_NAME="${MIGRATE_DATABASE:-$PROJECT}"
DB_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@shared_postgres:5432/${DB_NAME}?sslmode=disable"

echo "project=$PROJECT db=$DB_NAME action=$ACTION"

docker run --rm \
  --network shared_infra \
  -v "$DIR:/migrations:ro" \
  migrate/migrate:v4.18.1 \
  -path=/migrations \
  -database "$DB_URL" \
  $ACTION $EXTRA
