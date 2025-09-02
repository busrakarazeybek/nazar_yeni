-- Fix messages UPDATE policy with correct conversations table fields
-- Location: supabase/migrations/20250127170000_fix_messages_update_policy.sql

-- Drop the incorrect policy
DROP POLICY IF EXISTS "Users can update messages they can read" ON public.messages;

-- Create corrected UPDATE policy for messages table
CREATE POLICY "Users can update messages they can read"
ON public.messages
FOR UPDATE
TO authenticated
USING (
    sender_id = auth.uid() 
    OR EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_id 
        AND (c.participant_one_id = auth.uid() OR c.participant_two_id = auth.uid())
    )
    OR public.is_admin()
)
WITH CHECK (
    sender_id = auth.uid() 
    OR EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_id 
        AND (c.participant_one_id = auth.uid() OR c.participant_two_id = auth.uid())
    )
    OR public.is_admin()
);