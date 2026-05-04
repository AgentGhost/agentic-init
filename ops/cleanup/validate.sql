-- =============================================================================
-- Plane Project Validation Report
-- =============================================================================
-- Checks all must-haves per docs/TICKETS.md
-- Run: docker exec agentic-init-ops-plane-db-1 psql -U plane -d plane -f /tmp/validate.sql
--
-- MUST-HAVES (required):
--   - Name: [TYPE] summary format
--   - Description: non-empty
--   - Hierarchy: INITIATIVE → EPIC → STORY
--
-- RECOMMENDED (optional):
--   - Cycle: Phase assignment
--   - Module: Component assignment
-- =============================================================================

-- CHECK 1: Name format [TYPE] summary
-- Must have prefix like [INITIATIVE], [EPIC], [STORY], etc.
SELECT 'Name format [TYPE] summary' as check, 
    CASE WHEN name !~ '^\[.*\] ' THEN 'MISSING [TYPE] prefix' ELSE 'OK' END as status, COUNT(*) as cnt
FROM issues WHERE deleted_at IS NULL GROUP BY status;

-- CHECK 2: Description required
-- Each issue must have meaningful description
SELECT 'Description required' as check, 
    CASE WHEN description_html IS NULL OR description_html = '<p></p>' THEN 'MISSING' ELSE 'OK' END as status, COUNT(*) as cnt
FROM issues WHERE deleted_at IS NULL GROUP BY status;

-- CHECK 3: INITIATIVE has no parent
-- INITIATIVE is root - should have no parent
SELECT 'INITIATIVE: no parent (root)' as check,
    CASE WHEN parent_id IS NULL THEN 'OK' ELSE 'HAS parent (should be none)' END as status, COUNT(*) as cnt
FROM issues WHERE name LIKE '[INITIATIVE]%' AND deleted_at IS NULL GROUP BY status;

-- CHECK 4: EPIC has INITIATIVE as parent
-- EPIC must be child of INITIATIVE (per hierarchy)
SELECT 'EPIC: has INITIATIVE parent' as check,
    CASE WHEN p.name LIKE '[INITIATIVE]%' THEN 'OK'
         WHEN p.name IS NULL THEN 'ORPHAN (no parent)'
         ELSE 'WRONG parent' END as status, COUNT(*) as cnt
FROM issues e LEFT JOIN issues p ON e.parent_id = p.id
WHERE e.name LIKE '[EPIC]%' AND e.deleted_at IS NULL GROUP BY status;

-- CHECK 5: STORY has parent (EPIC or INITIATIVE)
-- STORY must have parent - either EPIC or INITIATIVE
SELECT 'STORY: has parent' as check,
    CASE WHEN parent_id IS NULL THEN 'ORPHAN (no parent)' ELSE 'OK' END as status, COUNT(*) as cnt
FROM issues WHERE name LIKE '[STORY]%' AND deleted_at IS NULL GROUP BY status;

-- CHECK 6: Cycle assigned (optional but recommended)
-- Cycle = WHEN (Phase 1-5 from TICKETS.md)
SELECT 'Cycle assigned (optional)' as check,
    CASE WHEN ci.cycle_id IS NULL THEN 'NOT assigned' ELSE 'OK' END as status, COUNT(*) as cnt
FROM issues i LEFT JOIN cycle_issues ci ON i.id = ci.issue_id
WHERE i.deleted_at IS NULL GROUP BY status;

-- CHECK 7: Module assigned (optional but recommended)
-- Module = WHERE (technical component)
SELECT 'Module assigned (optional)' as check,
    CASE WHEN mi.module_id IS NULL THEN 'NOT assigned' ELSE 'OK' END as status, COUNT(*) as cnt
FROM issues i LEFT JOIN module_issues mi ON i.id = mi.issue_id
WHERE i.deleted_at IS NULL GROUP BY status;

-- SUMMARY: Total active issues
SELECT '========== SUMMARY ==========' as check, '' as status, COUNT(*) as cnt FROM issues WHERE deleted_at IS NULL;