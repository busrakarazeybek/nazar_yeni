-- Fix Conversations Foreign Key Constraint
-- Location: supabase/migrations/20241221120000_fix_conversations_foreign_key_constraint.sql
-- This migration fixes the foreign key constraint violation in conversations table

-- 1. First, check if conversations table exists and has the match_id column
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'conversations') THEN
        -- Check if match_id column exists
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'conversations' AND column_name = 'match_id') THEN
            
            -- Clean up orphaned conversation records that reference non-existent match_proposals
            DELETE FROM public.conversations 
            WHERE match_id IS NOT NULL 
            AND match_id NOT IN (SELECT id FROM public.match_proposals);
            
            -- Log the cleanup
            RAISE NOTICE 'Cleaned up orphaned conversation records';
        END IF;
    END IF;
END $$;

-- 2. Ensure match_proposals table exists before creating foreign key constraint
CREATE TABLE IF NOT EXISTS public.match_proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    selector_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    candidate_1_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    candidate_2_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    status_1 public.match_proposal_status DEFAULT 'pending'::public.match_proposal_status,
    status_2 public.match_proposal_status DEFAULT 'pending'::public.match_proposal_status,
    final_status public.match_proposal_status DEFAULT 'pending'::public.match_proposal_status,
    selector_message TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT different_candidates CHECK (candidate_1_id != candidate_2_id)
);

-- 3. Create conversations table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID,
    participant_one_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    participant_two_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    last_message_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Now safely add the foreign key constraint
DO $$
BEGIN
    -- Check if the constraint already exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'conversations' 
        AND constraint_name = 'conversations_match_id_fkey'
        AND constraint_type = 'FOREIGN KEY'
    ) THEN
        -- Add the foreign key constraint
        ALTER TABLE public.conversations 
        ADD CONSTRAINT conversations_match_id_fkey 
        FOREIGN KEY (match_id) REFERENCES public.match_proposals(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Foreign key constraint added successfully';
    ELSE
        RAISE NOTICE 'Foreign key constraint already exists';
    END IF;
    
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint violation: %', SQLERRM;
        
        -- Additional cleanup if needed
        DELETE FROM public.conversations 
        WHERE match_id IS NOT NULL 
        AND match_id NOT IN (SELECT id FROM public.match_proposals);
        
        -- Try again
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE table_name = 'conversations' 
            AND constraint_name = 'conversations_match_id_fkey'
            AND constraint_type = 'FOREIGN KEY'
        ) THEN
            ALTER TABLE public.conversations 
            ADD CONSTRAINT conversations_match_id_fkey 
            FOREIGN KEY (match_id) REFERENCES public.match_proposals(id) ON DELETE CASCADE;
        END IF;
        
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 5. Create indexes for performance if they don't exist
CREATE INDEX IF NOT EXISTS idx_conversations_match_id ON public.conversations(match_id);
CREATE INDEX IF NOT EXISTS idx_conversations_participants ON public.conversations(participant_one_id, participant_two_id);

-- 6. Enable RLS if not already enabled
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- 7. Create or update RLS policies for conversations
DROP POLICY IF EXISTS "conversation_participants_access" ON public.conversations;
CREATE POLICY "conversation_participants_access"
ON public.conversations
FOR ALL
TO authenticated
USING (
    participant_one_id = auth.uid() 
    OR participant_two_id = auth.uid()
    OR public.is_admin()
)
WITH CHECK (
    participant_one_id = auth.uid() 
    OR participant_two_id = auth.uid()
    OR public.is_admin()
);

-- 8. Create helper function to validate conversation access
CREATE OR REPLACE FUNCTION public.can_access_conversation(conversation_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = conversation_uuid 
    AND (
        c.participant_one_id = auth.uid() 
        OR c.participant_two_id = auth.uid()
        OR public.is_admin()
    )
)
$$;

-- 9. Create sample data if match_proposals table was empty
DO $$
DECLARE
    selector_uuid UUID;
    candidate1_uuid UUID;
    candidate2_uuid UUID;
    proposal_uuid UUID;
    conversation_count INTEGER;
    proposal_count INTEGER;
BEGIN
    -- Check if we need to create sample data
    SELECT COUNT(*) INTO conversation_count FROM public.conversations;
    SELECT COUNT(*) INTO proposal_count FROM public.match_proposals;
    
    IF conversation_count = 0 AND proposal_count = 0 THEN
        -- Get existing user IDs
        SELECT id INTO selector_uuid FROM public.user_profiles WHERE role = 'selector'::public.user_role LIMIT 1;
        SELECT id INTO candidate1_uuid FROM public.user_profiles WHERE role = 'candidate'::public.user_role LIMIT 1;
        SELECT id INTO candidate2_uuid FROM public.user_profiles WHERE role = 'candidate'::public.user_role OFFSET 1 LIMIT 1;
        
        -- Create sample match proposal if users exist
        IF selector_uuid IS NOT NULL AND candidate1_uuid IS NOT NULL AND candidate2_uuid IS NOT NULL THEN
            INSERT INTO public.match_proposals (
                selector_id, candidate_1_id, candidate_2_id, 
                status_1, status_2, final_status, selector_message
            ) VALUES (
                selector_uuid, candidate1_uuid, candidate2_uuid,
                'accepted'::public.match_proposal_status,
                'accepted'::public.match_proposal_status,
                'matched'::public.match_proposal_status,
                'Sample matched proposal for conversation'
            ) RETURNING id INTO proposal_uuid;
            
            -- Create sample conversation
            INSERT INTO public.conversations (
                match_id, participant_one_id, participant_two_id
            ) VALUES (
                proposal_uuid, candidate1_uuid, candidate2_uuid
            );
            
            RAISE NOTICE 'Sample data created successfully';
        END IF;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Sample data creation failed: %', SQLERRM;
END $$;

-- 10. Create data integrity validation function
CREATE OR REPLACE FUNCTION public.validate_conversation_data()
RETURNS TABLE(
    orphaned_conversations INTEGER,
    total_conversations INTEGER,
    valid_conversations INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(
            (SELECT COUNT(*)::INTEGER FROM public.conversations c 
             WHERE c.match_id IS NOT NULL 
             AND c.match_id NOT IN (SELECT id FROM public.match_proposals)), 
            0
        ) as orphaned_conversations,
        COALESCE(
            (SELECT COUNT(*)::INTEGER FROM public.conversations), 
            0
        ) as total_conversations,
        COALESCE(
            (SELECT COUNT(*)::INTEGER FROM public.conversations c 
             WHERE c.match_id IS NULL 
             OR c.match_id IN (SELECT id FROM public.match_proposals)), 
            0
        ) as valid_conversations;
END;
$$;

-- 11. Final validation
DO $$
DECLARE
    validation_result RECORD;
BEGIN
    -- Run validation
    SELECT * INTO validation_result FROM public.validate_conversation_data();
    
    RAISE NOTICE 'Data validation complete:';
    RAISE NOTICE 'Total conversations: %', validation_result.total_conversations;
    RAISE NOTICE 'Valid conversations: %', validation_result.valid_conversations;
    RAISE NOTICE 'Orphaned conversations: %', validation_result.orphaned_conversations;
    
    -- Clean up any remaining orphaned data
    IF validation_result.orphaned_conversations > 0 THEN
        DELETE FROM public.conversations 
        WHERE match_id IS NOT NULL 
        AND match_id NOT IN (SELECT id FROM public.match_proposals);
        
        RAISE NOTICE 'Cleaned up % orphaned conversations', validation_result.orphaned_conversations;
    END IF;
    
END $$;