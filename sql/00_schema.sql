-- Core tables (current schema)

CREATE TABLE IF NOT EXISTS sets (
  set_id   BIGSERIAL PRIMARY KEY,
  set_code TEXT NOT NULL UNIQUE,
  set_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS card_catalogue (
  id          BIGINT PRIMARY KEY,       -- Konami card ID
  name        TEXT NOT NULL,
  type        TEXT,
  frameType   TEXT,
  description TEXT,
  level       NUMERIC,
  atk         NUMERIC,
  def         NUMERIC,
  race        TEXT,
  attribute   TEXT,
  archetype   TEXT
);

CREATE TABLE IF NOT EXISTS printings (
  printing_id   BIGSERIAL PRIMARY KEY,
  printing_code TEXT NOT NULL,
  set_code      TEXT NOT NULL REFERENCES sets(set_code),
  card_id       BIGINT REFERENCES card_catalogue(id),
  card_name     TEXT NOT NULL,
  rarity        TEXT NOT NULL,
  variant_name  TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS inventory (
  inventory_id BIGSERIAL PRIMARY KEY,
  printing_id  BIGINT NOT NULL REFERENCES printings(printing_id) ON DELETE CASCADE,
  card_grade   TEXT NOT NULL DEFAULT 'Ungraded',
  edition      TEXT NOT NULL DEFAULT '',
  location     TEXT,
  quantity     INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  price_each   NUMERIC(10,2),
  binder_value NUMERIC(12,2)
);
