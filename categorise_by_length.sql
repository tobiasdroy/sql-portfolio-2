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