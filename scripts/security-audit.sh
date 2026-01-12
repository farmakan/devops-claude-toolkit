#!/bin/bash
# Security audit script for GCP project
# Usage: ./scripts/security-audit.sh [project-id]

set -euo pipefail

PROJECT="${1:-${GCP_PROJECT:-$(gcloud config get-value project 2>/dev/null)}}"

if [[ -z "$PROJECT" ]]; then
    echo "Error: No GCP project specified" >&2
    exit 1
fi

echo "=== Security Audit Report ==="
echo "Project: ${PROJECT}"
echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "============================="
echo ""

CRITICAL=0
HIGH=0
MEDIUM=0
LOW=0

# Check for overly permissive IAM bindings
echo "### IAM Analysis ###"
echo ""
echo "#### Overly Permissive Roles ####"
PERMISSIVE=$(gcloud projects get-iam-policy "${PROJECT}" --format=json 2>/dev/null | \
    jq -r '.bindings[] | select(.role | test("owner|editor")) | "\(.role): \(.members | length) members"' 2>/dev/null || echo "")
if [[ -n "$PERMISSIVE" ]]; then
    echo "$PERMISSIVE"
    HIGH=$((HIGH + 1))
else
    echo "No overly permissive bindings found"
fi
echo ""

echo "#### External Users ####"
EXTERNAL=$(gcloud projects get-iam-policy "${PROJECT}" --format=json 2>/dev/null | \
    jq -r '.bindings[].members[]' 2>/dev/null | \
    grep -v "gserviceaccount.com" | \
    grep -v "@${PROJECT}.iam" | \
    sort -u || echo "")
if [[ -n "$EXTERNAL" ]]; then
    echo "$EXTERNAL"
    MEDIUM=$((MEDIUM + 1))
else
    echo "No external users found"
fi
echo ""

# Check service accounts
echo "### Service Account Analysis ###"
echo ""
echo "#### Service Accounts with User-Managed Keys ####"
for sa in $(gcloud iam service-accounts list --project="${PROJECT}" --format='value(email)' 2>/dev/null); do
    KEY_COUNT=$(gcloud iam service-accounts keys list --iam-account="${sa}" --format='value(name)' 2>/dev/null | wc -l)
    if [[ $KEY_COUNT -gt 1 ]]; then
        echo "${sa}: ${KEY_COUNT} keys (including default)"
        HIGH=$((HIGH + 1))
    fi
done
echo ""

# Check public resources
echo "### Public Resource Check ###"
echo ""
echo "#### Public Storage Buckets ####"
PUBLIC_BUCKETS=$(gcloud storage buckets list --project="${PROJECT}" --format=json 2>/dev/null | \
    jq -r '.[] | select(.iamConfiguration.publicAccessPrevention != "enforced") | .name' 2>/dev/null || echo "")
if [[ -n "$PUBLIC_BUCKETS" ]]; then
    echo "$PUBLIC_BUCKETS"
    HIGH=$((HIGH + 1))
else
    echo "No potentially public buckets found"
fi
echo ""

# Check firewall rules
echo "### Network Security ###"
echo ""
echo "#### Firewall Rules Allowing 0.0.0.0/0 ####"
OPEN_FW=$(gcloud compute firewall-rules list --project="${PROJECT}" --format=json 2>/dev/null | \
    jq -r '.[] | select(.sourceRanges[]? == "0.0.0.0/0") | "\(.name): \(.allowed[].ports // ["all"] | join(","))"' 2>/dev/null || echo "")
if [[ -n "$OPEN_FW" ]]; then
    echo "$OPEN_FW"
    MEDIUM=$((MEDIUM + 1))
else
    echo "No overly permissive firewall rules found"
fi
echo ""

# Recent admin activities
echo "### Recent Admin Activities (Last 24h) ###"
gcloud logging read 'logName:"cloudaudit.googleapis.com%2Factivity" AND protoPayload.methodName:("SetIamPolicy" OR "CreateServiceAccountKey" OR "delete")' \
    --project="${PROJECT}" \
    --format='table(timestamp,protoPayload.authenticationInfo.principalEmail,protoPayload.methodName)' \
    --limit=20 2>/dev/null || echo "Cannot access audit logs"
echo ""

# Summary
echo "=== Audit Summary ==="
echo "Critical: ${CRITICAL}"
echo "High: ${HIGH}"
echo "Medium: ${MEDIUM}"
echo "Low: ${LOW}"
echo ""

TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW))
if [[ $CRITICAL -gt 0 ]]; then
    echo "Status: CRITICAL - Immediate action required"
    exit 2
elif [[ $HIGH -gt 0 ]]; then
    echo "Status: HIGH RISK - Review required"
    exit 1
elif [[ $TOTAL -gt 0 ]]; then
    echo "Status: MODERATE - Some improvements recommended"
    exit 0
else
    echo "Status: GOOD - No significant issues found"
    exit 0
fi
