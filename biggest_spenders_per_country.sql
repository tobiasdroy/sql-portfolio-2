WITH CustomerTotals AS (
	SELECT
		CustomerId,
		SUM(Total) AS total_spent
	FROM Invoice
	GROUP BY CustomerId
)
SELECT
	Customer.Country AS country,
	Customer.CustomerId AS customer_id,
	Customer.FirstName AS first_name,
	Customer.LastName AS last_name,
	CustomerTotals.total_spent,
	RANK() OVER (PARTITION BY Customer.Country ORDER BY CustomerTotals.total_spent DESC) AS spend_rank
FROM CustomerTotals
JOIN Customer ON CustomerTotals.CustomerId = Customer.CustomerId
ORDER BY Customer.Country;