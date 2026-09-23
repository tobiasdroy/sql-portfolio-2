SELECT
	strftime('%Y', Invoice.InvoiceDate) AS invoice_year,
	strftime('%m', Invoice.InvoiceDate) AS invoice_month,
	SUM(Invoice.Total) AS total_revenue
FROM Invoice
GROUP BY invoice_year, invoice_month
ORDER BY invoice_year, invoice_month;