-- Alternative: Update existing RLS policy to allow candidates to update their own relationships

-- Drop existing policy
DROP POLICY IF EXISTS "selectors_manage_candidates" ON public.selector_candidates;

-- Create new policy allowing both selectors and candidates to manage relationships
CREATE POLICY "selector_candidate_relationship_management"
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
    OR candidate_id = auth.uid()
    OR public.is_admin()
);