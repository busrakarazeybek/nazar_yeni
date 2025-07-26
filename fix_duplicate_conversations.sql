-- Fix duplicate conversations issue

-- 1. Remove duplicate conversations (keep only the first one for each match_id)
DELETE FROM conversations 
WHERE id NOT IN (
    SELECT DISTINCT ON (match_id) id 
    FROM conversations 
    ORDER BY match_id, created_at ASC
);

-- 2. Add unique constraint to prevent future duplicates
ALTER TABLE conversations 
ADD CONSTRAINT unique_match_conversation 
UNIQUE (match_id);

-- 3. Create index for better performance
CREATE INDEX IF NOT EXISTS idx_conversations_match_id_unique 
ON conversations (match_id);

-- 4. Verify no duplicates remain
-- SELECT match_id, COUNT(*) as count 
-- FROM conversations 
-- GROUP BY match_id 
-- HAVING COUNT(*) > 1;