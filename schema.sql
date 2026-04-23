-- Run in Supabase SQL Editor
-- PDF API: api keys + usage tracking

CREATE TABLE IF NOT EXISTS pdfapi_keys (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    api_key text UNIQUE NOT NULL,
    email text NOT NULL,
    plan text DEFAULT 'free',
    usage_count integer DEFAULT 0,
    usage_limit integer DEFAULT 50,
    stripe_customer_id text,
    created_at timestamptz DEFAULT now(),
    last_used_at timestamptz
);

CREATE INDEX IF NOT EXISTS pdfapi_keys_api_key_idx ON pdfapi_keys (api_key);

CREATE TABLE IF NOT EXISTS pdfapi_logs (
    id bigserial PRIMARY KEY,
    api_key_id uuid REFERENCES pdfapi_keys(id),
    input_size integer,
    output_size integer,
    duration_ms integer,
    status text,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE pdfapi_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE pdfapi_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service role full access" ON pdfapi_keys FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON pdfapi_logs FOR ALL USING (true) WITH CHECK (true);
