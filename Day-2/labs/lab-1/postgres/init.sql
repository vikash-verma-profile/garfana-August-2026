-- Demo schema for Day 2 SQL + Geomap panels
CREATE TABLE IF NOT EXISTS orders (
  id          SERIAL PRIMARY KEY,
  status      TEXT NOT NULL,
  region      TEXT NOT NULL DEFAULT 'us-east',
  amount      NUMERIC(10, 2) NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS api_requests (
  id           SERIAL PRIMARY KEY,
  endpoint     TEXT NOT NULL,
  status_code  INT NOT NULL,
  duration_ms  INT NOT NULL,
  service      TEXT NOT NULL DEFAULT 'api',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Regions with coordinates for Lab 3 Geomap panel
CREATE TABLE IF NOT EXISTS regions (
  region    TEXT PRIMARY KEY,
  latitude  DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders (created_at);
CREATE INDEX IF NOT EXISTS idx_api_requests_created_at ON api_requests (created_at);
CREATE INDEX IF NOT EXISTS idx_api_requests_duration ON api_requests (duration_ms);

INSERT INTO regions (region, latitude, longitude) VALUES
  ('us-east',  37.7749,  -122.4194),
  ('us-west',  34.0522,  -118.2437),
  ('eu-west',  51.5074,   -0.1278),
  ('ap-south', 19.0760,   72.8777)
ON CONFLICT (region) DO NOTHING;

-- Seed ~6 hours of synthetic traffic
INSERT INTO orders (status, region, amount, created_at)
SELECT
  (ARRAY['pending', 'paid', 'shipped', 'cancelled'])[1 + (random() * 3)::int],
  (ARRAY['us-east', 'us-west', 'eu-west', 'ap-south'])[1 + (random() * 3)::int],
  round((random() * 200 + 5)::numeric, 2),
  NOW() - (random() * INTERVAL '6 hours')
FROM generate_series(1, 500);

INSERT INTO api_requests (endpoint, status_code, duration_ms, service, created_at)
SELECT
  (ARRAY['/checkout', '/cart', '/pay', '/catalog', '/health'])[1 + (random() * 4)::int],
  (ARRAY[200, 200, 200, 201, 400, 500])[1 + (random() * 5)::int],
  (random() * 800 + 20)::int,
  'api',
  NOW() - (random() * INTERVAL '6 hours')
FROM generate_series(1, 800);
