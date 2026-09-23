WITH CustomerTotals AS (
	SELECT
		CustomerId,
		SUM(Total) AS total_spent
	FROM Invoice
	GROUP BY CustomerId
)
SELECT
	CustomerTotals.CustomerId AS customer_id,
	Customer.FirstName AS first_name,
	Customer.LastName AS last_name,
	CustomerTotals.total_spent
FROM CustomerTotals
JOIN Customer ON CustomerTotals.CustomerId = Customer.CustomerId
WHERE total_spent > 40
ORDER BY total_spent DESC;