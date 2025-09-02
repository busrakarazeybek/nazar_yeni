-- Add missing UPDATE policy for messages table
-- Location: supabase/migrations/20250127160000_add_messages_update_policy.sql

-- Create UPDATE policy for messages table
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