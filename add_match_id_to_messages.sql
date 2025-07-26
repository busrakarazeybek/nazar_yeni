-- Add match_id column to messages table
ALTER TABLE messages 
ADD COLUMN match_id UUID;

-- Add foreign key constraint to matches table
ALTER TABLE messages 
ADD CONSTRAINT fk_messages_match_id 
FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE;

-- Create index for better query performance
CREATE INDEX idx_messages_match_id ON messages(match_id);

-- Update existing messages to populate match_id from conversations
UPDATE messages m
SET match_id = c.match_id
FROM conversations c
WHERE m.conversation_id = c.id;

-- Optional: Make match_id NOT NULL after data migration
-- ALTER TABLE messages ALTER COLUMN match_id SET NOT NULL;