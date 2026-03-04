SELECT
    s.set_code,
    s.set_name,
    COUNT(DISTINCT p.printing_id) AS total_printings,
    COUNT(DISTINCT i.printing_id) AS owned_printings,
    ROUND(
        COUNT(DISTINCT i.printing_id)::numeric
        / COUNT(DISTINCT p.printing_id),
        2
    ) AS completion_rate
FROM sets s
JOIN printings p
ON s.set_code = p.set_code
LEFT JOIN inventory i
ON p.printing_id = i.printing_id
GROUP BY s.set_code, s.set_name
ORDER BY completion_rate DESC;
