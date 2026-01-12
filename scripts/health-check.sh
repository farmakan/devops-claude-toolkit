#!/bin/bash
# Infrastructure health check script
# Usage: ./scripts/health-check.sh [environment]

set -euo pipefail

ENVIRONMENT="${1:-production}"
PROJECT="${GCP_PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

echo "=== Infrastructure Health Check ==="
echo "Environment: ${ENVIRONMENT}"
echo "Project: ${PROJECT}"
echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "=================================="
echo ""

# Check Cloud Run services
echo "### Cloud Run Services ###"
if gcloud run services list --format="table(SERVICE,REGION,LAST_DEPLOYED_AT)" 2>/dev/null; then
    echo ""
else
    echo "No Cloud Run services found or insufficient permissions"
    echo ""
fi

# Check GKE clusters
echo "### GKE Clusters ###"
if gcloud container clusters list --format="table(NAME,LOCATION,STATUS,NUM_NODES)" 2>/dev/null; then
    echo ""
else
    echo "No GKE clusters found or insufficient permissions"
    echo ""
fi

# Check Kubernetes pods (if kubectl configured)
echo "### Kubernetes Pods Status ###"
if kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null | head -20; then
    if [[ $(kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null | wc -l) -eq 0 ]]; then
        echo "All pods healthy"
    fi
else
    echo "Kubernetes not configured or no unhealthy pods"
fi
echo ""

# Check recent errors
echo "### Recent Errors (Last 15 min) ###"
ERROR_COUNT=$(gcloud logging read "severity>=ERROR AND timestamp>=\"$(date -u -d '15 minutes ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v-15M '+%Y-%m-%dT%H:%M:%SZ')\"" --format=json --limit=100 2>/dev/null | jq length 2>/dev/null || echo "0")
echo "Error count: ${ERROR_COUNT}"

if [[ "$ERROR_COUNT" -gt 0 ]]; then
    echo ""
    echo "Error distribution by service:"
    gcloud logging read "severity>=ERROR AND timestamp>=\"$(date -u -d '15 minutes ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v-15M '+%Y-%m-%dT%H:%M:%SZ')\"" --format=json --limit=100 2>/dev/null | \
        jq -r '.[].resource.labels.service_name // "unknown"' 2>/dev/null | \
        sort | uniq -c | sort -rn || true
fi
echo ""

# Summary
echo "=== Health Summary ==="
if [[ "$ERROR_COUNT" -gt 50 ]]; then
    echo "Status: CRITICAL - High error rate detected"
    exit 2
elif [[ "$ERROR_COUNT" -gt 10 ]]; then
    echo "Status: WARNING - Elevated error rate"
    exit 1
else
    echo "Status: HEALTHY"
    exit 0
fi
