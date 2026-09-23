SELECT
	Genre.Name AS genre_name,
	COUNT(Track.TrackId) AS number_of_tracks
FROM Track
JOIN Genre ON Track.GenreId = Genre.GenreId
GROUP BY Genre.GenreId
HAVING COUNT(Track.TrackId) > 50
ORDER BY number_of_tracks DESC;