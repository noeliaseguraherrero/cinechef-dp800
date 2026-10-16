/*==============================================================
  CineChef - Fase 3: consultas T-SQL avanzadas (Bloque A)
  Consultas de solo lectura. Ejecutar de una en una y hacer captura.
  Cada una indica qué elemento del temario demuestra.
==============================================================*/
USE CineChefDB;
GO

/*-- Q1. CTE + ROW_NUMBER() OVER (PARTITION BY ...)
      Las 2 películas más recientes de cada género. --*/
WITH MoviesByGenre AS (
    SELECT g.Name AS Genre, m.Title, m.ReleaseYear,
           ROW_NUMBER() OVER (PARTITION BY g.GenreId
                              ORDER BY m.ReleaseYear DESC, m.Title) AS rn
    FROM dbo.Genres      AS g
    JOIN dbo.MovieGenres AS mg ON mg.GenreId = g.GenreId
    JOIN dbo.Movies      AS m  ON m.MovieId  = mg.MovieId
)
SELECT Genre, rn AS Position, Title, ReleaseYear
FROM MoviesByGenre
WHERE rn <= 2
ORDER BY Genre, rn;
GO

/*-- Q2a. LAG y media acumulada (ventana con ROWS)
       Historial de cada usuario: valoración anterior y media móvil. --*/
SELECT u.UserName, n.NightId, m.Title, n.Rating,
       LAG(n.Rating) OVER (PARTITION BY n.UserId ORDER BY n.PlannedAt, n.NightId) AS PreviousRating,
       AVG(CAST(n.Rating AS DECIMAL(4,2)))
           OVER (PARTITION BY n.UserId ORDER BY n.PlannedAt, n.NightId
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)                 AS RunningAvgRating
FROM dbo.MovieNights AS n
JOIN dbo.Users  AS u ON u.UserId  = n.UserId
JOIN dbo.Movies AS m ON m.MovieId = n.MovieId
ORDER BY u.UserName, n.PlannedAt, n.NightId;
GO

/*-- Q2b. DENSE_RANK sobre una agregación
       Ranking de películas por valoración media (solo planes valorados). --*/
SELECT m.Title,
       COUNT(*)                                       AS RatedNights,
       AVG(CAST(n.Rating AS DECIMAL(4,2)))            AS AvgRating,
       DENSE_RANK() OVER (ORDER BY AVG(CAST(n.Rating AS DECIMAL(4,2))) DESC) AS RankPosition
FROM dbo.MovieNights AS n
JOIN dbo.Movies AS m ON m.MovieId = n.MovieId
WHERE n.Rating IS NOT NULL
GROUP BY m.MovieId, m.Title
ORDER BY RankPosition, m.Title;
GO

/*-- Q3. CTE recursiva
       Histograma de películas por década, incluyendo décadas sin películas.
       (La recursión no admite subconsultas, por eso se usan variables.) --*/
DECLARE @minY INT = (SELECT MIN(ReleaseYear) FROM dbo.Movies);
DECLARE @maxY INT = (SELECT MAX(ReleaseYear) FROM dbo.Movies);

WITH Decades AS (
    SELECT (@minY / 10) * 10 AS DecadeStart
    UNION ALL
    SELECT DecadeStart + 10 FROM Decades WHERE DecadeStart + 10 <= @maxY
)
SELECT d.DecadeStart, COUNT(m.MovieId) AS Movies
FROM Decades AS d
LEFT JOIN dbo.Movies AS m ON m.ReleaseYear >= d.DecadeStart AND m.ReleaseYear < d.DecadeStart + 10
GROUP BY d.DecadeStart
ORDER BY d.DecadeStart;
GO

/*-- Q4a. JSON de salida: FOR JSON PATH con array anidado (JSON_QUERY)
       Las 3 recetas más rápidas y seguras para un usuario, con sus ingredientes. --*/
DECLARE @uid INT = (SELECT UserId FROM dbo.Users WHERE UserName = N'Isaac Brown');

SELECT TOP (3)
       r.RecipeId, r.Name, r.PrepMin, r.Difficulty,
       JSON_QUERY((SELECT i.Name AS ingredient
                   FROM dbo.RecipeIngredients AS ri
                   JOIN dbo.Ingredients       AS i ON i.IngredientId = ri.IngredientId
                   WHERE ri.RecipeId = r.RecipeId
                   ORDER BY i.Name
                   FOR JSON PATH)) AS ingredients
FROM dbo.fn_SafeRecipes(@uid) AS r
ORDER BY r.PrepMin, r.Name
FOR JSON PATH, ROOT('safeRecipes');
GO

/*-- Q4b. JSON de entrada: JSON_VALUE y OPENJSON
       Las preferencias llegan como documento JSON (así las enviaría una aplicación). --*/
DECLARE @prefs NVARCHAR(MAX) = N'{"maxMinutes": 45, "avoid": ["Gluten", "Milk"]}';
DECLARE @maxMin INT = CAST(JSON_VALUE(@prefs, '$.maxMinutes') AS INT);

SELECT r.RecipeId, r.Name, r.PrepMin
FROM dbo.Recipes AS r
WHERE r.PrepMin <= @maxMin
  AND EXISTS (SELECT 1 FROM dbo.RecipeIngredients AS r0 WHERE r0.RecipeId = r.RecipeId)
  AND NOT EXISTS (
        SELECT 1
        FROM dbo.RecipeIngredients   AS ri
        JOIN dbo.IngredientAllergens AS ia ON ia.IngredientId = ri.IngredientId
        JOIN dbo.Allergens           AS a  ON a.AllergenId    = ia.AllergenId
        JOIN OPENJSON(@prefs, '$.avoid') AS j ON j.[value] = a.Name
        WHERE ri.RecipeId = r.RecipeId)
ORDER BY r.PrepMin, r.Name;
GO

/*-- Q5a. Expresiones regulares: REGEXP_LIKE
       Películas cuyo título empieza por un artículo (The / A / An). --*/
SELECT Title
FROM dbo.Movies
WHERE REGEXP_LIKE(Title, N'^(The|A|An)\s')
ORDER BY Title;
GO

/*-- Q5b. REGEXP_REPLACE
       Título de ordenación sin el artículo inicial. --*/
SELECT TOP (15) Title,
       REGEXP_REPLACE(Title, N'^(The|A|An)\s+', N'') AS SortTitle
FROM dbo.Movies
WHERE REGEXP_LIKE(Title, N'^(The|A|An)\s')
ORDER BY SortTitle;
GO

/*-- Q5c. Regex como control de calidad de datos
       Descripciones de receta que NO terminan en signo de puntuación (esperado: 0 filas). --*/
SELECT RecipeId, Name
FROM dbo.Recipes
WHERE NOT REGEXP_LIKE(Description, N'[.!?]$');
GO

/*-- Q6. Subconsulta correlacionada
       Películas más largas que la media de su misma década. --*/
SELECT m.Title, m.ReleaseYear, m.RuntimeMin,
       (SELECT AVG(CAST(m2.RuntimeMin AS FLOAT))
        FROM dbo.Movies AS m2
        WHERE m2.ReleaseYear / 10 = m.ReleaseYear / 10) AS DecadeAvgRuntime
FROM dbo.Movies AS m
WHERE m.RuntimeMin > (SELECT AVG(CAST(m2.RuntimeMin AS FLOAT))
                      FROM dbo.Movies AS m2
                      WHERE m2.ReleaseYear / 10 = m.ReleaseYear / 10)
ORDER BY m.ReleaseYear, m.Title;
GO

/*-- Q7. Fuzzy string matching (usa el procedimiento usp_FindMovieByTitle)
       Búsqueda con erratas. --*/
EXEC dbo.usp_FindMovieByTitle @SearchTitle = N'fight clob';
EXEC dbo.usp_FindMovieByTitle @SearchTitle = N'wild strawberies';
GO
