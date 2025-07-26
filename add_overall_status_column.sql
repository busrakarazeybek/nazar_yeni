-- Add overall_status column to matches table
ALTER TABLE matches 
ADD COLUMN overall_status VARCHAR(20) DEFAULT 'pending';

-- Create index for better query performance
CREATE INDEX idx_matches_overall_status ON matches(overall_status);

-- Update existing records based on current status and target_status
UPDATE matches 
SET overall_status = CASE 
    WHEN status = 'accepted' AND target_status = 'accepted' THEN 'matched'
    WHEN status = 'rejected' OR target_status = 'rejected' THEN 'rejected'
    ELSE 'pending'
END;

-- Add check constraint to ensure valid values
ALTER TABLE matches 
ADD CONSTRAINT chk_overall_status 
CHECK (overall_status IN ('pending', 'matched', 'rejected'));