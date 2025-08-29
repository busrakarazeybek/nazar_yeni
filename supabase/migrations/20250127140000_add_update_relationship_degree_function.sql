-- Add RPC function to update relationship degree with proper security
-- Location: supabase/migrations/20250127140000_add_update_relationship_degree_function.sql

-- Create function to update selector-candidate relationship degree
CREATE OR REPLACE FUNCTION public.update_selector_candidate_relation(
    p_selector_id UUID,
    p_candidate_id UUID,
    p_relation TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if the authenticated user is either the selector or the candidate
    IF auth.uid() != p_selector_id AND auth.uid() != p_candidate_id THEN
        RAISE EXCEPTION 'Access denied: You can only update your own relationships';
    END IF;

    -- Check if the relationship exists and is active
    IF NOT EXISTS (
        SELECT 1 FROM public.selector_candidates 
        WHERE selector_id = p_selector_id 
        AND candidate_id = p_candidate_id 
        AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'Active relationship not found between selector and candidate';
    END IF;

    -- Update the relationship degree
    UPDATE public.selector_candidates
    SET relation = p_relation,
        updated_at = CURRENT_TIMESTAMP
    WHERE selector_id = p_selector_id 
    AND candidate_id = p_candidate_id;

    -- Check if update was successful
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Failed to update relationship degree';
    END IF;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.update_selector_candidate_relation(UUID, UUID, TEXT) TO authenticated;

-- Add updated_at column to selector_candidates if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'selector_candidates' AND column_name = 'updated_at') THEN
        ALTER TABLE public.selector_candidates ADD COLUMN updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;
        
        -- Add trigger to automatically update updated_at column
        CREATE TRIGGER update_selector_candidates_updated_at
            BEFORE UPDATE ON public.selector_candidates
            FOR EACH ROW
            EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
END $$;

-- Add comment
COMMENT ON FUNCTION public.update_selector_candidate_relation(UUID, UUID, TEXT) IS 'Updates relationship degree between selector and candidate with proper security checks';