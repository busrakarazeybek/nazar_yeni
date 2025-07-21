-- Enhanced Match Proposal System for Görücü App
-- Location: supabase/migrations/20241217120000_enhanced_match_proposal_system.sql

-- MATCH_PROPOSALS TABLOSU VE İLGİLİ TÜM TANIMLAR YORUM SATIRINA ALINDI
-- 1. Add enhanced match proposal types
-- CREATE TYPE public.match_proposal_status AS ENUM ('pending', 'accepted', 'rejected', 'matched');

-- 2. Create enhanced match proposals table with dual candidate support
-- CREATE TABLE public.match_proposals (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     selector_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
--     candidate_1_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
--     candidate_2_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
--     status_1 public.match_proposal_status DEFAULT 'pending'::public.match_proposal_status,
--     status_2 public.match_proposal_status DEFAULT 'pending'::public.match_proposal_status,
--     final_status public.match_proposal_status DEFAULT 'pending'::public.match_proposal_status,
--     selector_message TEXT,
--     created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
--     CONSTRAINT different_candidates CHECK (candidate_1_id != candidate_2_id)
-- );

-- 3. Create indexes for performance
-- CREATE INDEX idx_match_proposals_selector ON public.match_proposals(selector_id);
-- CREATE INDEX idx_match_proposals_candidate_1 ON public.match_proposals(candidate_1_id);
-- CREATE INDEX idx_match_proposals_candidate_2 ON public.match_proposals(candidate_2_id);
-- CREATE INDEX idx_match_proposals_final_status ON public.match_proposals(final_status);
-- CREATE INDEX idx_match_proposals_status_1 ON public.match_proposals(status_1);
-- CREATE INDEX idx_match_proposals_status_2 ON public.match_proposals(status_2);

-- 4. Enable RLS
-- ALTER TABLE public.match_proposals ENABLE ROW LEVEL SECURITY;

-- 5. Create helper functions for RLS policies
-- CREATE OR REPLACE FUNCTION public.can_access_proposal(proposal_uuid UUID)
-- RETURNS BOOLEAN
-- LANGUAGE sql
-- STABLE
-- SECURITY DEFINER
-- AS $$
-- SELECT EXISTS (
--     SELECT 1 FROM public.match_proposals mp
--     WHERE mp.id = proposal_uuid 
--     AND (
--         mp.selector_id = auth.uid() 
--         OR mp.candidate_1_id = auth.uid() 
--         OR mp.candidate_2_id = auth.uid()
--         OR public.is_admin()
--     )
-- )
-- $$;

-- CREATE OR REPLACE FUNCTION public.can_create_proposal()
-- RETURNS BOOLEAN
-- LANGUAGE sql
-- STABLE
-- SECURITY DEFINER
-- AS $$
-- SELECT EXISTS (
--     SELECT 1 FROM public.user_profiles up
--     WHERE up.id = auth.uid() 
--     AND (up.role = 'selector'::public.user_role OR up.role = 'admin'::public.user_role)
-- )
-- $$;

-- 6. Create RLS policies for match proposals
-- CREATE POLICY "proposal_participants_access"
-- ON public.match_proposals
-- FOR SELECT
-- TO authenticated
-- USING (public.can_access_proposal(id));

-- CREATE POLICY "selectors_create_proposals"
-- ON public.match_proposals
-- FOR INSERT
-- TO authenticated
-- WITH CHECK (
--     public.can_create_proposal() 
--     AND selector_id = auth.uid()
-- );

-- CREATE POLICY "candidates_update_status"
-- ON public.match_proposals
-- FOR UPDATE
-- TO authenticated
-- USING (
--     candidate_1_id = auth.uid() 
--     OR candidate_2_id = auth.uid() 
--     OR selector_id = auth.uid()
--     OR public.is_admin()
-- )
-- WITH CHECK (
--     candidate_1_id = auth.uid() 
--     OR candidate_2_id = auth.uid() 
--     OR selector_id = auth.uid()
--     OR public.is_admin()
-- );

-- 7. Create function to automatically update final status
-- CREATE OR REPLACE FUNCTION public.update_proposal_final_status()
-- RETURNS TRIGGER
-- LANGUAGE plpgsql
-- SECURITY DEFINER
-- AS $$
-- BEGIN
--     -- If both candidates accept, set final status to matched
--     IF NEW.status_1 = 'accepted'::public.match_proposal_status 
--        AND NEW.status_2 = 'accepted'::public.match_proposal_status THEN
--         NEW.final_status = 'matched'::public.match_proposal_status;
--     -- If any candidate rejects, set final status to rejected
--     ELSIF NEW.status_1 = 'rejected'::public.match_proposal_status 
--           OR NEW.status_2 = 'rejected'::public.match_proposal_status THEN
--         NEW.final_status = 'rejected'::public.match_proposal_status;
--     -- Otherwise keep as pending
--     ELSE
--         NEW.final_status = 'pending'::public.match_proposal_status;
--     END IF;
    
--     NEW.updated_at = CURRENT_TIMESTAMP;
--     RETURN NEW;
-- END;
-- $$;

-- 8. Create trigger for automatic final status update
-- CREATE TRIGGER update_proposal_status_trigger
--     BEFORE UPDATE ON public.match_proposals
--     FOR EACH ROW EXECUTE FUNCTION public.update_proposal_final_status();

-- 9. Create trigger for updated_at
-- CREATE TRIGGER update_match_proposals_updated_at
--     BEFORE UPDATE ON public.match_proposals
--     FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 10. Create function to create conversations when matched
-- CREATE OR REPLACE FUNCTION public.handle_successful_match()
-- RETURNS TRIGGER
-- LANGUAGE plpgsql
-- SECURITY DEFINER
-- AS $$
-- BEGIN
--     -- Only create conversation if final status changed to matched
--     IF OLD.final_status != 'matched'::public.match_proposal_status 
--        AND NEW.final_status = 'matched'::public.match_proposal_status THEN
        
--         -- Create conversation between the two candidates
--         INSERT INTO public.conversations (
--             match_id, 
--             participant_one_id, 
--             participant_two_id
--         ) VALUES (
--             NEW.id::text::UUID, 
--             NEW.candidate_1_id, 
--             NEW.candidate_2_id
--         );
--     END IF;
    
--     RETURN NEW;
-- END;
-- $$;

-- 11. Create trigger for automatic conversation creation
-- CREATE TRIGGER create_conversation_on_match_trigger
--     AFTER UPDATE ON public.match_proposals
--     FOR EACH ROW EXECUTE FUNCTION public.handle_successful_match();

-- 12. Create mock data for enhanced system
DO $$
DECLARE
    selector_uuid UUID;
    candidate1_uuid UUID;
    candidate2_uuid UUID;
    candidate3_uuid UUID;
    proposal1_uuid UUID := gen_random_uuid();
    proposal2_uuid UUID := gen_random_uuid();
BEGIN
    -- Get existing user IDs
    SELECT id INTO selector_uuid FROM public.user_profiles WHERE role = 'selector'::public.user_role LIMIT 1;
    SELECT id INTO candidate1_uuid FROM public.user_profiles WHERE role = 'candidate'::public.user_role AND full_name = 'Ayşe Demir';
    SELECT id INTO candidate2_uuid FROM public.user_profiles WHERE role = 'candidate'::public.user_role AND full_name = 'Zeynep Kaya';
    SELECT id INTO candidate3_uuid FROM public.user_profiles WHERE role = 'candidate'::public.user_role AND full_name = 'Elif Özkan';

    -- Create sample match proposals
    IF selector_uuid IS NOT NULL AND candidate1_uuid IS NOT NULL AND candidate2_uuid IS NOT NULL THEN
        INSERT INTO public.match_proposals (
            id, selector_id, candidate_1_id, candidate_2_id, 
            status_1, status_2, final_status, selector_message
        ) VALUES 
            (proposal1_uuid, selector_uuid, candidate1_uuid, candidate2_uuid, 
             'pending'::public.match_proposal_status, 'pending'::public.match_proposal_status, 
             'pending'::public.match_proposal_status, 'İkiniz birbiriniz için çok uygun görünüyorsunuz. Tanışmanızı öneriyorum.'),
            (proposal2_uuid, selector_uuid, candidate2_uuid, candidate3_uuid, 
             'accepted'::public.match_proposal_status, 'pending'::public.match_proposal_status, 
             'pending'::public.match_proposal_status, 'Ortak ilgi alanlarınız var, tanışmanızı tavsiye ederim.');
    END IF;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error in mock data: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error in mock data: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error in mock data: %', SQLERRM;
END $$;

-- 13. Create cleanup function for enhanced system
CREATE OR REPLACE FUNCTION public.cleanup_enhanced_match_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Delete in dependency order
    DELETE FROM public.conversations WHERE match_id IN (
        SELECT id::text::UUID FROM public.match_proposals
    );
    DELETE FROM public.match_proposals;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;