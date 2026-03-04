-- Uniqueness for inventory upserts
ALTER TABLE inventory
  ADD CONSTRAINT IF NOT EXISTS inventory_identity_key
  UNIQUE (printing_id, card_grade, edition, location);

-- Make printings identity stable (rarity variants matter, artwork variants supported)
CREATE UNIQUE INDEX IF NOT EXISTS ux_printings_identity
ON printings (printing_code, rarity, variant_name);

-- Speed
CREATE INDEX IF NOT EXISTS idx_printings_set_code ON printings(set_code);
CREATE INDEX IF NOT EXISTS idx_printings_card_id  ON printings(card_id);
CREATE INDEX IF NOT EXISTS idx_inventory_printing ON inventory(printing_id);
CREATE INDEX IF NOT EXISTS idx_inventory_location ON inventory(location);
