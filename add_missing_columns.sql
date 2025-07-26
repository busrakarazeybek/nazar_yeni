-- user_profiles tablosuna eksik kolonları ekle
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS preferred_age_min INTEGER,
ADD COLUMN IF NOT EXISTS preferred_age_max INTEGER,
ADD COLUMN IF NOT EXISTS preferred_cities TEXT[],
ADD COLUMN IF NOT EXISTS preferred_interests TEXT[],
ADD COLUMN IF NOT EXISTS preferred_genders TEXT[];