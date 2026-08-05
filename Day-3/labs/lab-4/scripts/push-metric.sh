#!/usr/bin/env bash
# Push a gauge to Prometheus Pushgateway (batch-job style).
# Usage:
#   ./scripts/push-metric.sh lab_batch_duration_seconds 3.14
#   ./scripts/push-metric.sh lab_batch_duration_seconds 1.2 student-a

set -euo pipefail

NAME="${1:?metric name required}"
VALUE="${2:?value required}"
INSTANCE="${3:-student1}"
JOB="${JOB:-lab4}"
PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-http://localhost:9091}"

URI="$PUSHGATEWAY_URL/metrics/job/$JOB/instance/$INSTANCE"

PAYLOAD=$(cat <<EOF
# TYPE $NAME gauge
# HELP $NAME Custom value pushed from lab-4 script
$NAME $VALUE
EOF
)

echo "POST $URI"
echo "$PAYLOAD"
curl -sS --data-binary "$PAYLOAD" "$URI"
echo
echo "Pushed $NAME=$VALUE (job=$JOB instance=$INSTANCE)"
