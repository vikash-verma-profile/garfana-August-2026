#!/usr/bin/env bash
# Insert / update a custom metric on the lab custom-metrics API.
# Usage:
#   ./scripts/set-metric.sh lab_queue_depth 42
#   ./scripts/set-metric.sh lab_queue_depth 7 gauge '{"region":"eu","env":"lab"}'
#   ./scripts/set-metric.sh lab_orders_total 150 counter '{"region":"lab"}'

set -euo pipefail

NAME="${1:?metric name required}"
VALUE="${2:?value required}"
TYPE="${3:-gauge}"
LABELS="${4:-{}}"
BASE_URL="${BASE_URL:-http://localhost:8081}"

BODY=$(printf '{"name":"%s","value":%s,"type":"%s","labels":%s}' "$NAME" "$VALUE" "$TYPE" "$LABELS")

echo "POST $BASE_URL/api/metrics"
echo "$BODY"
curl -sS -X POST "$BASE_URL/api/metrics" \
  -H "Content-Type: application/json" \
  -d "$BODY"
echo
