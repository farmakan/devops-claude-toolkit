#!/bin/bash
# Fetch logs from GCP Cloud Logging
# Usage: ./scripts/fetch-logs.sh [service-name] [time-range] [severity]

set -euo pipefail

SERVICE_NAME="${1:-}"
TIME_RANGE="${2:-1h}"
SEVERITY="${3:-ERROR}"
PROJECT="${GCP_PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "$PROJECT" ]]; then
    echo "Error: No GCP project configured. Set GCP_PROJECT or run 'gcloud config set project PROJECT_ID'" >&2
    exit 1
fi

# Calculate timestamp
case "$TIME_RANGE" in
    *h) HOURS="${TIME_RANGE%h}"; TIMESTAMP=$(date -u -d "${HOURS} hours ago" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v-${HOURS}H '+%Y-%m-%dT%H:%M:%SZ') ;;
    *d) DAYS="${TIME_RANGE%d}"; TIMESTAMP=$(date -u -d "${DAYS} days ago" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v-${DAYS}d '+%Y-%m-%dT%H:%M:%SZ') ;;
    *) TIMESTAMP=$(date -u -d "1 hour ago" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v-1H '+%Y-%m-%dT%H:%M:%SZ') ;;
esac

# Build filter
FILTER="severity>=${SEVERITY} AND timestamp>=\"${TIMESTAMP}\""
if [[ -n "$SERVICE_NAME" ]]; then
    FILTER="${FILTER} AND resource.labels.service_name=\"${SERVICE_NAME}\""
fi

echo "Fetching logs from project: ${PROJECT}" >&2
echo "Filter: ${FILTER}" >&2
echo "---" >&2

gcloud logging read "${FILTER}" \
    --project="${PROJECT}" \
    --format=json \
    --limit=500
