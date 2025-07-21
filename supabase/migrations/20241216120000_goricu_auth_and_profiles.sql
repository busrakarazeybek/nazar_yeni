-- Görücü Matchmaker App - Authentication and User Management Module
-- Location: supabase/migrations/20241216120000_goricu_auth_and_profiles.sql

-- 1. Enable required extensions (if not already enabled)
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; -- Already enabled in Supabase
-- CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- Already enabled in Supabase

-- 2. Create custom types for the application
CREATE TYPE public.user_role AS ENUM ('candidate', 'selector', 'admin');
CREATE TYPE public.gender_type AS ENUM ('male', 'female', 'other', 'prefer_not_to_say');
CREATE TYPE public.match_status AS ENUM ('pending', 'accepted', 'rejected');

-- 3. Create user_profiles table (intermediary for auth.users)
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

-- 4. Create selector-candidate relationships table
CREATE TABLE public.selector_candidates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    selector_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    candidate_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(selector_id, candidate_id)
);

-- 5. Create matches table for matchmaking functionality
CREATE TABLE public.matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    selector_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    candidate_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    target_candidate_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    status public.match_status DEFAULT 'pending'::public.match_status,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Create conversations table for messaging
CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE,
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
CREATE INDEX idx_selector_candidates_selector ON public.selector_candidates(selector_id);
CREATE INDEX idx_selector_candidates_candidate ON public.selector_candidates(candidate_id);
CREATE INDEX idx_matches_selector ON public.matches(selector_id);
CREATE INDEX idx_matches_candidate ON public.matches(candidate_id);
CREATE INDEX idx_matches_target ON public.matches(target_candidate_id);
CREATE INDEX idx_matches_status ON public.matches(status);
CREATE INDEX idx_conversations_participants ON public.conversations(participant_one_id, participant_two_id);
CREATE INDEX idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX idx_messages_sender ON public.messages(sender_id);

-- 9. Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.selector_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
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

-- 12. Create trigger function for automatic profile creation
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

-- 13. Create trigger for new user creation
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 14. Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- 15. Create triggers for updated_at
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_matches_updated_at
    BEFORE UPDATE ON public.matches
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 16. Create mock data for testing
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    selector1_uuid UUID := gen_random_uuid();
    selector2_uuid UUID := gen_random_uuid();
    candidate1_uuid UUID := gen_random_uuid();
    candidate2_uuid UUID := gen_random_uuid();
    candidate3_uuid UUID := gen_random_uuid();
    candidate4_uuid UUID := gen_random_uuid();
    candidate5_uuid UUID := gen_random_uuid();
    match1_uuid UUID := gen_random_uuid();
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

    -- Create selector-candidate relationships
    INSERT INTO public.selector_candidates (selector_id, candidate_id) VALUES
        (selector1_uuid, candidate1_uuid),
        (selector2_uuid, candidate2_uuid),
        (selector1_uuid, candidate3_uuid);

    -- Create sample matches
    INSERT INTO public.matches (id, selector_id, candidate_id, target_candidate_id, status) VALUES
        (match1_uuid, selector1_uuid, candidate1_uuid, candidate2_uuid, 'pending'::public.match_status);

    -- Create sample conversation
    INSERT INTO public.conversations (id, match_id, participant_one_id, participant_two_id) VALUES
        (conversation1_uuid, match1_uuid, candidate1_uuid, candidate2_uuid);

    -- Create sample messages
    INSERT INTO public.messages (conversation_id, sender_id, content) VALUES
        (conversation1_uuid, candidate1_uuid, 'Merhaba! Tanıştığımıza memnun oldum.'),
        (conversation1_uuid, candidate2_uuid, 'Merhaba! Ben de çok memnun oldum. Nasılsınız?');

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 17. Create cleanup function for testing
CREATE OR REPLACE FUNCTION public.cleanup_test_data()
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