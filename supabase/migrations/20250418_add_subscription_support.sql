-- Add subscription support to the database

-- Update users table to add plan column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'plan') THEN
        ALTER TABLE users ADD COLUMN plan TEXT NOT NULL DEFAULT 'free';
    END IF;
END$$;

-- Create subscription_history table if it doesn't exist
CREATE TABLE IF NOT EXISTS subscription_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id TEXT NOT NULL,
    status TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    stripe_subscription_id TEXT,
    stripe_customer_id TEXT,
    metadata JSONB
);

-- Add index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_subscription_history_user_id ON subscription_history(user_id);

-- Add index on stripe_subscription_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_subscription_history_stripe_subscription_id ON subscription_history(stripe_subscription_id);

-- Add RLS policies for subscription_history table
ALTER TABLE subscription_history ENABLE ROW LEVEL SECURITY;

-- Policy for users to view their own subscription history
CREATE POLICY "Users can view their own subscription history"
    ON subscription_history
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy for service role to manage all subscription history
CREATE POLICY "Service role can manage all subscription history"
    ON subscription_history
    USING (auth.role() = 'service_role');

-- Add function to update user points when subscription is created or renewed
CREATE OR REPLACE FUNCTION update_user_points_on_subscription()
RETURNS TRIGGER AS $$
DECLARE
    points_to_add INTEGER;
BEGIN
    -- Determine points based on plan_id
    CASE NEW.plan_id
        WHEN 'plan_ume' THEN points_to_add := 500;
        WHEN 'plan_take' THEN points_to_add := 1000;
        WHEN 'plan_matsu' THEN points_to_add := 2000;
        ELSE points_to_add := 0;
    END CASE;
    
    -- Only add points for new or renewed subscriptions
    IF NEW.status = 'active' AND (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status != 'active')) THEN
        -- Update user points
        UPDATE users
        SET points = points + points_to_add
        WHERE id = NEW.user_id;
        
        -- Add entry to point_history
        INSERT INTO point_history (user_id, type, amount, description)
        VALUES (NEW.user_id, 'subscription', points_to_add, NEW.plan_id || ' サブスクリプションポイント');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for subscription_history
DROP TRIGGER IF EXISTS trigger_update_user_points_on_subscription ON subscription_history;
CREATE TRIGGER trigger_update_user_points_on_subscription
    AFTER INSERT OR UPDATE OF status
    ON subscription_history
    FOR EACH ROW
    EXECUTE FUNCTION update_user_points_on_subscription();

-- Add function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for subscription_history
DROP TRIGGER IF EXISTS trigger_update_subscription_history_updated_at ON subscription_history;
CREATE TRIGGER trigger_update_subscription_history_updated_at
    BEFORE UPDATE
    ON subscription_history
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create point_history table if it doesn't exist
CREATE TABLE IF NOT EXISTS point_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    amount INTEGER NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expiry_date TIMESTAMP WITH TIME ZONE
);

-- Add index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_point_history_user_id ON point_history(user_id);

-- Add RLS policies for point_history table
ALTER TABLE point_history ENABLE ROW LEVEL SECURITY;

-- Policy for users to view their own point history
CREATE POLICY "Users can view their own point history"
    ON point_history
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy for service role to manage all point history
CREATE POLICY "Service role can manage all point history"
    ON point_history
    USING (auth.role() = 'service_role');
