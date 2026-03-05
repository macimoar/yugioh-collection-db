-- Dashboard-friendly views (read-only metrics layer)
-- Works with: sets, printings, inventory, card_catalogue
-- Assumes rarity variants matter (printings define the checklist).

-- 1) Overall collection summary
CREATE OR REPLACE VIEW v_dashboard_collection_summary AS
SELECT
  COUNT(*) AS inventory_rows,
  SUM(i.quantity) AS total_cards_owned,
  ROUND(SUM(COALESCE(i.binder_value, 0)), 2) AS total_collection_value,
  COUNT(DISTINCT p.set_code) AS sets_with_any_owned,
  COUNT(DISTINCT p.printing_id) AS unique_printings_owned
FROM inventory i
JOIN printings p ON p.printing_id = i.printing_id;


-- 2) Value by location (binders/boxes)
CREATE OR REPLACE VIEW v_dashboard_value_by_location AS
SELECT
  COALESCE(NULLIF(TRIM(i.location), ''), '(Unassigned)') AS location,
  SUM(i.quantity) AS total_cards,
  ROUND(SUM(COALESCE(i.binder_value, 0)), 2) AS total_value,
  ROUND(AVG(NULLIF(i.price_each, 0)), 2) AS avg_price_each
FROM inventory i
GROUP BY 1
ORDER BY total_value DESC;


-- 3) Owned distribution by rarity
CREATE OR REPLACE VIEW v_dashboard_rarity_distribution AS
SELECT
  p.rarity,
  SUM(i.quantity) AS total_cards,
  COUNT(DISTINCT p.printing_id) AS unique_printings_owned,
  ROUND(SUM(COALESCE(i.binder_value, 0)), 2) AS total_value
FROM inventory i
JOIN printings p ON p.printing_id = i.printing_id
GROUP BY p.rarity
ORDER BY total_cards DESC;


-- 4) Most valuable owned items (line items, not aggregated across grades/editions)
CREATE OR REPLACE VIEW v_dashboard_top_valuable_items AS
SELECT
  p.card_name,
  p.printing_code,
  p.set_code,
  s.set_name,
  p.rarity,
  p.variant_name,
  i.card_grade,
  i.edition,
  COALESCE(NULLIF(TRIM(i.location), ''), '(Unassigned)') AS location,
  i.quantity,
  i.price_each,
  ROUND(COALESCE(i.binder_value, 0), 2) AS total_value
FROM inventory i
JOIN printings p ON p.printing_id = i.printing_id
LEFT JOIN sets s ON s.set_code = p.set_code
ORDER BY total_value DESC NULLS LAST;


-- 5) Set completion dashboard (rarity variants matter)
CREATE OR REPLACE VIEW v_dashboard_set_completion AS
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
  ) AS completion_rate,
  ROUND(
    SUM(CASE WHEN COALESCE(inv.qty_owned,0) > 0 THEN 1 ELSE 0 END)::numeric
    / NULLIF(COUNT(*)::numeric, 0),
    4
  ) AS completion_rate_alt -- same number; included for readability in some BI tools
FROM printings p
LEFT JOIN sets s ON s.set_code = p.set_code
LEFT JOIN inv_by_printing inv ON inv.printing_id = p.printing_id
GROUP BY p.set_code, s.set_name
ORDER BY completion_rate DESC, total_printings DESC;
