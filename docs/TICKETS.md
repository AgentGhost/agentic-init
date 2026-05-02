# Ticket Type System

## Concept

| Type | Purpose | Example |
|------|---------|----------|
| **EPIC** | Work package: big feature/initiative | User management |
| **STORY** | Work package: user story with value | Login flow |
| **BUG** | Work package: fix defect | Fix login bug |
| **TASK** | Work package: technical work | Docker fix |
| **FINDING** | Issue discovered during test | API keys in logs |

## Hierarchy

Use Plane's **parent → child** relation:

```
[EPIC] User Management (parent)
  └── [STORY] Login flow (child)
  └── [STORY] Password reset (child)
        └── [FINDING] API timeout (child)
              └── [BUG] Fix timeout handling (child)
```

- EPIC has STORIES (分解)
- STORIES tested → FINDINGS
- FINDINGS → BUG or STORY (improvement)
- Use "parent" field in Plane, not labels

## Structure

1. **Issue (Work item)** = WHAT to do
   - Name: `[TYPE] summary` (~50 chars)
   - Description: full details, requirements, test cases

2. **Cycle** = WHEN to do it
   - Set via Plane UI Cycles, not in issue name

3. **Module** = WHERE (technical object)
   - Set via Plane UI Modules, not in issue name

4. **Labels** = ORG information
   - Team: ops, dev, sec (custom per project)
   - Dependencies: blocked-by, relates-to