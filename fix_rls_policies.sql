-- Fix Row Level Security (RLS) policies for conversations and messages tables

-- 1. Enable RLS on conversations table (if not already enabled)
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies if they exist
DROP POLICY IF EXISTS "Enable read access for users involved in conversation" ON conversations;
DROP POLICY IF EXISTS "Enable insert for users creating conversations" ON conversations;
DROP POLICY IF EXISTS "Enable update for users in conversation" ON conversations;

-- 3. Create RLS policies for conversations table
CREATE POLICY "Enable read access for users involved in conversation" ON conversations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM matches m 
            WHERE m.id = conversations.match_id 
            AND (m.candidate_id = auth.uid() OR m.target_candidate_id = auth.uid() OR m.selector_id = auth.uid())
        )
    );

CREATE POLICY "Enable insert for users creating conversations" ON conversations
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM matches m 
            WHERE m.id = conversations.match_id 
            AND (m.candidate_id = auth.uid() OR m.target_candidate_id = auth.uid() OR m.selector_id = auth.uid())
        )
    );

CREATE POLICY "Enable update for users in conversation" ON conversations
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM matches m 
            WHERE m.id = conversations.match_id 
            AND (m.candidate_id = auth.uid() OR m.target_candidate_id = auth.uid() OR m.selector_id = auth.uid())
        )
    );

-- 4. Enable RLS on messages table (if not already enabled)
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 5. Drop existing policies if they exist
DROP POLICY IF EXISTS "Enable read access for users in conversation" ON messages;
DROP POLICY IF EXISTS "Enable insert for users in conversation" ON messages;
DROP POLICY IF EXISTS "Enable update for message sender" ON messages;

-- 6. Create RLS policies for messages table
CREATE POLICY "Enable read access for users in conversation" ON messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conversations c
            JOIN matches m ON c.match_id = m.id 
            WHERE c.id = messages.conversation_id 
            AND (m.candidate_id = auth.uid() OR m.target_candidate_id = auth.uid() OR m.selector_id = auth.uid())
        )
    );

CREATE POLICY "Enable insert for users in conversation" ON messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM conversations c
            JOIN matches m ON c.match_id = m.id 
            WHERE c.id = messages.conversation_id 
            AND (m.candidate_id = auth.uid() OR m.target_candidate_id = auth.uid() OR m.selector_id = auth.uid())
        )
    );

CREATE POLICY "Enable update for message sender" ON messages
    FOR UPDATE USING (sender_id = auth.uid());

-- 7. Grant necessary permissions
GRANT ALL ON conversations TO authenticated;
GRANT ALL ON messages TO authenticated;

-- 8. Verification queries (run these to test the policies)
-- SELECT * FROM conversations WHERE match_id IN (SELECT id FROM matches WHERE candidate_id = auth.uid() OR target_candidate_id = auth.uid() OR selector_id = auth.uid());
-- SELECT * FROM messages WHERE conversation_id IN (SELECT id FROM conversations WHERE match_id IN (SELECT id FROM matches WHERE candidate_id = auth.uid() OR target_candidate_id = auth.uid() OR selector_id = auth.uid()));