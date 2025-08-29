-- Add dual relationship fields to selector_candidates table
-- Location: supabase/migrations/20250127150000_add_dual_relation_fields.sql

-- Add new columns for dual relationships
ALTER TABLE public.selector_candidates 
ADD COLUMN IF NOT EXISTS selector_relation TEXT,
ADD COLUMN IF NOT EXISTS candidate_relation TEXT;

-- Migrate existing data: copy 'relation' to both new fields
UPDATE public.selector_candidates 
SET 
    selector_relation = relation,
    candidate_relation = relation
WHERE relation IS NOT NULL;

-- Add comments
COMMENT ON COLUMN public.selector_candidates.selector_relation IS 'How selector describes their relationship to candidate (e.g., "kızım")';
COMMENT ON COLUMN public.selector_candidates.candidate_relation IS 'How candidate describes their relationship to selector (e.g., "annem")';

-- Note: We keep the old 'relation' column for backward compatibility
-- It can be removed in a future migration after all code is updated