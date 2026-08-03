-- Demo schema for Day 2 SQL panels (orders + api_requests)
CREATE TABLE IF NOT EXISTS orders (
  id          SERIAL PRIMARY KEY,
  status      TEXT NOT NULL,
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

CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders (created_at);
CREATE INDEX IF NOT EXISTS idx_api_requests_created_at ON api_requests (created_at);

-- Seed ~6 hours of synthetic traffic
INSERT INTO orders (status, amount, created_at)
SELECT
  (ARRAY['pending', 'paid', 'shipped', 'cancelled'])[1 + (random() * 3)::int],
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
