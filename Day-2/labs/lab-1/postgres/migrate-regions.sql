-- Apply when upgrading an existing Day-2 postgres volume (init.sql only runs on first boot).
-- Usage (PowerShell):
--   Get-Content postgres\migrate-regions.sql | docker exec -i postgres psql -U grafana -d demo

ALTER TABLE orders ADD COLUMN IF NOT EXISTS region TEXT NOT NULL DEFAULT 'us-east';

CREATE TABLE IF NOT EXISTS regions (
  region    TEXT PRIMARY KEY,
  latitude  DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL
);

INSERT INTO regions (region, latitude, longitude) VALUES
  ('us-east',  37.7749,  -122.4194),
  ('us-west',  34.0522,  -118.2437),
  ('eu-west',  51.5074,   -0.1278),
  ('ap-south', 19.0760,   72.8777)
ON CONFLICT (region) DO NOTHING;

-- Spread existing rows across regions for Geomap labs
UPDATE orders
SET region = (ARRAY['us-east', 'us-west', 'eu-west', 'ap-south'])[1 + ((id - 1) % 4)];
