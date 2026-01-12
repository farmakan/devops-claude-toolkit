---
name: adr-generation
description: Generate Architecture Decision Records from analysis findings. Invoked when documenting technical decisions, recording architectural choices, or creating decision records.
allowed-tools:
  - Read
  - Write(docs/**)
  - Glob
---

# ADR Generation Skill

## Purpose
Create standardized Architecture Decision Records to document significant technical decisions made during or after analysis.

## ADR Numbering
```bash
# Get next ADR number
NEXT_NUM=$(ls docs/decisions/ADR-*.md 2>/dev/null | wc -l | awk '{print $1 + 1}')
printf "ADR-%03d" ${NEXT_NUM}
```

## Standard Template

```markdown
# ADR-{NUMBER}: {Title}

## Status
{Proposed | Accepted | Deprecated | Superseded by ADR-XXX}

## Date
{YYYY-MM-DD}

## Context
What is the issue that we're seeing that motivates this decision or change?

## Decision
What is the change that we're proposing and/or doing?

## Consequences

### Positive
- What becomes easier?
- What problems does this solve?

### Negative
- What becomes harder?
- What new problems might this create?

### Neutral
- What other effects does this have?

## Alternatives Considered

### Alternative 1: {Name}
- **Description**: What was this option?
- **Pros**: Why might we choose this?
- **Cons**: Why did we not choose this?

### Alternative 2: {Name}
...

## References
- [Link to relevant documentation]
- [Link to analysis that led to this decision]
```

## Generation Process

### Step 1: Identify the Decision
Extract from conversation:
- What technical choice was made?
- What problem does it solve?
- What triggered this decision?

### Step 2: Document Context
Pull evidence from the analysis:
- Error patterns found
- Performance data
- Cost implications
- Security considerations

### Step 3: Record Alternatives
Even if not explicitly discussed, document:
- Status quo (do nothing)
- Obvious alternatives
- Why they were rejected

### Step 4: List Consequences
Be specific and measurable where possible:
- "Reduces p99 latency from 500ms to 200ms"
- "Increases monthly cost by ~$500"
- "Requires 2 weeks of migration effort"

### Step 5: Write and Save
Save to: `docs/decisions/ADR-{number}-{slug}.md`

Slug format: lowercase, hyphens, no special chars
Example: `ADR-015-migrate-to-cloud-sql.md`

## Common Decision Categories

- **Infrastructure**: Cloud provider, regions, scaling approach
- **Architecture**: Microservices, event-driven, caching strategy
- **Technology**: Language, framework, database, queue
- **Security**: Authentication, encryption, access control
- **Operations**: Monitoring, alerting, deployment strategy
- **Cost**: Resource optimization, reserved capacity
