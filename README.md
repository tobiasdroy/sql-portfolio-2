# SQL Portfolio 2 - Chinook Database

## About this project

A follow-up to [SQL Portfolio 1](#), moving from single-table reporting questions ("what's biggest") to questions that need row-level comparison within a group and multi-step logic ("who matters, and why"). Each query builds on the last: `CASE WHEN` and `HAVING` first, then date functions, then CTEs to chain steps together, then window functions to compare individual customers against their peers without collapsing the data. The final query combines all of it into one piece of customer-behaviour analysis.

## Tools used

SQLite, DB Browser for SQLite

## Categorising tracks by length

**Question:** How do the tracks in the catalogue break down by length?

**Query**
```sql
SELECT Name,
		CASE
				WHEN Milliseconds < 120000 THEN 'Short'
				WHEN Milliseconds >= 300000 THEN 'Long'
				ELSE 'Medium'
		END AS Length
FROM Track
```

**Result:**
*(screenshot to add)*

**Finding:**
*(add once screenshot is in)*

## Genres with more than 50 tracks

**Question:** Which genres have a large enough catalogue (more than 50 tracks) to be worth analysing on their own, rather than being a rounding error in the totals?

**Query**
```sql
SELECT
		Genre.Name AS genre_name, 
		COUNT(Track.TrackId) AS number_of_tracks
FROM Track
JOIN Genre ON Track.GenreId = Genre.GenreId
GROUP BY Genre.GenreId
HAVING COUNT(Track.TrackId) > 50;
```

**Result:**
*(screenshot to add)*

**Finding:**
*(add once screenshot is in)*

## Revenue by month

**Question:** How has monthly revenue moved over time?

**Query**
```sql
SELECT 
		strftime('%Y', Invoice.InvoiceDate) AS invoice_year,
		strftime('%m', Invoice.InvoiceDate) AS invoice_month,
		SUM(Invoice.Total) AS total_revenue
FROM Invoice
GROUP BY invoice_year, invoice_month
ORDER BY invoice_year, invoice_month
```

**Result:**
*(screenshot to add)*

**Finding:**
*(add once screenshot is in)*

## Customers who have spent more than $40

**Question:** Which customers have crossed the $40 lifetime spend mark?

**Query**
```sql
WITH CustomerTotals AS (
	SELECT 
		CustomerId, 
		SUM(Total) AS total_spent
	FROM Invoice
	GROUP BY CustomerId
)
SELECT 
	CustomerTotals.CustomerId,
	Customer.FirstName AS first_name,
	Customer.LastName AS last_name,
	CustomerTotals.total_spent
FROM CustomerTotals
JOIN Customer ON CustomerTotals.CustomerId = Customer.CustomerId
WHERE total_spent > 40
ORDER BY total_spent DESC
```

**Result:**
*(screenshot to add)*

**Finding:**
*(add once screenshot is in)*

## Biggest spenders per country

**Question:** Who is the top-spending customer in each country?

**Query**
```sql
WITH CustomerTotal AS (
	SELECT 
		CustomerId,
		SUM(Total) AS total_spent
	FROM Invoice
	GROUP BY CustomerId
)
SELECT
	Customer.Country,
	Customer.CustomerId, 
	Customer.FirstName,
	Customer.LastName,
	CustomerTotal.total_spent,
	RANK() OVER (PARTITION BY Customer.Country ORDER BY CustomerTotal.total_spent DESC) AS spend_rank
FROM CustomerTotal
JOIN Customer ON CustomerTotal.CustomerId = Customer.CustomerId
ORDER BY Customer.Country
```

**Result:**
*(screenshot to add)*

**Finding:**
*(add once screenshot is in)*

## Time between first and most recent purchase

**Question:** For each customer, how long is the gap between their first and most recent purchase — a rough proxy for how long they've stuck around as a customer?

**Query**
```sql
WITH InvoiceExtremes AS (
	SELECT
		CustomerId,
		MIN(InvoiceDate) AS earliest_invoice,
		MAX(InvoiceDate) AS latest_invoice
	FROM Invoice
	GROUP BY CustomerId
)
SELECT
	FirstName, 
	LastName,
	earliest_invoice,
	latest_invoice,
	julianday(latest_invoice) - julianday(earliest_invoice) AS time_between
FROM InvoiceExtremes
JOIN Customer ON InvoiceExtremes.CustomerId = Customer.CustomerId
ORDER BY time_between DESC
```

**Result:**
*(screenshot to add)*

**Finding:**
*(add once screenshot is in)*

## Marketing and retention focus

**Question:** In countries with a large enough customer base to make comparison meaningful, who are the top-spending customers, and is each one a reliable repeat buyer or a customer who might already be going quiet?

Rank by spend alone can mislead: a customer sitting at #1 in their country might be one large one-off purchase rather than a stable relationship. This query pairs the spend rank with a buyer-type label and a recency figure, so a rank can be read alongside whether it reflects loyalty or a fluke.

**Query**
```sql
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
		total_spend,
		CASE
			WHEN purchase_count = 1 THEN 'one-time'
			WHEN purchase_count <= 5 THEN 'occasional'
			ELSE 'frequent'
		END AS customer_type,
		julianday((SELECT MAX(InvoiceDate) FROM Invoice)) - julianday(latest_purchase) AS days_since_last_purchase,
		RANK() OVER(PARTITION BY TargetCountries.Country ORDER BY total_spend DESC) AS spend_rank
	FROM CustomerOverview
	JOIN Customer ON CustomerOverview.CustomerId = Customer.CustomerId
	JOIN TargetCountries ON Customer.Country = TargetCountries.Country
	)
SELECT
	FirstName,
	LastName,
	BuyerType.Country,
	total_spend,
	spend_rank,
	customer_type,
	days_since_last_purchase
FROM Customer
JOIN BuyerType ON Customer.CustomerId = BuyerType.CustomerId
ORDER BY BuyerType.Country, spend_rank
```

**Result:**
*(screenshot to add)*

**Finding:**
*(add once screenshot is in)*

## Skills demonstrated
- Window functions (`RANK() OVER`, `PARTITION BY`) to compare individual customers against peers in the same country without collapsing the data
- CTEs (`WITH`) to chain multi-step logic into readable stages, including CTEs built on top of other CTEs
- `HAVING` to filter groups after aggregation, distinct from `WHERE`
- `CASE WHEN` to bucket customers into behavioural categories
- Date functions (`strftime`, `julianday`) for monthly trends and gap-between-dates calculations
- Deliberately choosing plain aggregation over a window function when the output doesn't need row-level detail, rather than defaulting to the newest tool learned
- Combining all of the above into one query that answers a compound business question, rather than forcing every technique into a single query for its own sake
