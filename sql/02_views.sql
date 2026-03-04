CREATE OR REPLACE VIEW v_collection AS
SELECT
  i.inventory_id,
  i.quantity,
  i.card_grade,
  i.edition AS owned_edition,
  i.location,
  i.price_each,
  i.binder_value,

  p.printing_id,
  p.printing_code,
  p.set_code,
  s.set_name,
  p.rarity,
  p.variant_name,
  p.card_name AS printing_card_name,
  p.card_id,

  cc.name        AS catalogue_name,
  cc.type        AS catalogue_type,
  cc.frameType   AS frame_type,
  cc.race,
  cc.attribute,
  cc.level,
  cc.atk,
  cc.def,
  cc.archetype,
  cc.description
FROM inventory i
JOIN printings p ON p.printing_id = i.printing_id
LEFT JOIN sets s ON s.set_code = p.set_code
LEFT JOIN card_catalogue cc ON cc.id = p.card_id;


CREATE OR REPLACE VIEW v_set_completion AS
WITH inv_by_printing AS (
  SELECT printing_id, SUM(quantity) AS qty_owned
  FROM inventory
  GROUP BY printing_id
)
SELECT
  p.set_code,
  s.set_name,
  COUNT(*) AS total_printings,
  COUNT(*) FILTER (WHERE COALESCE(inv.qty_owned, 0) > 0) AS owned_printings,
  ROUND(
    COUNT(*) FILTER (WHERE COALESCE(inv.qty_owned, 0) > 0)::numeric
    / NULLIF(COUNT(*)::numeric, 0),
    4
  ) AS completion_rate
FROM printings p
LEFT JOIN sets s ON s.set_code = p.set_code
LEFT JOIN inv_by_printing inv ON inv.printing_id = p.printing_id
GROUP BY p.set_code, s.set_name;
