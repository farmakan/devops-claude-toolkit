---
description: Generate an Architecture Decision Record from analysis conversation
allowed-tools:
  - Read
  - Write(docs/**)
  - Glob
  - Bash(ls *)
  - Bash(date *)
argument-hint: <decision-topic>
model: sonnet
---

# Generate ADR: $ARGUMENTS

## Context Gathering

### Existing ADRs
```
!`ls -la docs/decisions/ADR-*.md 2>/dev/null | tail -10 || echo "No existing ADRs found"`
```

### Next ADR Number
```
!`printf "ADR-%03d" $(( $(ls docs/decisions/ADR-*.md 2>/dev/null | wc -l) + 1 ))`
```

### Current Date
```
!`date '+%Y-%m-%d'`
```

---

## Your Task

Using the adr-generation skill, create an ADR for: **$ARGUMENTS**

### Step 1: Extract Decision from Conversation
Review our conversation to identify:
- What technical decision was made or is being proposed?
- What problem does this address?
- What evidence supports this decision?

### Step 2: Document Thoroughly
Create a complete ADR with:
- Clear, specific title
- Full context from our analysis
- Concrete consequences (positive and negative)
- Alternatives that were considered

### Step 3: Save the ADR
Write the ADR to: `docs/decisions/[ADR-NUMBER]-[slug].md`

Where slug is derived from the topic:
- Lowercase
- Hyphens instead of spaces
- No special characters
- Example: "migrate-auth-to-oauth2"

---

## Quality Checklist

Before saving, verify:
- [ ] Title clearly describes the decision
- [ ] Context explains WHY this decision was needed
- [ ] Decision is stated in present tense ("We will...")
- [ ] Consequences are specific and measurable where possible
- [ ] At least 2 alternatives are documented
- [ ] References link to relevant analysis/data

---

## Output

After creating the ADR:
1. Show the full content
2. Confirm the file path
3. Summarize the key decision in 1-2 sentences
