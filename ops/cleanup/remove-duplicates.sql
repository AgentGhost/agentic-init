-- Remove duplicate INITIATIVEs
-- Keep first of each INITIATIVE name, soft-delete duplicates

-- Get duplicate INITIATIVE IDs to delete (keep first)
WITH init_names AS (
    SELECT name, MIN(id) as keep_id
    FROM issues 
    WHERE name LIKE '[INITIATIVE]%' AND deleted_at IS NULL
    GROUP BY name
    HAVING COUNT(*) > 1
)
SELECT i.id, i.name 
FROM issues i
JOIN init_names n ON i.name = n.name
WHERE i.id != n.keep_id;

-- Soft delete duplicates
-- UPDATE issues SET deleted_at = NOW()
-- WHERE id IN (/* IDs from above */);