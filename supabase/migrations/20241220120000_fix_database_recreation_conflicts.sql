-- Fix Database Recreation Conflicts
-- Location: supabase/migrations/20241220120000_fix_database_recreation_conflicts.sql
-- This migration fixes the conflicts from the previous complete recreation migration

-- 1. Create custom types only if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE public.user_role AS ENUM ('candidate', 'selector', 'admin');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'gender_type') THEN
        CREATE TYPE public.gender_type AS ENUM ('male', 'female', 'other', 'prefer_not_to_say');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'match_status') THEN
        CREATE TYPE public.match_status AS ENUM ('pending', 'accepted', 'rejected');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'match_proposal_status') THEN
        CREATE TYPE public.match_proposal_status AS ENUM ('pending', 'accepted', 'rejected', 'matched');
    END IF;
END $$;

-- 2. Create missing columns and tables that don't exist
DO $$
BEGIN
    -- Add missing columns to user_profiles if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'age') THEN
        ALTER TABLE public.user_profiles ADD COLUMN age INTEGER CHECK (age >= 18 AND age <= 100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'gender') THEN
        ALTER TABLE public.user_profiles ADD COLUMN gender public.gender_type;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'bio') THEN
        ALTER TABLE public.user_profiles ADD COLUMN bio TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'interests') THEN
        ALTER TABLE public.user_profiles ADD COLUMN interests TEXT[];
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'location') THEN
        ALTER TABLE public.user_profiles ADD COLUMN location TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'profession') THEN
        ALTER TABLE public.user_profiles ADD COLUMN profession TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'image_url') THEN
        ALTER TABLE public.user_profiles ADD COLUMN image_url TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'phone') THEN
        ALTER TABLE public.user_profiles ADD COLUMN phone TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'is_active') THEN
        ALTER TABLE public.user_profiles ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'is_verified') THEN
        ALTER TABLE public.user_profiles ADD COLUMN is_verified BOOLEAN DEFAULT false;
    END IF;
END $$;

-- 3. Create match_proposals table if it doesn't exist
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

-- 4. Update conversations table to reference match_proposals if needed
DO $$
BEGIN
    -- Check if conversations table references matches or match_proposals
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'conversations' AND column_name = 'match_id') THEN
        -- Check if it references matches table
        IF EXISTS (SELECT 1 FROM information_schema.table_constraints tc
                   JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
                   WHERE tc.table_name = 'conversations' AND kcu.column_name = 'match_id'
                   AND tc.constraint_type = 'FOREIGN KEY') THEN
            -- Drop and recreate constraint to reference match_proposals
            ALTER TABLE public.conversations DROP CONSTRAINT IF EXISTS conversations_match_id_fkey;
            ALTER TABLE public.conversations ADD CONSTRAINT conversations_match_id_fkey 
                FOREIGN KEY (match_id) REFERENCES public.match_proposals(id) ON DELETE CASCADE;
        END IF;
    END IF;
END $$;

-- 5. Create additional indexes for new tables if they don't exist
CREATE INDEX IF NOT EXISTS idx_user_profiles_age ON public.user_profiles(age);
CREATE INDEX IF NOT EXISTS idx_user_profiles_gender ON public.user_profiles(gender);
CREATE INDEX IF NOT EXISTS idx_match_proposals_selector ON public.match_proposals(selector_id);
CREATE INDEX IF NOT EXISTS idx_match_proposals_candidate_1 ON public.match_proposals(candidate_1_id);
CREATE INDEX IF NOT EXISTS idx_match_proposals_candidate_2 ON public.match_proposals(candidate_2_id);
CREATE INDEX IF NOT EXISTS idx_match_proposals_final_status ON public.match_proposals(final_status);
CREATE INDEX IF NOT EXISTS idx_match_proposals_status_1 ON public.match_proposals(status_1);
CREATE INDEX IF NOT EXISTS idx_match_proposals_status_2 ON public.match_proposals(status_2);

-- 6. Enable RLS for match_proposals table
ALTER TABLE public.match_proposals ENABLE ROW LEVEL SECURITY;

-- 7. Create missing helper functions
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

-- 8. Create missing RLS policies for match_proposals
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

-- 9. Create missing trigger functions
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

-- 10. Create missing triggers
DROP TRIGGER IF EXISTS update_proposal_status_trigger ON public.match_proposals;
CREATE TRIGGER update_proposal_status_trigger
    BEFORE UPDATE ON public.match_proposals
    FOR EACH ROW EXECUTE FUNCTION public.update_proposal_final_status();

DROP TRIGGER IF EXISTS update_match_proposals_updated_at ON public.match_proposals;
CREATE TRIGGER update_match_proposals_updated_at
    BEFORE UPDATE ON public.match_proposals
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS create_conversation_on_match_trigger ON public.match_proposals;
CREATE TRIGGER create_conversation_on_match_trigger
    AFTER UPDATE ON public.match_proposals
    FOR EACH ROW EXECUTE FUNCTION public.handle_successful_match();

-- 11. Create missing utility functions
CREATE OR REPLACE FUNCTION public.get_user_stats(user_uuid UUID)
RETURNS TABLE(
    total_proposals INTEGER,
    accepted_proposals INTEGER,
    matched_proposals INTEGER,
    total_conversations INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(
            (SELECT COUNT(*)::INTEGER FROM public.match_proposals mp 
             WHERE mp.selector_id = user_uuid OR mp.candidate_1_id = user_uuid OR mp.candidate_2_id = user_uuid), 
            0
        ) as total_proposals,
        COALESCE(
            (SELECT COUNT(*)::INTEGER FROM public.match_proposals mp 
             WHERE (mp.candidate_1_id = user_uuid AND mp.status_1 = 'accepted'::public.match_proposal_status) 
                OR (mp.candidate_2_id = user_uuid AND mp.status_2 = 'accepted'::public.match_proposal_status)), 
            0
        ) as accepted_proposals,
        COALESCE(
            (SELECT COUNT(*)::INTEGER FROM public.match_proposals mp 
             WHERE mp.final_status = 'matched'::public.match_proposal_status 
               AND (mp.candidate_1_id = user_uuid OR mp.candidate_2_id = user_uuid)), 
            0
        ) as matched_proposals,
        COALESCE(
            (SELECT COUNT(*)::INTEGER FROM public.conversations c 
             WHERE c.participant_one_id = user_uuid OR c.participant_two_id = user_uuid), 
            0
        ) as total_conversations;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_candidates_for_selector(selector_uuid UUID)
RETURNS TABLE(
    id UUID,
    full_name TEXT,
    age INTEGER,
    profession TEXT,
    location TEXT,
    bio TEXT,
    interests TEXT[],
    image_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        up.id,
        up.full_name,
        up.age,
        up.profession,
        up.location,
        up.bio,
        up.interests,
        up.image_url
    FROM public.user_profiles up
    WHERE up.role = 'candidate'::public.user_role
      AND up.is_active = true
      AND up.is_verified = true
      AND NOT EXISTS (
          SELECT 1 FROM public.selector_candidates sc
          WHERE sc.selector_id = selector_uuid AND sc.candidate_id = up.id
      )
    ORDER BY up.created_at DESC;
END;
$$;

-- 12. Update cleanup function to handle new tables
CREATE OR REPLACE FUNCTION public.cleanup_all_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    auth_user_ids_to_delete UUID[];
BEGIN
    -- Get auth user IDs first
    SELECT ARRAY_AGG(id) INTO auth_user_ids_to_delete
    FROM auth.users
    WHERE email LIKE '%@goricu.com';

    -- Delete in dependency order (children first)
    DELETE FROM public.messages WHERE sender_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.conversations WHERE participant_one_id = ANY(auth_user_ids_to_delete) OR participant_two_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.match_proposals WHERE selector_id = ANY(auth_user_ids_to_delete) OR candidate_1_id = ANY(auth_user_ids_to_delete) OR candidate_2_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.matches WHERE selector_id = ANY(auth_user_ids_to_delete) OR candidate_id = ANY(auth_user_ids_to_delete) OR target_candidate_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.selector_candidates WHERE selector_id = ANY(auth_user_ids_to_delete) OR candidate_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.user_profiles WHERE id = ANY(auth_user_ids_to_delete);

    -- Delete auth.users last
    DELETE FROM auth.users WHERE id = ANY(auth_user_ids_to_delete);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;

-- 13. Add sample data for match_proposals if table is empty
DO $$
DECLARE
    selector1_uuid UUID;
    candidate1_uuid UUID;
    candidate2_uuid UUID;
    candidate3_uuid UUID;
    candidate4_uuid UUID;
    proposal_count INTEGER;
BEGIN
    -- Check if match_proposals table has data
    SELECT COUNT(*) INTO proposal_count FROM public.match_proposals;
    
    IF proposal_count = 0 THEN
        -- Get existing user IDs
        SELECT id INTO selector1_uuid FROM public.user_profiles WHERE email = 'selector@goricu.com';
        SELECT id INTO candidate1_uuid FROM public.user_profiles WHERE email = 'candidate@goricu.com';
        SELECT id INTO candidate2_uuid FROM public.user_profiles WHERE email = 'zeynep.kaya@goricu.com';
        SELECT id INTO candidate3_uuid FROM public.user_profiles WHERE email = 'elif.ozkan@goricu.com';
        SELECT id INTO candidate4_uuid FROM public.user_profiles WHERE email = 'fatma.yilmaz@goricu.com';
        
        -- Create sample match proposals if users exist
        IF selector1_uuid IS NOT NULL AND candidate1_uuid IS NOT NULL AND candidate2_uuid IS NOT NULL THEN
            INSERT INTO public.match_proposals (
                selector_id, candidate_1_id, candidate_2_id, 
                status_1, status_2, final_status, selector_message
            ) VALUES 
                (selector1_uuid, candidate1_uuid, candidate2_uuid, 
                 'pending'::public.match_proposal_status, 'pending'::public.match_proposal_status, 
                 'pending'::public.match_proposal_status, 'İkiniz birbiriniz için çok uygun görünüyorsunuz. Tanışmanızı öneriyorum.');
                 
            IF candidate3_uuid IS NOT NULL AND candidate4_uuid IS NOT NULL THEN
                INSERT INTO public.match_proposals (
                    selector_id, candidate_1_id, candidate_2_id, 
                    status_1, status_2, final_status, selector_message
                ) VALUES 
                    (selector1_uuid, candidate3_uuid, candidate4_uuid, 
                     'accepted'::public.match_proposal_status, 'accepted'::public.match_proposal_status, 
                     'matched'::public.match_proposal_status, 'Mükemmel bir eşleşme! İkiniz birbirinize çok uygun.');
            END IF;
        END IF;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Sample data creation failed: %', SQLERRM;
END $$;