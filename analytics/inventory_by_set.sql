SELECT
    p.set_code,
    COUNT(*) AS unique_printings,
    SUM(i.quantity) AS total_cards
FROM inventory i
JOIN printings p
ON i.printing_id = p.printing_id
GROUP BY p.set_code
ORDER BY total_cards DESC;
