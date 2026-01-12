---
description: Comprehensive Kubernetes cluster security and configuration audit
allowed-tools:
  - Bash(kubectl *)
  - Bash(gcloud *)
  - Read
  - Grep
argument-hint: [namespace]
model: opus
---

# Kubernetes Security Audit

## Target
- **Namespace**: $ARGUMENTS (default: all namespaces)
- **Cluster**: !`kubectl config current-context 2>/dev/null || echo "No context"`
- **Timestamp**: !`date -u '+%Y-%m-%d %H:%M:%S UTC'`

---

## Cluster Overview

### Node Status
```
!`kubectl get nodes -o wide 2>/dev/null || echo "Cannot access nodes"`
```

### Namespace Summary
```
!`kubectl get namespaces 2>/dev/null || echo "Cannot list namespaces"`
```

---

## Security Checks

### Pods Running as Root
```
!`kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.spec.securityContext.runAsUser}{"\n"}{end}' 2>/dev/null | grep -E '\t0$|\t$' | head -20 || echo "Check complete"`
```

### Privileged Containers
```
!`kubectl get pods -A -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.name}{"\t"}{.securityContext.privileged}{"\n"}{end}{end}' 2>/dev/null | grep true | head -20 || echo "No privileged containers found"`
```

### Host Network/PID Pods
```
!`kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}hostNetwork:{.spec.hostNetwork}{"\t"}hostPID:{.spec.hostPID}{"\n"}{end}' 2>/dev/null | grep true | head -20 || echo "No host network/PID pods"`
```

### Secrets in Environment Variables
```
!`kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}: {range .spec.containers[*]}{range .env[*]}{.name}={.valueFrom.secretKeyRef.name}/{.valueFrom.secretKeyRef.key} {end}{end}{"\n"}{end}' 2>/dev/null | grep -v ": $" | head -20 || echo "Check complete"`
```

---

## Resource Configuration

### Pods Without Resource Limits
```
!`kubectl get pods -A -o json 2>/dev/null | jq -r '.items[] | select(.spec.containers[].resources.limits == null) | "\(.metadata.namespace)/\(.metadata.name)"' | head -20 || echo "Check complete"`
```

### Pods Without Liveness Probes
```
!`kubectl get pods -A -o json 2>/dev/null | jq -r '.items[] | select(.spec.containers[].livenessProbe == null) | "\(.metadata.namespace)/\(.metadata.name)"' | head -20 || echo "Check complete"`
```

### High Restart Count Pods
```
!`kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{range .status.containerStatuses[*]}{.restartCount}{" "}{end}{"\n"}{end}' 2>/dev/null | awk '$3 > 5 {print}' | head -20 || echo "No high restart pods"`
```

---

## Network Policies

### Namespaces Without Network Policies
```
!`for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do count=$(kubectl get networkpolicies -n $ns 2>/dev/null | wc -l); if [ $count -eq 0 ]; then echo "$ns: NO NETWORK POLICIES"; fi; done | head -20`
```

---

## RBAC Review

### ClusterRoleBindings with cluster-admin
```
!`kubectl get clusterrolebindings -o json 2>/dev/null | jq -r '.items[] | select(.roleRef.name == "cluster-admin") | "\(.metadata.name): \(.subjects[].name)"' || echo "Check complete"`
```

### Service Accounts with Secrets
```
!`kubectl get serviceaccounts -A -o json 2>/dev/null | jq -r '.items[] | select(.secrets != null) | "\(.metadata.namespace)/\(.metadata.name): \(.secrets | length) secrets"' | head -20 || echo "Check complete"`
```

---

## Output Format

Produce an audit report:

```markdown
## K8s Security Audit Summary

**Cluster**: [name]
**Audit Time**: [timestamp]

### Critical Findings
| Finding | Count | Risk | Recommendation |
|---------|-------|------|----------------|

### Security Score
[X/10] - [Brief assessment]

### Priority Remediation Items
1. [Most critical issue with specific fix]
2. [Second priority]
3. [Third priority]

### Compliance Gaps
- [ ] [Gap with reference to best practice]
```
