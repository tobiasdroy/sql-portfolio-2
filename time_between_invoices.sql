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