-- Add phone column constraint to user_profiles table
-- Location: supabase/migrations/20250116130000_add_phone_column.sql

-- Check if phone column exists, if not add it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'phone') THEN
        ALTER TABLE public.user_profiles ADD COLUMN phone TEXT;
    END IF;
END $$;

-- Clean up any invalid phone data first
UPDATE public.user_profiles 
SET phone = NULL 
WHERE phone IS NOT NULL 
  AND (char_length(regexp_replace(phone, '[^0-9]', '', 'g')) != 11 
       OR regexp_replace(phone, '[^0-9]', '', 'g') !~ '^05[0-9]{9}$');

-- Add constraint for Turkish phone numbers (05xx xxx xx xx format)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.constraint_column_usage 
                   WHERE constraint_name = 'check_phone_format' AND table_name = 'user_profiles') THEN
        ALTER TABLE public.user_profiles
        ADD CONSTRAINT check_phone_format CHECK (
            phone IS NULL OR 
            (char_length(regexp_replace(phone, '[^0-9]', '', 'g')) = 11 AND 
             regexp_replace(phone, '[^0-9]', '', 'g') ~ '^05[0-9]{9}$')
        );
    END IF;
END $$;

-- Create index for phone number lookups if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_user_profiles_phone ON public.user_profiles(phone) WHERE phone IS NOT NULL;

-- Add comment
COMMENT ON COLUMN public.user_profiles.phone IS 'Turkish phone number in format 05xx xxx xx xx';