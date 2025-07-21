-- Complete Görücü Matchmaker Database Recreation
-- Location: supabase/migrations/20241219120000_complete_goricu_database_recreation.sql
-- This migration recreates all necessary tables after database deletion

-- 1. Create custom types for the application
CREATE TYPE public.user_role AS ENUM ('candidate', 'selector', 'admin');
CREATE TYPE public.gender_type AS ENUM ('male', 'female', 'other', 'prefer_not_to_say');
CREATE TYPE public.match_status AS ENUM ('pending', 'accepted', 'rejected');
CREATE TYPE public.match_proposal_status AS ENUM ('pending', 'accepted', 'rejected', 'matched');

-- 2. Create user_profiles table (intermediary for auth.users)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role public.user_role DEFAULT 'candidate'::public.user_role,
    age INTEGER CHECK (age >= 18 AND age <= 100),
    gender public.gender_type,
    bio TEXT,
    interests TEXT[],
    location TEXT,
    profession TEXT,
    image_url TEXT,
    phone TEXT,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create selector-candidate relationships table
CREATE TABLE public.selector_candidates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    selector_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    candidate_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(selector_id, candidate_id)
);

-- 4. Create matches table for basic matchmaking functionality
CREATE TABLE public.matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    selector_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    candidate_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    target_candidate_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    status public.match_status DEFAULT 'pending'::public.match_status,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Create enhanced match proposals table with dual candidate support
CREATE TABLE public.match_proposals (
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

-- 6. Create conversations table for messaging
CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID REFERENCES public.match_proposals(id) ON DELETE CASCADE,
    participant_one_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    participant_two_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    last_message_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 7. Create messages table
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 8. Create essential indexes for performance
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_location ON public.user_profiles(location);
CREATE INDEX idx_user_profiles_age ON public.user_profiles(age);
CREATE INDEX idx_user_profiles_gender ON public.user_profiles(gender);

CREATE INDEX idx_selector_candidates_selector ON public.selector_candidates(selector_id);
CREATE INDEX idx_selector_candidates_candidate ON public.selector_candidates(candidate_id);

CREATE INDEX idx_matches_selector ON public.matches(selector_id);
CREATE INDEX idx_matches_candidate ON public.matches(candidate_id);
CREATE INDEX idx_matches_target ON public.matches(target_candidate_id);
CREATE INDEX idx_matches_status ON public.matches(status);

CREATE INDEX idx_match_proposals_selector ON public.match_proposals(selector_id);
CREATE INDEX idx_match_proposals_candidate_1 ON public.match_proposals(candidate_1_id);
CREATE INDEX idx_match_proposals_candidate_2 ON public.match_proposals(candidate_2_id);
CREATE INDEX idx_match_proposals_final_status ON public.match_proposals(final_status);
CREATE INDEX idx_match_proposals_status_1 ON public.match_proposals(status_1);
CREATE INDEX idx_match_proposals_status_2 ON public.match_proposals(status_2);

CREATE INDEX idx_conversations_participants ON public.conversations(participant_one_id, participant_two_id);
CREATE INDEX idx_conversations_match ON public.conversations(match_id);

CREATE INDEX idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX idx_messages_sender ON public.messages(sender_id);
CREATE INDEX idx_messages_created_at ON public.messages(created_at);

-- 9. Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.selector_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 10. Create helper functions for RLS policies
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() AND up.role = 'admin'::public.user_role
)
$$;

CREATE OR REPLACE FUNCTION public.is_selector()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() AND up.role = 'selector'::public.user_role
)
$$;

CREATE OR REPLACE FUNCTION public.is_candidate()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() AND up.role = 'candidate'::public.user_role
)
$$;

CREATE OR REPLACE FUNCTION public.can_view_candidate_profile(candidate_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() 
    AND (
        up.role = 'selector'::public.user_role 
        OR up.role = 'admin'::public.user_role
        OR up.id = candidate_uuid
    )
)
$$;

CREATE OR REPLACE FUNCTION public.can_access_match(match_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.matches m
    WHERE m.id = match_uuid 
    AND (
        m.selector_id = auth.uid() 
        OR m.candidate_id = auth.uid() 
        OR m.target_candidate_id = auth.uid()
        OR public.is_admin()
    )
)
$$;

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

-- 11. Create RLS policies
-- User profiles policies
CREATE POLICY "users_own_profile"
ON public.user_profiles
FOR ALL
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "selectors_view_candidates"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (
    auth.uid() = id 
    OR public.can_view_candidate_profile(id)
);

-- Selector-candidate relationships policies
CREATE POLICY "selectors_manage_candidates"
ON public.selector_candidates
FOR ALL
TO authenticated
USING (
    selector_id = auth.uid() 
    OR candidate_id = auth.uid() 
    OR public.is_admin()
)
WITH CHECK (
    selector_id = auth.uid() 
    OR public.is_admin()
);

-- Matches policies
CREATE POLICY "match_participants_access"
ON public.matches
FOR ALL
TO authenticated
USING (public.can_access_match(id))
WITH CHECK (
    selector_id = auth.uid() 
    OR public.is_admin()
);

-- Match proposals policies
CREATE POLICY "proposal_participants_access"
ON public.match_proposals
FOR SELECT
TO authenticated
USING (public.can_access_proposal(id));

CREATE POLICY "selectors_create_proposals"
ON public.match_proposals
FOR INSERT
TO authenticated
WITH CHECK (
    public.can_create_proposal() 
    AND selector_id = auth.uid()
);

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

-- Messages policies
CREATE POLICY "message_participants_access"
ON public.messages
FOR ALL
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
    OR public.is_admin()
);

-- 12. Create trigger functions
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, role)
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'candidate')::public.user_role
    );
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

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

-- 13. Create triggers
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_matches_updated_at
    BEFORE UPDATE ON public.matches
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_proposal_status_trigger
    BEFORE UPDATE ON public.match_proposals
    FOR EACH ROW EXECUTE FUNCTION public.update_proposal_final_status();

CREATE TRIGGER update_match_proposals_updated_at
    BEFORE UPDATE ON public.match_proposals
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER create_conversation_on_match_trigger
    AFTER UPDATE ON public.match_proposals
    FOR EACH ROW EXECUTE FUNCTION public.handle_successful_match();

-- 14. Create comprehensive mock data
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    selector1_uuid UUID := gen_random_uuid();
    selector2_uuid UUID := gen_random_uuid();
    selector3_uuid UUID := gen_random_uuid();
    selector4_uuid UUID := gen_random_uuid();
    candidate1_uuid UUID := gen_random_uuid();
    candidate2_uuid UUID := gen_random_uuid();
    candidate3_uuid UUID := gen_random_uuid();
    candidate4_uuid UUID := gen_random_uuid();
    candidate5_uuid UUID := gen_random_uuid();
    candidate6_uuid UUID := gen_random_uuid();
    candidate7_uuid UUID := gen_random_uuid();
    candidate8_uuid UUID := gen_random_uuid();
    candidate9_uuid UUID := gen_random_uuid();
    candidate10_uuid UUID := gen_random_uuid();
    candidate11_uuid UUID := gen_random_uuid();
    candidate12_uuid UUID := gen_random_uuid();
    candidate13_uuid UUID := gen_random_uuid();
    candidate14_uuid UUID := gen_random_uuid();
    candidate15_uuid UUID := gen_random_uuid();
    proposal1_uuid UUID := gen_random_uuid();
    proposal2_uuid UUID := gen_random_uuid();
    proposal3_uuid UUID := gen_random_uuid();
    conversation1_uuid UUID := gen_random_uuid();
BEGIN
    -- Create auth users with complete field structure
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@goricu.com', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (selector1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'selector@goricu.com', crypt('selector123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Ahmet Seçici", "role": "selector"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (selector2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'meryem.secici@goricu.com', crypt('selector123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Meryem Seçici", "role": "selector"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (selector3_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'hasan.secici@goricu.com', crypt('selector123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Hasan Seçici", "role": "selector"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (selector4_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'fatma.secici@goricu.com', crypt('selector123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Fatma Seçici", "role": "selector"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'candidate@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Ayşe Demir", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'zeynep.kaya@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Zeynep Kaya", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate3_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'elif.ozkan@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Elif Özkan", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate4_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'fatma.yilmaz@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Fatma Yılmaz", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate5_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'merve.sahin@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Merve Şahin", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate6_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'sema.aksoy@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Sema Aksoy", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate7_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'busra.celik@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Büşra Çelik", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate8_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'dilan.yildirim@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Dilan Yıldırım", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate9_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'melisa.turkmen@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Melisa Türkmen", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate10_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'nazli.koc@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Nazlı Koç", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate11_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'simge.dogan@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Simge Doğan", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate12_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'tugba.arslan@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Tuğba Arslan", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate13_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'ece.polat@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Ece Polat", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate14_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'gizem.kurt@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Gizem Kurt", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (candidate15_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'asli.ozdemir@goricu.com', crypt('candidate123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Aslı Özdemir", "role": "candidate"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Update user profiles with detailed information
    UPDATE public.user_profiles SET
        age = 26,
        gender = 'female'::public.gender_type,
        bio = 'Kitap okumayı ve doğa yürüyüşlerini seven, pozitif enerjili bir öğretmenim. Hayatımda anlamlı bağlantılar kurmayı hedefliyorum.',
        interests = ARRAY['Kitap', 'Doğa', 'Yoga', 'Müzik', 'Seyahat'],
        location = 'İstanbul',
        profession = 'Öğretmen',
        image_url = 'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
        is_verified = true
    WHERE id = candidate1_uuid;

    UPDATE public.user_profiles SET
        age = 24,
        gender = 'female'::public.gender_type,
        bio = 'Sanat ve tasarımla ilgilenen, yaratıcı projeler geliştiren bir grafik tasarımcısıyım. Hayalperest ve samimi biriyim.',
        interests = ARRAY['Sanat', 'Tasarım', 'Fotoğraf', 'Kahve', 'Sinema'],
        location = 'Ankara',
        profession = 'Grafik Tasarımcı',
        image_url = 'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
        is_verified = true
    WHERE id = candidate2_uuid;

    UPDATE public.user_profiles SET
        age = 28,
        gender = 'female'::public.gender_type,
        bio = 'Mutfakta deneyimler yapmayı seven, arkadaşlarıyla kaliteli zaman geçiren bir pazarlama uzmanıyım.',
        interests = ARRAY['Yemek', 'Arkadaşlık', 'Spor', 'Teknoloji', 'Gezi'],
        location = 'İzmir',
        profession = 'Pazarlama Uzmanı',
        image_url = 'https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
        is_verified = true
    WHERE id = candidate3_uuid;

    UPDATE public.user_profiles SET
        age = 25,
        gender = 'female'::public.gender_type,
        bio = 'Doktor olmak için çalışan, insanlara yardım etmeyi seven, empati dolu bir tıp öğrencisiyim.',
        interests = ARRAY['Tıp', 'Gönüllülük', 'Okuma', 'Klasik Müzik', 'Bahçıvanlık'],
        location = 'Bursa',
        profession = 'Tıp Öğrencisi',
        image_url = 'https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
        is_verified = true
    WHERE id = candidate4_uuid;

    UPDATE public.user_profiles SET
        age = 27,
        gender = 'female'::public.gender_type,
        bio = 'Teknoloji dünyasında kendini geliştiren, problem çözmeyi seven bir yazılım geliştiricisiyim.',
        interests = ARRAY['Teknoloji', 'Kodlama', 'Oyun', 'Bilim', 'Podcast'],
        location = 'İstanbul',
        profession = 'Yazılım Geliştirici',
        image_url = 'https://images.pexels.com/photos/1181424/pexels-photo-1181424.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
        is_verified = true
    WHERE id = candidate5_uuid;

    UPDATE public.user_profiles SET
        age = 29,
        gender = 'female'::public.gender_type,
        bio = 'Mühendislik alanında çalışan, analitik düşünmeyi seven ve teknolojiye meraklı bir endüstri mühendisiyim.',
        interests = ARRAY['Mühendislik', 'Teknoloji', 'Analitik', 'Proje Yönetimi', 'İnovasyon'],
        location = 'İstanbul',
        profession = 'Endüstri Mühendisi',
        image_url = 'https://images.pexels.com/photos/1065084/pexels-photo-1065084.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
        is_verified = true
    WHERE id = candidate6_uuid;

    UPDATE public.user_profiles SET
        age = 26,
        gender = 'female'::public.gender_type,
        bio = 'Çocukların geleceğini şekillendirmeyi seven, sabırlı ve anlayışlı bir okul öncesi öğretmeniyim.',
        interests = ARRAY['Eğitim', 'Çocuk Gelişimi', 'Oyun', 'Hikaye', 'Müzik'],
        location = 'Ankara',
        profession = 'Okul Öncesi Öğretmeni',
        image_url = 'https://images.pexels.com/photos/1310522/pexels-photo-1310522.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
        is_verified = true
    WHERE id = candidate7_uuid;

    UPDATE public.user_profiles SET
        age = 24,
        gender = 'female'::public.gender_type,
        bio = 'İletişim fakültesi mezunu, medya ve içerik üretimi konularında deneyimli genç bir profesyonelim.',
        interests = ARRAY['Medya', 'İçerik Üretimi', 'Sosyal Medya', 'Yazı', 'Kreatif'],
        location = 'İzmir',
        profession = 'İletişim Uzmanı',
        image_url = 'https://images.pexels.com/photos/1542085/pexels-photo-1542085.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
        is_verified = true
    WHERE id = candidate8_uuid;

    UPDATE public.user_profiles SET
        age = 27,
        gender = 'female'::public.gender_type,
        bio = 'Halkla ilişkiler alanında uzmanlaşmış, organizasyon yetenekleri güçlü ve sosyal bir kişiyim.',
        interests = ARRAY['Halkla İlişkiler', 'Organizasyon', 'Sosyalleşme', 'Etkinlik', 'Network'],
        location = 'Bursa',
        profession = 'Halkla İlişkiler Uzmanı',
        image_url = 'https://images.pexels.com/photos/762020/pexels-photo-762020.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
        is_verified = true
    WHERE id = candidate9_uuid;

    UPDATE public.user_profiles SET
        age = 25,
        gender = 'female'::public.gender_type,
        bio = 'Fizyoterapist olarak insanların sağlığına katkıda bulunmayı seven, empatik ve yardımsever biriyim.',
        interests = ARRAY['Sağlık', 'Rehabilitasyon', 'Spor', 'Wellness', 'Yardım'],
        location = 'Antalya',
        profession = 'Fizyoterapist',
        image_url = 'https://images.pexels.com/photos/1559486/pexels-photo-1559486.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
        is_verified = true
    WHERE id = candidate10_uuid;

    UPDATE public.user_profiles SET
        age = 28,
        gender = 'female'::public.gender_type,
        bio = 'Muhasebe ve finans alanında uzman, detaycı ve sistematik çalışmayı seven bir profesyonelim.',
        interests = ARRAY['Finans', 'Muhasebe', 'Analiz', 'Planlama', 'Sistem'],
        location = 'Konya',
        profession = 'Mali Müşavir',
        image_url = 'https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
        is_verified = true
    WHERE id = candidate11_uuid;

    UPDATE public.user_profiles SET
        age = 26,
        gender = 'female'::public.gender_type,
        bio = 'İnsan kaynakları alanında çalışan, insanlarla iletişim kurmayı seven ve çözüm odaklı biriyim.',
        interests = ARRAY['İK', 'İnsan İlişkileri', 'Coaching', 'Gelişim', 'İletişim'],
        location = 'Adana',
        profession = 'İnsan Kaynakları Uzmanı',
        image_url = 'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
        is_verified = true
    WHERE id = candidate12_uuid;

    UPDATE public.user_profiles SET
        age = 24,
        gender = 'female'::public.gender_type,
        bio = 'Mimarlık okuyarak yaratıcılığımı geliştiren, estetik ve fonksiyonelliği harmanlayan bir öğrenciyim.',
        interests = ARRAY['Mimarlık', 'Tasarım', 'Estetik', 'Yaratıcılık', 'Çizim'],
        location = 'Eskişehir',
        profession = 'Mimarlık Öğrencisi',
        image_url = 'https://images.pixabay.com/photo/2017/05/30/03/58/business-2355684_1280.jpg',
        is_verified = true
    WHERE id = candidate13_uuid;

    UPDATE public.user_profiles SET
        age = 27,
        gender = 'female'::public.gender_type,
        bio = 'Veteriner hekim olarak hayvanları sevmeyi ve onlara yardım etmeyi kendime misyon edindim.',
        interests = ARRAY['Veterinerlik', 'Hayvan Sevgisi', 'Doğa', 'Şifa', 'Empati'],
        location = 'Trabzon',
        profession = 'Veteriner Hekim',
        image_url = 'https://images.unsplash.com/photo-1494790108755-2616b6b44516?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1887&q=80',
        is_verified = true
    WHERE id = candidate14_uuid;

    UPDATE public.user_profiles SET
        age = 25,
        gender = 'female'::public.gender_type,
        bio = 'Eczacılık alanında uzmanlaşarak insanların sağlık ihtiyaçlarına çözüm üretmeyi hedefliyorum.',
        interests = ARRAY['Eczacılık', 'Sağlık', 'İlaç', 'Danışmanlık', 'Hizmet'],
        location = 'Kayseri',
        profession = 'Eczacı',
        image_url = 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
        is_verified = true
    WHERE id = candidate15_uuid;

    -- Update selector profiles
    UPDATE public.user_profiles SET
        age = 45,
        gender = 'male'::public.gender_type,
        bio = 'Deneyimli görücü ve aile büyüğü',
        location = 'İstanbul',
        profession = 'İş Adamı',
        is_verified = true
    WHERE id = selector1_uuid;

    UPDATE public.user_profiles SET
        age = 42,
        gender = 'female'::public.gender_type,
        bio = 'Ailenin büyüğü ve deneyimli görücü',
        location = 'İstanbul',
        profession = 'Ev Hanımı',
        is_verified = true
    WHERE id = selector2_uuid;

    UPDATE public.user_profiles SET
        age = 48,
        gender = 'male'::public.gender_type,
        bio = 'Deneyimli görücü ve aile rehberi',
        location = 'Ankara',
        profession = 'Mühendis',
        is_verified = true
    WHERE id = selector3_uuid;

    UPDATE public.user_profiles SET
        age = 43,
        gender = 'female'::public.gender_type,
        bio = 'Aile danışmanı ve görücü',
        location = 'İzmir',
        profession = 'Öğretmen',
        is_verified = true
    WHERE id = selector4_uuid;

    -- Create selector-candidate relationships
    INSERT INTO public.selector_candidates (selector_id, candidate_id) VALUES
        (selector1_uuid, candidate1_uuid),
        (selector2_uuid, candidate2_uuid),
        (selector3_uuid, candidate3_uuid),
        (selector4_uuid, candidate4_uuid),
        (selector1_uuid, candidate5_uuid),
        (selector2_uuid, candidate6_uuid),
        (selector3_uuid, candidate7_uuid),
        (selector4_uuid, candidate8_uuid);

    -- Create sample match proposals
    INSERT INTO public.match_proposals (
        id, selector_id, candidate_1_id, candidate_2_id, 
        status_1, status_2, final_status, selector_message
    ) VALUES 
        (proposal1_uuid, selector1_uuid, candidate1_uuid, candidate2_uuid, 
         'pending'::public.match_proposal_status, 'pending'::public.match_proposal_status, 
         'pending'::public.match_proposal_status, 'İkiniz birbiriniz için çok uygun görünüyorsunuz. Tanışmanızı öneriyorum.'),
        (proposal2_uuid, selector2_uuid, candidate3_uuid, candidate4_uuid, 
         'accepted'::public.match_proposal_status, 'pending'::public.match_proposal_status, 
         'pending'::public.match_proposal_status, 'Ortak ilgi alanlarınız var, tanışmanızı tavsiye ederim.'),
        (proposal3_uuid, selector3_uuid, candidate5_uuid, candidate6_uuid, 
         'accepted'::public.match_proposal_status, 'accepted'::public.match_proposal_status, 
         'matched'::public.match_proposal_status, 'Mükemmel bir eşleşme! İkiniz birbirinize çok uygun.');

    -- Create sample conversation (automatically created by trigger for matched proposals)
    INSERT INTO public.conversations (id, match_id, participant_one_id, participant_two_id) VALUES
        (conversation1_uuid, proposal3_uuid, candidate5_uuid, candidate6_uuid);

    -- Create sample messages
    INSERT INTO public.messages (conversation_id, sender_id, content) VALUES
        (conversation1_uuid, candidate5_uuid, 'Merhaba! Tanıştığımıza memnun oldum.'),
        (conversation1_uuid, candidate6_uuid, 'Merhaba! Ben de çok memnun oldum. Nasılsınız?'),
        (conversation1_uuid, candidate5_uuid, 'Teşekkür ederim, gayet iyiyim. Ortak ilgi alanlarımızın olması çok güzel.'),
        (conversation1_uuid, candidate6_uuid, 'Evet, ben de aynı şekilde düşünüyorum. Belki bir kahve içmek istersiniz?');

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 15. Create cleanup function for testing
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

-- 16. Create utility functions for application
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