SELECT
    p.rarity,
    SUM(i.quantity) AS total_cards
FROM inventory i
JOIN printings p
ON i.printing_id = p.printing_id
GROUP BY p.rarity
ORDER BY total_cards DESC;
