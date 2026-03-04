SELECT
    SUM(quantity * price_each) AS total_collection_value
FROM inventory;

SELECT
    location,
    SUM(quantity * price_each) AS location_value
FROM inventory
GROUP BY location
ORDER BY location_value DESC;
