-- Real-time update tables for Supabase

-- Typing status table for chat
CREATE TABLE IF NOT EXISTS typing_status (
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, conversation_id)
);

-- Real-time events table for custom events
CREATE TABLE IF NOT EXISTS realtime_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_type TEXT NOT NULL,
    payload JSONB,
    sender_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    target_user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User gallery table for image galleries
CREATE TABLE IF NOT EXISTS user_gallery (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
    image_url TEXT NOT NULL,
    caption TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add online status columns to user_profiles if they don't exist
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_typing_status_conversation ON typing_status(conversation_id);
CREATE INDEX IF NOT EXISTS idx_typing_status_updated ON typing_status(updated_at);
CREATE INDEX IF NOT EXISTS idx_realtime_events_target ON realtime_events(target_user_id);
CREATE INDEX IF NOT EXISTS idx_realtime_events_created ON realtime_events(created_at);
CREATE INDEX IF NOT EXISTS idx_user_gallery_user ON user_gallery(user_id);
CREATE INDEX IF NOT EXISTS idx_user_gallery_created ON user_gallery(created_at);
CREATE INDEX IF NOT EXISTS idx_user_profiles_online ON user_profiles(is_online);
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_seen ON user_profiles(last_seen);

-- Enable Row Level Security (RLS)
ALTER TABLE typing_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE realtime_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_gallery ENABLE ROW LEVEL SECURITY;

-- RLS Policies for typing_status
CREATE POLICY "Users can view typing status in their conversations" ON typing_status
    FOR SELECT USING (
        conversation_id IN (
            SELECT c.id FROM conversations c
            JOIN matches m ON c.match_id = m.id
            WHERE m.candidate_id = auth.uid() 
               OR m.target_candidate_id = auth.uid() 
               OR m.selector_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own typing status" ON typing_status
    FOR ALL USING (user_id = auth.uid());

-- RLS Policies for realtime_events
CREATE POLICY "Users can view events sent to them" ON realtime_events
    FOR SELECT USING (target_user_id = auth.uid() OR sender_id = auth.uid());

CREATE POLICY "Users can insert their own events" ON realtime_events
    FOR INSERT WITH CHECK (sender_id = auth.uid());

-- RLS Policies for user_gallery
CREATE POLICY "Users can view their own gallery" ON user_gallery
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own gallery" ON user_gallery
    FOR ALL USING (user_id = auth.uid());

-- Function to automatically clean old typing status
CREATE OR REPLACE FUNCTION cleanup_old_typing_status()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM typing_status 
    WHERE updated_at < NOW() - INTERVAL '30 seconds';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to clean up old typing status
DROP TRIGGER IF EXISTS cleanup_typing_status_trigger ON typing_status;
CREATE TRIGGER cleanup_typing_status_trigger
    AFTER INSERT OR UPDATE ON typing_status
    EXECUTE FUNCTION cleanup_old_typing_status();

-- Function to automatically update last_seen on user activity
CREATE OR REPLACE FUNCTION update_user_last_seen()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE user_profiles 
    SET last_seen = NOW() 
    WHERE id = auth.uid();
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers to update last_seen on various activities
DROP TRIGGER IF EXISTS update_last_seen_on_message ON messages;
CREATE TRIGGER update_last_seen_on_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_user_last_seen();

DROP TRIGGER IF EXISTS update_last_seen_on_match ON matches;
CREATE TRIGGER update_last_seen_on_match
    AFTER INSERT OR UPDATE ON matches
    FOR EACH ROW
    EXECUTE FUNCTION update_user_last_seen();

-- Enable real-time subscriptions for new tables
ALTER PUBLICATION supabase_realtime ADD TABLE typing_status;
ALTER PUBLICATION supabase_realtime ADD TABLE realtime_events;
ALTER PUBLICATION supabase_realtime ADD TABLE user_gallery;

-- Update existing publication to include user_profiles changes
ALTER PUBLICATION supabase_realtime ADD TABLE user_profiles;