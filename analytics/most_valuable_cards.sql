SELECT
    p.card_name,
    p.printing_code,
    p.rarity,
    i.card_grade,
    i.quantity,
    i.price_each,
    (i.quantity * i.price_each) AS total_value
FROM inventory i
JOIN printings p
ON i.printing_id = p.printing_id
ORDER BY total_value DESC
LIMIT 20;

SELECT
    p.card_name,
    p.printing_code,
    p.rarity,
    i.card_grade,
    i.quantity,
    i.price_each
FROM inventory i 
JOIN printings p 
ON i.printing_id = p.printing_id 
ORDER BY i.price_each DESC 
LIMIT 20;
