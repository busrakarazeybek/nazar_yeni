-- ROLLBACK: Remove match_id column from messages table
-- Bu komutları sırasıyla çalıştırın

-- 1. Drop the index first
DROP INDEX IF EXISTS idx_messages_match_id;

-- 2. Drop the foreign key constraint
ALTER TABLE messages 
DROP CONSTRAINT IF EXISTS fk_messages_match_id;

-- 3. Drop the match_id column (this will also remove all data in that column)
ALTER TABLE messages 
DROP COLUMN IF EXISTS match_id;

-- Verification query - Bu sorguyu çalıştırarak sütunun silindiğini kontrol edebilirsiniz
-- SELECT column_name 
-- FROM information_schema.columns 
-- WHERE table_name = 'messages' AND column_name = 'match_id';