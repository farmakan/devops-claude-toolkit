---
description: Review and analyze Terraform plan output for infrastructure changes
allowed-tools:
  - Bash(terraform:*)
  - Bash(cat:*)
  - Read
  - Grep
  - Glob
argument-hint: [terraform-dir]
model: opus
---

# Terraform Plan Analysis

## Target Directory
- **Path**: $ARGUMENTS (default: current directory)
- **Timestamp**: !`date -u '+%Y-%m-%d %H:%M:%S UTC'`

---

## Terraform State

### Current Workspace
```
!`cd ${ARGUMENTS:-.} && terraform workspace show 2>/dev/null || echo "Not a terraform directory or not initialized"`
```

### State Overview
```
!`cd ${ARGUMENTS:-.} && terraform state list 2>/dev/null | head -30 || echo "Cannot access state"`
```

---

## Plan Generation

### Generate Plan
```
!`cd ${ARGUMENTS:-.} && terraform plan -no-color -out=/tmp/tfplan 2>&1 | head -200 || echo "Plan failed"`
```

### Plan Summary
```
!`cd ${ARGUMENTS:-.} && terraform show -no-color /tmp/tfplan 2>/dev/null | head -300 || echo "No plan to show"`
```

---

## Change Analysis

### Resources to Create
```
!`cd ${ARGUMENTS:-.} && terraform show -json /tmp/tfplan 2>/dev/null | jq -r '.resource_changes[] | select(.change.actions[] == "create") | "\(.address)"' | head -20 || echo "None"`
```

### Resources to Destroy
```
!`cd ${ARGUMENTS:-.} && terraform show -json /tmp/tfplan 2>/dev/null | jq -r '.resource_changes[] | select(.change.actions[] == "delete") | "\(.address)"' | head -20 || echo "None"`
```

### Resources to Update
```
!`cd ${ARGUMENTS:-.} && terraform show -json /tmp/tfplan 2>/dev/null | jq -r '.resource_changes[] | select(.change.actions[] == "update") | "\(.address)"' | head -20 || echo "None"`
```

### Resources to Replace (Destroy + Create)
```
!`cd ${ARGUMENTS:-.} && terraform show -json /tmp/tfplan 2>/dev/null | jq -r '.resource_changes[] | select(.change.actions | contains(["delete", "create"])) | "\(.address) - REPLACING"' | head -20 || echo "None"`
```

---

## Security Review

### IAM Changes
```
!`cd ${ARGUMENTS:-.} && terraform show -json /tmp/tfplan 2>/dev/null | jq -r '.resource_changes[] | select(.address | contains("iam")) | "\(.change.actions[0]): \(.address)"' | head -20 || echo "No IAM changes"`
```

### Network Changes
```
!`cd ${ARGUMENTS:-.} && terraform show -json /tmp/tfplan 2>/dev/null | jq -r '.resource_changes[] | select(.address | test("network|firewall|security_group|vpc")) | "\(.change.actions[0]): \(.address)"' | head -20 || echo "No network changes"`
```

### Public Access Changes
```
!`cd ${ARGUMENTS:-.} && terraform show -no-color /tmp/tfplan 2>/dev/null | grep -A5 -B5 "0.0.0.0/0\|public\|external" | head -30 || echo "No obvious public access changes"`
```

---

## Cost Impact (Estimated)

### New Resources with Cost Implications
```
!`cd ${ARGUMENTS:-.} && terraform show -json /tmp/tfplan 2>/dev/null | jq -r '.resource_changes[] | select(.change.actions[] == "create") | select(.address | test("instance|disk|sql|storage|cluster")) | "\(.address)"' | head -20 || echo "Check Infracost for estimates"`
```

---

## Output Format

Provide a plan review:

```markdown
## Terraform Plan Review

**Directory**: [path]
**Workspace**: [workspace]
**Review Time**: [timestamp]

### Change Summary
| Action | Count | Resources |
|--------|-------|-----------|
| Create | X | [list] |
| Update | X | [list] |
| Delete | X | [list] |
| Replace | X | [list] |

### Risk Assessment
**Overall Risk**: [Low/Medium/High/Critical]

### Critical Changes Requiring Review
1. [Change with explanation of why it's significant]
2. [Change with explanation]

### Security Considerations
- [Any IAM/network changes that need attention]

### Cost Implications
- [Estimated impact on monthly spend]

### Recommendations
1. [Proceed / Review / Block with reason]
```
