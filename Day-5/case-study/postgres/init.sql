-- ShopFront demo schema
CREATE TABLE IF NOT EXISTS orders (
  id          SERIAL PRIMARY KEY,
  status      TEXT NOT NULL,
  amount      NUMERIC(10, 2) NOT NULL DEFAULT 0,
  channel     TEXT NOT NULL DEFAULT 'web',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders (created_at);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders (status);

-- Seed a few historical rows so SQL panels work immediately
INSERT INTO orders (status, amount, channel, created_at)
SELECT
  (ARRAY['paid', 'paid', 'paid', 'declined', 'failed'])[1 + (random() * 4)::int],
  round((random() * 180 + 10)::numeric, 2),
  (ARRAY['web', 'web', 'mobile'])[1 + (random() * 2)::int],
  NOW() - (random() * INTERVAL '6 hours')
FROM generate_series(1, 200);
