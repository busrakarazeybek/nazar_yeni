-- Enhanced Sample Candidates for Testing - Görücü Matchmaker App
-- Location: supabase/migrations/20241218120000_enhanced_sample_candidates.sql

-- Add more diverse sample candidates for testing
DO $$
DECLARE
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
    selector3_uuid UUID := gen_random_uuid();
    selector4_uuid UUID := gen_random_uuid();
BEGIN
    -- Create additional auth users for more diverse candidates
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
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
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (selector3_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'hasan.secici@goricu.com', crypt('selector123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Hasan Seçici", "role": "selector"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (selector4_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'fatma.secici@goricu.com', crypt('selector123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Fatma Seçici", "role": "selector"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Update new candidate profiles with detailed information
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

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;