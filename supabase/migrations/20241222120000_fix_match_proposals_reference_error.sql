-- Fix Match Proposals Reference Error
-- Location: supabase/migrations/20241222120000_fix_match_proposals_reference_error.sql
-- This migration fixes the error: relation "public.match_proposals" does not exist

-- 1. First, ensure all required types exist
CREATE TYPE public.match_proposal_status AS ENUM ('pending', 'accepted', 'rejected', 'matched');

-- 2. Create match_proposals table first (before any queries that reference it)
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

-- 4. Now safely clean up orphaned conversation records (after both tables exist)
DO $$
BEGIN
    -- Clean up orphaned conversation records that reference non-existent match_proposals
    DELETE FROM public.conversations 
    WHERE match_id IS NOT NULL 
    AND match_id NOT IN (SELECT id FROM public.match_proposals);
    
    -- Log the cleanup
    RAISE NOTICE 'Cleaned up orphaned conversation records';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup warning: %', SQLERRM;
END $$;

-- 5. Add foreign key constraint safely
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
        RAISE NOTICE 'Constraint creation warning: %', SQLERRM;
END $$;

-- 6. Create indexes for performance if they don't exist
CREATE INDEX IF NOT EXISTS idx_match_proposals_selector ON public.match_proposals(selector_id);
CREATE INDEX IF NOT EXISTS idx_match_proposals_candidate_1 ON public.match_proposals(candidate_1_id);
CREATE INDEX IF NOT EXISTS idx_match_proposals_candidate_2 ON public.match_proposals(candidate_2_id);
CREATE INDEX IF NOT EXISTS idx_match_proposals_final_status ON public.match_proposals(final_status);
CREATE INDEX IF NOT EXISTS idx_match_proposals_status_1 ON public.match_proposals(status_1);
CREATE INDEX IF NOT EXISTS idx_match_proposals_status_2 ON public.match_proposals(status_2);

CREATE INDEX IF NOT EXISTS idx_conversations_match_id ON public.conversations(match_id);
CREATE INDEX IF NOT EXISTS idx_conversations_participants ON public.conversations(participant_one_id, participant_two_id);

-- 7. Enable RLS if not already enabled
ALTER TABLE public.match_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- 8. Create helper functions for RLS policies
CREATE OR REPLACE FUNCTION public.can_access_proposal(proposal_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.match_proposals mp
    WHERE mp.id = proposal_uuid 
    AND (
        mp.selector_id = auth.uid() 
        OR mp.candidate_1_id = auth.uid() 
        OR mp.candidate_2_id = auth.uid()
        OR public.is_admin()
    )
)
$$;

CREATE OR REPLACE FUNCTION public.can_create_proposal()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() 
    AND (up.role = 'selector'::public.user_role OR up.role = 'admin'::public.user_role)
)
$$;

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

-- 9. Create or update RLS policies
-- Match proposals policies
DROP POLICY IF EXISTS "proposal_participants_access" ON public.match_proposals;
CREATE POLICY "proposal_participants_access"
ON public.match_proposals
FOR SELECT
TO authenticated
USING (public.can_access_proposal(id));

DROP POLICY IF EXISTS "selectors_create_proposals" ON public.match_proposals;
CREATE POLICY "selectors_create_proposals"
ON public.match_proposals
FOR INSERT
TO authenticated
WITH CHECK (
    public.can_create_proposal() 
    AND selector_id = auth.uid()
);

DROP POLICY IF EXISTS "candidates_update_status" ON public.match_proposals;
CREATE POLICY "candidates_update_status"
ON public.match_proposals
FOR UPDATE
TO authenticated
USING (
    candidate_1_id = auth.uid() 
    OR candidate_2_id = auth.uid() 
    OR selector_id = auth.uid()
    OR public.is_admin()
)
WITH CHECK (
    candidate_1_id = auth.uid() 
    OR candidate_2_id = auth.uid() 
    OR selector_id = auth.uid()
    OR public.is_admin()
);

-- Conversations policies
DROP POLICY IF EXISTS "conversation_participants_access" ON public.conversations;
CREATE POLICY "conversation_participants_access"
ON public.conversations
FOR ALL
TO authenticated
USING (public.can_access_conversation(id))
WITH CHECK (
    participant_one_id = auth.uid() 
    OR participant_two_id = auth.uid() 
    OR public.is_admin()
);

-- 10. Create trigger functions for match proposals
CREATE OR REPLACE FUNCTION public.update_proposal_final_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- If both candidates accept, set final status to matched
    IF NEW.status_1 = 'accepted'::public.match_proposal_status 
       AND NEW.status_2 = 'accepted'::public.match_proposal_status THEN
        NEW.final_status = 'matched'::public.match_proposal_status;
    -- If any candidate rejects, set final status to rejected
    ELSIF NEW.status_1 = 'rejected'::public.match_proposal_status 
          OR NEW.status_2 = 'rejected'::public.match_proposal_status THEN
        NEW.final_status = 'rejected'::public.match_proposal_status;
    -- Otherwise keep as pending
    ELSE
        NEW.final_status = 'pending'::public.match_proposal_status;
    END IF;
    
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_successful_match()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only create conversation if final status changed to matched
    IF OLD.final_status != 'matched'::public.match_proposal_status 
       AND NEW.final_status = 'matched'::public.match_proposal_status THEN
        
        -- Create conversation between the two candidates
        INSERT INTO public.conversations (
            match_id, 
            participant_one_id, 
            participant_two_id
        ) VALUES (
            NEW.id, 
            NEW.candidate_1_id, 
            NEW.candidate_2_id
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- 11. Create triggers
DROP TRIGGER IF EXISTS update_proposal_status_trigger ON public.match_proposals;
CREATE TRIGGER update_proposal_status_trigger
    BEFORE UPDATE ON public.match_proposals
    FOR EACH ROW EXECUTE FUNCTION public.update_proposal_final_status();

DROP TRIGGER IF EXISTS create_conversation_on_match_trigger ON public.match_proposals;
CREATE TRIGGER create_conversation_on_match_trigger
    AFTER UPDATE ON public.match_proposals
    FOR EACH ROW EXECUTE FUNCTION public.handle_successful_match();

-- 12. Create sample data if tables are empty
DO $$
DECLARE
    selector_uuid UUID;
    candidate1_uuid UUID;
    candidate2_uuid UUID;
    proposal_uuid UUID;
    proposal_count INTEGER;
BEGIN
    -- Check if we need to create sample data
    SELECT COUNT(*) INTO proposal_count FROM public.match_proposals;
    
    IF proposal_count = 0 THEN
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
                'pending'::public.match_proposal_status,
                'pending'::public.match_proposal_status,
                'pending'::public.match_proposal_status,
                'Sample proposal for database validation'
            ) RETURNING id INTO proposal_uuid;
            
            RAISE NOTICE 'Sample match proposal created successfully';
        END IF;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Sample data creation warning: %', SQLERRM;
END $$;

-- 13. Create data validation function
CREATE OR REPLACE FUNCTION public.validate_match_proposal_data()
RETURNS TABLE(
    total_proposals INTEGER,
    pending_proposals INTEGER,
    matched_proposals INTEGER,
    total_conversations INTEGER,
    orphaned_conversations INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(
            (SELECT COUNT(*)::INTEGER FROM public.match_proposals), 
            0
        ) as total_proposals,
        COALESCE(
            (SELECT COUNT(*)::INTEGER FROM public.match_proposals 
             WHERE final_status = 'pending'::public.match_proposal_status), 
            0
        ) as pending_proposals,
        COALESCE(
            (SELECT COUNT(*)::INTEGER FROM public.match_proposals 
             WHERE final_status = 'matched'::public.match_proposal_status), 
            0
        ) as matched_proposals,
        COALESCE(
            (SELECT COUNT(*)::INTEGER FROM public.conversations), 
            0
        ) as total_conversations,
        COALESCE(
            (SELECT COUNT(*)::INTEGER FROM public.conversations c 
             WHERE c.match_id IS NOT NULL 
             AND c.match_id NOT IN (SELECT id FROM public.match_proposals)), 
            0
        ) as orphaned_conversations;
END;
$$;

-- 14. Final validation and cleanup
DO $$
DECLARE
    validation_result RECORD;
BEGIN
    -- Run validation
    SELECT * INTO validation_result FROM public.validate_match_proposal_data();
    
    RAISE NOTICE 'Migration validation complete:';
    RAISE NOTICE 'Total proposals: %', validation_result.total_proposals;
    RAISE NOTICE 'Pending proposals: %', validation_result.pending_proposals;
    RAISE NOTICE 'Matched proposals: %', validation_result.matched_proposals;
    RAISE NOTICE 'Total conversations: %', validation_result.total_conversations;
    RAISE NOTICE 'Orphaned conversations: %', validation_result.orphaned_conversations;
    
    -- Clean up any remaining orphaned data
    IF validation_result.orphaned_conversations > 0 THEN
        DELETE FROM public.conversations 
        WHERE match_id IS NOT NULL 
        AND match_id NOT IN (SELECT id FROM public.match_proposals);
        
        RAISE NOTICE 'Cleaned up % orphaned conversations', validation_result.orphaned_conversations;
    END IF;
    
END $$;

-- 15. Create utility function for application debugging
CREATE OR REPLACE FUNCTION public.debug_match_proposal_system()
RETURNS TABLE(
    table_name TEXT,
    exists_status BOOLEAN,
    row_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'match_proposals'::TEXT as table_name,
        EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'match_proposals') as exists_status,
        COALESCE((SELECT COUNT(*)::INTEGER FROM public.match_proposals), 0) as row_count
    UNION ALL
    SELECT 
        'conversations'::TEXT as table_name,
        EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'conversations') as exists_status,
        COALESCE((SELECT COUNT(*)::INTEGER FROM public.conversations), 0) as row_count
    UNION ALL
    SELECT 
        'user_profiles'::TEXT as table_name,
        EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles') as exists_status,
        COALESCE((SELECT COUNT(*)::INTEGER FROM public.user_profiles), 0) as row_count;
END;
$$;

-- Final success message
DO $$
BEGIN
    RAISE NOTICE 'Migration 20241222120000_fix_match_proposals_reference_error completed successfully';
    RAISE NOTICE 'The match_proposals table now exists and foreign key constraints are properly established';
END $$;