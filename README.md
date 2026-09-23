# SQL Portfolio 2 - Chinook Database

## About this project

A follow-up to [SQL Portfolio 1](https://github.com/tobiasdroy/sql-portfolio-1), moving from single-table reporting questions ("what's biggest") to questions that need row-level comparison within a group and multi-step logic ("who matters, and why"). Each query builds on the last: `CASE WHEN` and `HAVING` first, then date functions, then CTEs to chain steps together, then window functions to compare individual customers against their peers without collapsing the data. The final query combines all of it into one piece of customer-behaviour analysis.

## Tools used

SQLite, DB Browser for SQLite

## Categorising tracks by length

**Question:** How do the tracks in the catalogue break down by length?

**Query**
```sql
WITH TrackLengths AS (
	SELECT
		Name AS track_name,
		CASE
			WHEN Milliseconds < 120000 THEN 'Short'
			WHEN Milliseconds >= 300000 THEN 'Long'
			ELSE 'Medium'
		END AS length_category
	FROM Track
)
SELECT
	length_category,
	COUNT(track_name) AS number_of_tracks
FROM TrackLengths
GROUP BY length_category;
```

**Result:**
<img width="262" height="99" alt="image" src="https://github.com/user-attachments/assets/fefe8af5-12c5-4491-9908-36462ded3b2a" />


**Finding:**
There are 1069 "Long" tracks (over 5 minutes), 2341 "Medium" tracks (between 2 and 5 minutes), and only 93 "Short" tracks (under 2 minutes). The very small proportion of the tracks in the database are "Short", and there are more than double the number of "Medium" tracks than "Long" tracks.

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
HAVING COUNT(Track.TrackId) > 50
ORDER BY number_of_tracks DESC;
```

**Result:**
<img width="257" height="296" alt="image" src="https://github.com/user-attachments/assets/7c439d52-a748-4580-b44f-18fd5dd27eee" />



**Finding:**
There are 11 genres with more than 50 tracks. Rock makes up a very large proportion of the database, having more than twice the number of tracks as Latin, the next most popular genre. There are only 5 genres with more than 100 tracks.

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
ORDER BY invoice_year, invoice_month;
```

**Result:**
<img width="322" height="459" alt="image" src="https://github.com/user-attachments/assets/5c875ac2-10d1-4a58-9239-8160f0288651" />


**Finding:**
Revenue stayed very consistent between January 2009 and December 2013, with most months netting $37.62. It hit a peak of $52.62 in January 2010, and a low of $23.76 in November 2011. This consistency is likely due to the synthetic data being relatively evenly spread across the entire simulated timeline.

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
	CustomerTotals.CustomerId AS customer_id,
	Customer.FirstName AS first_name,
	Customer.LastName AS last_name,
	CustomerTotals.total_spent
FROM CustomerTotals
JOIN Customer ON CustomerTotals.CustomerId = Customer.CustomerId
WHERE total_spent > 40
ORDER BY total_spent DESC;
```

**Result:**
<img width="360" height="369" alt="image" src="https://github.com/user-attachments/assets/859262af-6c3e-404d-b146-d7f3cea41c90" />


**Finding:**
There are 14 customers who have spent more than $40 with the store. With 59 customers overall, this represents just under a 24% of customers so is a good proxy for the top-quarter spenders at the store.

## Biggest spenders per country

**Question:** Who is the top-spending customer in each country?

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
	Customer.Country AS country,
	Customer.CustomerId AS customer_id,
	Customer.FirstName AS first_name,
	Customer.LastName AS last_name,
	CustomerTotals.total_spent,
	RANK() OVER (PARTITION BY Customer.Country ORDER BY CustomerTotals.total_spent DESC) AS spend_rank
FROM CustomerTotals
JOIN Customer ON CustomerTotals.CustomerId = Customer.CustomerId
ORDER BY Customer.Country;
```

**Result:**
<img width="538" height="573" alt="image" src="https://github.com/user-attachments/assets/c9b60a72-96d1-4a77-a35a-9e23fb999ccf" />


**Finding:**
There isn't a very large spread between the total spent of any customer ($36.64 - $49.62), and there is no marked correlation between country and total spend per person. Similarly to the revenue by month, a majority (30/59) of customers have a total spend of $37.62. Again, this is likely due to a very uniform distribution of synthetic data.

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
	Customer.FirstName AS first_name,
	Customer.LastName AS last_name,
	InvoiceExtremes.earliest_invoice,
	InvoiceExtremes.latest_invoice,
	julianday(InvoiceExtremes.latest_invoice) - julianday(InvoiceExtremes.earliest_invoice) AS days_between
FROM InvoiceExtremes
JOIN Customer ON InvoiceExtremes.CustomerId = Customer.CustomerId
ORDER BY days_between DESC;
```

**Result:**
<img width="526" height="573" alt="image" src="https://github.com/user-attachments/assets/fc88e2cb-0ce2-4010-8d05-ef74d15e4367" />


**Finding:**
John Gordon has the longest customer history, with 1788 days between his first and last purchase, but even the shortest customer history, belonging to Puja Srivastava, was 1151 days. Considering the entire length of the dataset is 1826 days, this seems to be another artefact of this synthetic data being more uniformly distributed than real-world data might be.

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
```

**Result:**
<img width="710" height="536" alt="image" src="https://github.com/user-attachments/assets/f9f77606-3b2d-423c-a5b7-190279991b8a" />


**Finding:**
The only two markets with more than 5 customers are Canada and the USA, and all of the customers from those markets are "frequent" purchasers, meaning they have made a purchase on more than 5 separate occasions. However, while some of them have made purchases within the past month, others haven't made one in more than a year. These customers should therefore be treated differently when trying to retain them and incentivise them to make subsequent purchases.

## Skills demonstrated
- Window functions (`RANK() OVER`, `PARTITION BY`) to compare individual customers against peers in the same country without collapsing the data
- CTEs (`WITH`) to chain multi-step logic into readable stages, including CTEs built on top of other CTEs
- `HAVING` to filter groups after aggregation, distinct from `WHERE`
- `CASE WHEN` to bucket customers into behavioural categories
- Date functions (`strftime`, `julianday`) for monthly trends and gap-between-dates calculations
- Deliberately choosing plain aggregation over a window function when the output doesn't need row-level detail, rather than defaulting to the newest tool learned
- Combining all of the above into one query that answers a compound business question, rather than forcing every technique into a single query for its own sake
