-- Create candidate request system for approval-based candidate addition
-- Location: supabase/migrations/20250125140000_create_candidate_requests_table.sql

-- Create candidate requests table
CREATE TABLE IF NOT EXISTS public.candidate_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    selector_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    candidate_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'rejected'
    relation TEXT NOT NULL, -- Yakınlık derecesi
    message TEXT, -- Optional message from selector
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(selector_id, candidate_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_candidate_requests_selector ON public.candidate_requests(selector_id);
CREATE INDEX IF NOT EXISTS idx_candidate_requests_candidate ON public.candidate_requests(candidate_id);
CREATE INDEX IF NOT EXISTS idx_candidate_requests_status ON public.candidate_requests(status);

-- Enable Row Level Security
ALTER TABLE public.candidate_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their requests" ON public.candidate_requests;
DROP POLICY IF EXISTS "Selectors can create requests" ON public.candidate_requests;
DROP POLICY IF EXISTS "Users can update their requests" ON public.candidate_requests;

-- Create RLS policies
-- Users can view requests where they are involved
CREATE POLICY "Users can view their requests" 
ON public.candidate_requests FOR SELECT 
USING (auth.uid() IN (
    SELECT id FROM public.user_profiles WHERE id = selector_id OR id = candidate_id
));

-- Selectors can create requests
CREATE POLICY "Selectors can create requests" 
ON public.candidate_requests FOR INSERT 
WITH CHECK (auth.uid() IN (
    SELECT id FROM public.user_profiles WHERE id = selector_id
));

-- Both users can update (selector to cancel, candidate to accept/reject)
CREATE POLICY "Users can update their requests" 
ON public.candidate_requests FOR UPDATE 
USING (auth.uid() IN (
    SELECT id FROM public.user_profiles WHERE id = selector_id OR id = candidate_id
));

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_candidate_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_candidate_requests_updated_at ON public.candidate_requests;

CREATE TRIGGER update_candidate_requests_updated_at
    BEFORE UPDATE ON public.candidate_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_candidate_requests_updated_at();

-- Add relation column to selector_candidates if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'selector_candidates' AND column_name = 'relation') THEN
        ALTER TABLE public.selector_candidates ADD COLUMN relation TEXT;
        COMMENT ON COLUMN public.selector_candidates.relation IS 'Relationship degree between selector and candidate';
    END IF;
END $$;

-- Add comments
COMMENT ON TABLE public.candidate_requests IS 'Table for managing candidate addition requests with approval system';
COMMENT ON COLUMN public.candidate_requests.relation IS 'Relationship degree specified by selector';