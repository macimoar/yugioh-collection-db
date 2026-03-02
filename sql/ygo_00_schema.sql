BEGIN;

-- 1) Master sets table
CREATE TABLE IF NOT EXISTS sets (
  set_id    BIGSERIAL PRIMARY KEY,
  set_code  TEXT NOT NULL UNIQUE,           -- e.g. DABL, LOB, DRL2
  set_name  TEXT NOT NULL                   -- e.g. Darkwing Blast
);

-- 2) Printings: unique per Card Code
--    List of every card printing in existence
CREATE TABLE IF NOT EXISTS printings (
  printing_id   BIGSERIAL PRIMARY KEY,
  card_code     TEXT NOT NULL UNIQUE,       -- e.g. DABL-EN006
  set_code      TEXT NOT NULL REFERENCES sets(set_code),
  card_name     TEXT NOT NULL,
  rarity        TEXT,
  edition       TEXT,                       -- 1st Edition / Unlimited
  card_type     TEXT,                       -- Aqua / Spell / Trap / etc
  language      TEXT,                       
  number_in_set TEXT                        
);

-- 3) Inventory: what I actually own
CREATE TABLE IF NOT EXISTS inventory (
  inventory_id BIGSERIAL PRIMARY KEY,
  printing_id  BIGINT NOT NULL REFERENCES printings(printing_id) ON DELETE CASCADE,
  condition    TEXT DEFAULT 'Ungraded',     -- your "Card Grade"
  quantity     INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  price_each   NUMERIC(10,2),               -- store numeric, not "$0.51"
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  notes        TEXT
);

-- Computed value instead of storing "Binder Value"
-- (Supabase supports generated columns on Postgres)
ALTER TABLE inventory
  ADD COLUMN IF NOT EXISTS binder_value NUMERIC(12,2)
  GENERATED ALWAYS AS (COALESCE(price_each,0) * quantity) STORED;

-- 4) Set checklist items
CREATE TABLE IF NOT EXISTS set_checklist_items (
  checklist_item_id BIGSERIAL PRIMARY KEY,
  set_code          TEXT NOT NULL REFERENCES sets(set_code),
  card_code         TEXT NOT NULL,          -- e.g. DABL-EN006
  card_name         TEXT NOT NULL,
  rarity            TEXT,
  item_type         TEXT,                   -- Monster/Spell/Trap etc 
  -- You can keep this, but long-term you can *compute obtained* from inventory
  obtained          BOOLEAN DEFAULT FALSE,
  UNIQUE(set_code, card_code)
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_printings_set_code ON printings(set_code);
CREATE INDEX IF NOT EXISTS idx_printings_card_name ON printings(card_name);
CREATE INDEX IF NOT EXISTS idx_inventory_printing_id ON inventory(printing_id);

COMMIT;
