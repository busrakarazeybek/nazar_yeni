-- Add read_at column to messages table for tracking when messages were read
-- Location: supabase/migrations/20250120120000_add_read_at_column_to_messages.sql

-- Check if read_at column exists, if not add it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'messages' AND column_name = 'read_at') THEN
        ALTER TABLE public.messages ADD COLUMN read_at TIMESTAMPTZ;
    END IF;
END $$;

-- Update existing read messages to have a read_at timestamp
UPDATE public.messages 
SET read_at = created_at 
WHERE is_read = true AND read_at IS NULL;

-- Create index for read_at column to improve query performance
CREATE INDEX IF NOT EXISTS idx_messages_read_at ON public.messages(read_at) WHERE read_at IS NOT NULL;

-- Create index for unread messages queries
CREATE INDEX IF NOT EXISTS idx_messages_unread ON public.messages(conversation_id, is_read) WHERE is_read = false;

-- Add comment
COMMENT ON COLUMN public.messages.read_at IS 'Timestamp when the message was marked as read by the recipient';