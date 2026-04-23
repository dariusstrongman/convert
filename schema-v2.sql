-- Run in Supabase SQL Editor
-- Adds user accounts, Stripe billing, and monthly usage reset

-- Add new columns to existing table
ALTER TABLE pdfapi_keys
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT,
  ADD COLUMN IF NOT EXISTS monthly_limit INT NOT NULL DEFAULT 50,
  ADD COLUMN IF NOT EXISTS period_usage INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS period_reset_at TIMESTAMPTZ NOT NULL DEFAULT (date_trunc('month', now()) + interval '1 month');

-- Update existing rows
UPDATE pdfapi_keys SET monthly_limit = usage_limit WHERE monthly_limit = 50 AND usage_limit != 50;
UPDATE pdfapi_keys SET period_usage = usage_count WHERE period_usage = 0 AND usage_count > 0;

-- Index for user lookup
CREATE INDEX IF NOT EXISTS pdfapi_keys_user_id_idx ON pdfapi_keys (user_id);

-- RLS: allow users to see their own keys via Supabase Auth
DROP POLICY IF EXISTS "Service role full access" ON pdfapi_keys;
DROP POLICY IF EXISTS "users_own_keys" ON pdfapi_keys;

-- Service role can do anything (for n8n webhooks)
CREATE POLICY "service_full" ON pdfapi_keys FOR ALL
  USING (true) WITH CHECK (true);

-- Authenticated users can read their own keys
CREATE POLICY "users_read_own" ON pdfapi_keys FOR SELECT
  USING (user_id = auth.uid());

-- Allow authenticated users to update their own keys (regenerate)
CREATE POLICY "users_update_own" ON pdfapi_keys FOR UPDATE
  USING (user_id = auth.uid());
