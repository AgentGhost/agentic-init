-- Remove items that belong to a different project
-- These items got mixed into the current project and should be moved or deleted
--
-- Usage: 
--   1. Preview: SELECT * FROM issues WHERE name LIKE '[TYPE]%';
--   2. Run: UPDATE issues SET deleted_at = NOW() WHERE name LIKE '[TYPE]%';

-- Common project prefixes to check:
-- [TECH], [UI], [EYE], [VANGUARD], [LIGHTHOUSE] - game UI/HUD items
-- [VANGUARD], [LIGHTHOUSE] - likely different project

-- Soft delete (move to trash)
-- UPDATE issues SET deleted_at = NOW() WHERE name LIKE '[TECH]%';

-- Hard delete (requires clearing all foreign keys first - complex!)
-- See remove-items-hard.sql for full procedure