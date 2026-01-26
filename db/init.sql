CREATE TABLE IF NOT EXISTS albums (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed enough rows so that a naive LIKE search can be non-trivial.
INSERT INTO albums (title, artist)
SELECT
  'Album ' || gs::text,
  'Artist ' || (gs % 200)::text
FROM generate_series(1, 50000) AS gs;
