-- List all type prefixes in the project
-- Helps identify items that don't belong

SELECT 
    SUBSTRING(name FROM 1 FOR position(']' IN name)+1) as type,
    COUNT(*) as count
FROM issues 
WHERE deleted_at IS NULL
GROUP BY type
ORDER BY count DESC;