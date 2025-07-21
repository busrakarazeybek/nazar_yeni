-- Add candidate preferences to user_profiles table
-- Location: supabase/migrations/20250116120000_add_candidate_preferences.sql

-- Add preference fields to user_profiles table
ALTER TABLE public.user_profiles
ADD COLUMN preferred_age_min INTEGER,
ADD COLUMN preferred_age_max INTEGER,
ADD COLUMN preferred_cities TEXT[],
ADD COLUMN preferred_genders TEXT[];

-- Add constraints for age preferences
ALTER TABLE public.user_profiles
ADD CONSTRAINT check_preferred_age_min CHECK (preferred_age_min IS NULL OR (preferred_age_min >= 18 AND preferred_age_min <= 100)),
ADD CONSTRAINT check_preferred_age_max CHECK (preferred_age_max IS NULL OR (preferred_age_max >= 18 AND preferred_age_max <= 100)),
ADD CONSTRAINT check_preferred_age_range CHECK (preferred_age_min IS NULL OR preferred_age_max IS NULL OR preferred_age_min <= preferred_age_max);

-- Create indexes for preference-based filtering
CREATE INDEX idx_user_profiles_preferred_age_min ON public.user_profiles(preferred_age_min);
CREATE INDEX idx_user_profiles_preferred_age_max ON public.user_profiles(preferred_age_max);
CREATE INDEX idx_user_profiles_preferred_cities ON public.user_profiles USING GIN(preferred_cities);
CREATE INDEX idx_user_profiles_preferred_genders ON public.user_profiles USING GIN(preferred_genders);

-- Create helper function for preference-based filtering
CREATE OR REPLACE FUNCTION public.get_filtered_candidates_by_preferences(
    selector_uuid UUID,
    candidate_uuid UUID DEFAULT NULL
)
RETURNS TABLE(
    id UUID,
    full_name TEXT,
    age INTEGER,
    gender TEXT,
    profession TEXT,
    location TEXT,
    bio TEXT,
    interests TEXT[],
    image_url TEXT,
    is_verified BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    candidate_preferred_age_min INTEGER;
    candidate_preferred_age_max INTEGER;
    candidate_preferred_cities TEXT[];
    candidate_preferred_genders TEXT[];
BEGIN
    -- If candidate_uuid is provided, get their preferences
    IF candidate_uuid IS NOT NULL THEN
        SELECT 
            up.preferred_age_min,
            up.preferred_age_max,
            up.preferred_cities,
            up.preferred_genders
        INTO 
            candidate_preferred_age_min,
            candidate_preferred_age_max,
            candidate_preferred_cities,
            candidate_preferred_genders
        FROM public.user_profiles up
        WHERE up.id = candidate_uuid;
    END IF;

    -- Return filtered candidates based on preferences
    RETURN QUERY
    SELECT 
        up.id,
        up.full_name,
        up.age,
        up.gender::TEXT,
        up.profession,
        up.location,
        up.bio,
        up.interests,
        up.image_url,
        up.is_verified
    FROM public.user_profiles up
    WHERE up.role = 'candidate'::public.user_role
      AND up.is_active = true
      AND up.is_verified = true
      AND up.id != COALESCE(candidate_uuid, '00000000-0000-0000-0000-000000000000'::UUID)
      AND NOT EXISTS (
          SELECT 1 FROM public.selector_candidates sc
          WHERE sc.selector_id = selector_uuid AND sc.candidate_id = up.id
      )
      -- Apply preference filters if candidate preferences exist
      AND (
          candidate_uuid IS NULL OR
          (
              -- Age filter
              (candidate_preferred_age_min IS NULL OR up.age IS NULL OR up.age >= candidate_preferred_age_min) AND
              (candidate_preferred_age_max IS NULL OR up.age IS NULL OR up.age <= candidate_preferred_age_max) AND
              -- City filter
              (candidate_preferred_cities IS NULL OR array_length(candidate_preferred_cities, 1) IS NULL OR up.location = ANY(candidate_preferred_cities)) AND
              -- Gender filter
              (candidate_preferred_genders IS NULL OR array_length(candidate_preferred_genders, 1) IS NULL OR up.gender::TEXT = ANY(candidate_preferred_genders))
          )
      )
    ORDER BY up.created_at DESC;
END;
$$;

-- Update existing candidates with sample preferences for testing
DO $$
DECLARE
    candidate_id UUID;
BEGIN
    -- Update some candidates with preferences
    FOR candidate_id IN 
        SELECT id FROM public.user_profiles WHERE role = 'candidate'::public.user_role AND email LIKE '%@goricu.com' LIMIT 10
    LOOP
        UPDATE public.user_profiles 
        SET 
            preferred_age_min = 23 + (random() * 5)::INTEGER,
            preferred_age_max = 28 + (random() * 7)::INTEGER,
            preferred_cities = CASE 
                WHEN random() < 0.5 THEN ARRAY['İstanbul', 'Ankara']
                ELSE ARRAY['İzmir', 'Bursa', 'Antalya']
            END,
            preferred_genders = CASE 
                WHEN random() < 0.3 THEN ARRAY['male']
                WHEN random() < 0.6 THEN ARRAY['female'] 
                ELSE ARRAY['male', 'female']
            END
        WHERE id = candidate_id;
    END LOOP;
END $$;