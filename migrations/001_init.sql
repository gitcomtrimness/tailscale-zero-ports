-- 001_init: first schema for the Meridian internal database.
-- Safe to run more than once.
CREATE TABLE IF NOT EXISTS schema_migrations (
  version    text PRIMARY KEY,
  applied_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS facilities (
  id    serial PRIMARY KEY,
  name  text NOT NULL,
  state text NOT NULL
);

INSERT INTO schema_migrations (version) VALUES ('001_init')
ON CONFLICT (version) DO NOTHING;