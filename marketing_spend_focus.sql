WITH CustomerOverview AS (
	SELECT
		CustomerId,
		SUM(Total) AS total_spend,
		COUNT(InvoiceId) AS purchase_count,
		MAX(InvoiceDate) AS latest_purchase
	FROM Invoice
	GROUP BY CustomerId
),
TargetCountries AS (
	SELECT
		Country
	FROM Customer
	GROUP BY Country
	HAVING COUNT(DISTINCT CustomerId) > 5
),
BuyerType AS (
	SELECT
		CustomerOverview.CustomerId,
		TargetCountries.Country,
		CustomerOverview.total_spend,
		CASE
			WHEN CustomerOverview.purchase_count = 1 THEN 'one-time'
			WHEN CustomerOverview.purchase_count <= 5 THEN 'occasional'
			ELSE 'frequent'
		END AS customer_type,
		julianday((SELECT MAX(InvoiceDate) FROM Invoice)) - julianday(CustomerOverview.latest_purchase) AS days_since_last_purchase,
		RANK() OVER (PARTITION BY TargetCountries.Country ORDER BY CustomerOverview.total_spend DESC) AS spend_rank
	FROM CustomerOverview
	JOIN Customer ON CustomerOverview.CustomerId = Customer.CustomerId
	JOIN TargetCountries ON Customer.Country = TargetCountries.Country
)
SELECT
	Customer.FirstName AS first_name,
	Customer.LastName AS last_name,
	BuyerType.Country AS country,
	BuyerType.total_spend,
	BuyerType.spend_rank,
	BuyerType.customer_type,
	BuyerType.days_since_last_purchase
FROM Customer
JOIN BuyerType ON Customer.CustomerId = BuyerType.CustomerId
ORDER BY BuyerType.Country, BuyerType.spend_rank;