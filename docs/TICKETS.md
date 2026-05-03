# Ticket Type System

## Concept

| Type | Purpose | Example |
|------|---------|----------|
| **INITIATIVE** | Root: top-level container | Software Factory |
| **EPIC** | Child of INITIATIVE | Core Development |
| **STORY** | Work package: user story with value | Login flow |
| **BUG** | Work package: fix defect | Fix login bug |
| **TASK** | Work package: technical work | Docker fix |
| **FINDING** | Issue discovered during test | API keys in logs |

## Hierarchy

Use Plane's **parent → child** relation:

```
[INITIATIVE] Software Factory (root)
  └── [EPIC] Core Development (child)
  └── [EPIC] User Group and Role Management (child)
        └── [STORY] Login flow (grandchild of INITIATIVE)
              └── [FINDING] API timeout (great-grandchild)
                    └── [BUG] Fix timeout handling
```

- **INITIATIVE**: Root (no parent) - top-level container
- **EPIC**: Child of INITIATIVE - specific area
- STORIES → children of EPIC (or direct children of INITIATIVE)
- STORIES tested → FINDINGS
- FINDINGS → BUG (fix) OR STORY (improvement)
- Use "parent" field in Plane, not labels

## Structure

1. **Issue (Work item)** = WHAT to do
   - Name: `[TYPE] summary` (~50 chars)
   - Description: full details, requirements, test cases

2. **Cycle** = WHEN to do it
   - Set via Plane UI (Project → Cycles)

3. **Module** = WHERE (technical object)
   - Set via Plane UI (Project → Modules)

4. **Labels** = ORG information
   - Team: ops, dev, sec
   - Dependencies: blocked-by, relates-to