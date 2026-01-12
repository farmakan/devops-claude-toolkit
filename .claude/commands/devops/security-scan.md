---
description: Security posture scan across GCP project and Kubernetes
allowed-tools:
  - Bash(gcloud *)
  - Bash(kubectl *)
  - Read
  - Grep
argument-hint: [scope]
model: sonnet
---

# Security Posture Scan

## Scope
- **Target**: $ARGUMENTS (default: current project)
- **GCP Project**: !`gcloud config get-value project 2>/dev/null`
- **Timestamp**: !`date -u '+%Y-%m-%d %H:%M:%S UTC'`

---

## GCP Security Findings

### Security Command Center Findings
```
!`gcloud scc findings list $(gcloud config get-value project) --format=json 2>/dev/null | jq -r '.[] | "\(.finding.category): \(.finding.resourceName)"' | head -30 || echo "SCC not available or no findings"`
```

### Public Resources

#### Public Cloud Storage Buckets
```
!`gcloud storage buckets list --format=json 2>/dev/null | jq -r '.[] | select(.iamConfiguration.publicAccessPrevention != "enforced") | .name' | head -20 || echo "Check complete"`
```

#### Public Cloud Run Services
```
!`gcloud run services list --format=json 2>/dev/null | jq -r '.[] | select(.spec.template.metadata.annotations["run.googleapis.com/ingress"] == "all") | .metadata.name' | head -20 || echo "Check complete"`
```

#### External Load Balancers
```
!`gcloud compute forwarding-rules list --format=json 2>/dev/null | jq -r '.[] | select(.loadBalancingScheme == "EXTERNAL") | "\(.name): \(.IPAddress)"' | head -20 || echo "Check complete"`
```

---

## IAM Security

### Overly Permissive Bindings
```
!`gcloud projects get-iam-policy $(gcloud config get-value project) --format=json 2>/dev/null | jq -r '.bindings[] | select(.role | test("owner|editor|admin")) | "\(.role): \(.members | length) members"' || echo "Check complete"`
```

### External Users
```
!`gcloud projects get-iam-policy $(gcloud config get-value project) --format=json 2>/dev/null | jq -r '.bindings[].members[]' | grep -v "gserviceaccount.com" | grep -v "@$(gcloud config get-value project).iam" | sort -u | head -20 || echo "Check complete"`
```

### Service Account Keys
```
!`for sa in $(gcloud iam service-accounts list --format='value(email)' 2>/dev/null); do keys=$(gcloud iam service-accounts keys list --iam-account=$sa --format='value(name)' 2>/dev/null | wc -l); if [ $keys -gt 1 ]; then echo "$sa: $keys keys"; fi; done | head -20`
```

---

## Audit Log Review

### Recent Admin Activities
```
!`gcloud logging read 'logName:"cloudaudit.googleapis.com%2Factivity" AND protoPayload.methodName:("SetIamPolicy" OR "CreateServiceAccountKey" OR "delete")' --format=json --limit=20 2>/dev/null | jq -r '.[] | "\(.timestamp): \(.protoPayload.authenticationInfo.principalEmail) - \(.protoPayload.methodName)"' || echo "No recent admin activities"`
```

### Failed Authentication Attempts
```
!`gcloud logging read 'protoPayload.status.code!=0 AND protoPayload.authenticationInfo.principalEmail:*' --format=json --limit=20 2>/dev/null | jq -r '.[] | "\(.timestamp): \(.protoPayload.authenticationInfo.principalEmail)"' | sort | uniq -c | sort -rn | head -10 || echo "No failed auth attempts"`
```

---

## Kubernetes Security

### RBAC Issues
```
!`kubectl get clusterrolebindings -o json 2>/dev/null | jq -r '.items[] | select(.roleRef.name == "cluster-admin") | "cluster-admin binding: \(.metadata.name)"' || echo "Cannot check RBAC"`
```

### Pod Security
```
!`kubectl get pods -A -o json 2>/dev/null | jq -r '.items[] | select(.spec.containers[].securityContext.privileged == true) | "Privileged: \(.metadata.namespace)/\(.metadata.name)"' | head -20 || echo "Cannot check pod security"`
```

### Secrets Exposure
```
!`kubectl get secrets -A -o json 2>/dev/null | jq -r '.items[] | select(.type != "kubernetes.io/service-account-token") | "\(.metadata.namespace)/\(.metadata.name): \(.type)"' | head -30 || echo "Cannot check secrets"`
```

---

## Network Security

### Firewall Rules Allowing All Traffic
```
!`gcloud compute firewall-rules list --format=json 2>/dev/null | jq -r '.[] | select(.sourceRanges[]? == "0.0.0.0/0") | "\(.name): \(.allowed[].ports // "all")"' | head -20 || echo "Check complete"`
```

### VPC Flow Logs Status
```
!`gcloud compute networks subnets list --format=json 2>/dev/null | jq -r '.[] | "\(.name): flowLogs=\(.enableFlowLogs // false)"' | grep "false" | head -20 || echo "Check complete"`
```

---

## Output Format

Produce a security report:

```markdown
## Security Posture Report

**Project**: [project-id]
**Scan Time**: [timestamp]

### Risk Summary
| Severity | Count | Category |
|----------|-------|----------|
| Critical | X | [category] |
| High | X | [category] |
| Medium | X | [category] |
| Low | X | [category] |

### Critical Findings
1. **[Finding Title]**
   - Resource: [resource]
   - Risk: [description]
   - Remediation: [specific fix]

### Compliance Status
| Control | Status | Gap |
|---------|--------|-----|
| Least Privilege | Pass/Fail | [detail] |
| Network Security | Pass/Fail | [detail] |
| Audit Logging | Pass/Fail | [detail] |

### Immediate Actions Required
1. [Action with owner and deadline]
2. [Action with owner and deadline]

### Security Score: X/100
```
