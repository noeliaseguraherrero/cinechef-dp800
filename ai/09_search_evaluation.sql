/*==============================================================
  CineChef - Fase 6: evaluación de la búsqueda (vector vs texto vs híbrida)
  Usa los propios procedimientos usp_SearchRecipes / usp_SearchMovies con
  @Top = 100 y mide en qué posición aparece la respuesta esperada.
  Solo lectura. Las sondas cuyo elemento no exista en el catálogo se
  listan y se descartan.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

DROP TABLE IF EXISTS #p, #oR, #oM, #res;
CREATE TABLE #p (PId INT IDENTITY, Kind CHAR(1), Query NVARCHAR(300), Expected NVARCHAR(200), ExpectedId INT NULL);
CREATE TABLE #oR (Pos INT IDENTITY, RecipeId INT, Name NVARCHAR(200), PrepMin INT, Difficulty NVARCHAR(50),
                  Score DECIMAL(9,6), VectorRank INT, TextRank INT, IngredientRank INT, CosineDistance FLOAT);
CREATE TABLE #oM (Pos INT IDENTITY, MovieId INT, Title NVARCHAR(200), ReleaseYear INT, MinAge INT,
                  Score DECIMAL(9,6), VectorRank INT, TextRank INT, CosineDistance FLOAT);
CREATE TABLE #res (PId INT, Kind CHAR(1), Mode VARCHAR(10), RankPos INT NULL);

-- Recetas (nombre exacto) y películas (patrón LIKE sobre el título)
INSERT #p (Kind, Query, Expected) VALUES
 ('R', N'chickpea curry with coconut milk',          N'Golden Coconut Chickpea Curry'),
 ('R', N'creamy pasta with chicken and mushrooms',   N'Creamy Chicken Mushroom Pasta'),
 ('R', N'spaghetti with garlic shrimp and tomato',   N'Garlic Shrimp Tomato Spaghetti'),
 ('R', N'mexican tacos with beans and corn',         N'Black Bean Corn Tacos'),
 ('R', N'vegetarian lentil pie',                     N'Rustic Lentil Shepherds Pie'),
 ('R', N'spicy chili with beef and beans',           N'Smoky Beef and Bean Chili'),
 ('R', N'light breakfast with yogurt and berries',   N'Berry Yogurt Breakfast Bowl'),
 ('R', N'smooth cauliflower soup',                   N'Velvet Cauliflower Soup'),
 ('R', N'mussels cooked in tomato sauce',            N'Garlic Mussel Tomato Pot'),
 ('R', N'pork with apples and rosemary',             N'Rosemary Pork with Apples'),
 ('R', N'sweet rice dessert with mango and coconut', N'Mango Coconut Rice Pudding'),
 ('R', N'baked salmon with asparagus',               N'Roasted Salmon with Asparagus'),
 ('R', N'bell peppers stuffed with quinoa',          N'Quinoa Stuffed Bell Peppers'),
 ('R', N'rice bowl with tuna and avocado',           N'Tuna Avocado Rice Bowl'),
 ('R', N'roasted cauliflower with tahini',           N'Roasted Cauliflower Tahini Plate'),
 ('R', N'peanut tofu in lettuce wraps',              N'Peanut Tofu Lettuce Cups'),
 ('R', N'salmon and pea cakes with lemon',           N'Salmon Pea Lemon Cakes'),
 ('R', N'turkey meatballs with paprika',             N'Paprika Turkey Meatballs'),
 ('R', N'salad with pear and walnuts',               N'Autumn Pear Walnut Salad'),
 ('R', N'tortilla folded with spinach and feta',     N'Spinach Feta Tortilla Fold'),
 ('M', N'a boy befriends a friendly alien and helps him go home', N'E.T.%'),
 ('M', N'an insomniac office worker starts an underground fight club', N'Fight Club'),
 ('M', N'an elderly professor reflects on his life during a road trip', N'Wild Strawberries'),
 ('M', N'a giant shark terrorizes a beach town',     N'Jaws'),
 ('M', N'mafia patriarch hands his empire to a reluctant son', N'The Godfather'),
 ('M', N'toys come alive when humans are not around', N'Toy Story'),
 ('M', N'a hacker discovers reality is a computer simulation', N'The Matrix'),
 ('M', N'a luxury ship hits an iceberg and a love story unfolds', N'Titanic');

UPDATE p SET ExpectedId = (SELECT TOP 1 r.RecipeId FROM dbo.Recipes AS r WHERE r.Name = p.Expected)
FROM #p AS p WHERE p.Kind = 'R';
UPDATE p SET ExpectedId = (SELECT TOP 1 m.MovieId FROM dbo.Movies AS m WHERE m.Title LIKE p.Expected ORDER BY m.MovieId)
FROM #p AS p WHERE p.Kind = 'M';

SELECT Kind, Query, Expected, N'no existe en el catálogo: se descarta' AS Aviso FROM #p WHERE ExpectedId IS NULL;

DECLARE @pid INT, @kind CHAR(1), @qry NVARCHAR(300), @id INT, @mode VARCHAR(10);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT p.PId, p.Kind, p.Query, p.ExpectedId, m.Mode
    FROM #p AS p CROSS JOIN (VALUES ('vector'), ('text'), ('hybrid')) AS m(Mode)
    WHERE p.ExpectedId IS NOT NULL;
OPEN cur; FETCH NEXT FROM cur INTO @pid, @kind, @qry, @id, @mode;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF @kind = 'R'
    BEGIN
        TRUNCATE TABLE #oR;
        INSERT #oR (RecipeId, Name, PrepMin, Difficulty, Score, VectorRank, TextRank, IngredientRank, CosineDistance)
        EXEC dbo.usp_SearchRecipes @Query = @qry, @Top = 100, @Mode = @mode;
        INSERT #res VALUES (@pid, @kind, @mode, (SELECT Pos FROM #oR WHERE RecipeId = @id));
    END
    ELSE
    BEGIN
        TRUNCATE TABLE #oM;
        INSERT #oM (MovieId, Title, ReleaseYear, MinAge, Score, VectorRank, TextRank, CosineDistance)
        EXEC dbo.usp_SearchMovies @Query = @qry, @Top = 100, @Mode = @mode;
        INSERT #res VALUES (@pid, @kind, @mode, (SELECT Pos FROM #oM WHERE MovieId = @id));
    END;
    FETCH NEXT FROM cur INTO @pid, @kind, @qry, @id, @mode;
END;
CLOSE cur; DEALLOCATE cur;

-- Resumen (RankPos NULL = no aparece en el top 100 => cuenta 0 en MRR)
SELECT CASE Kind WHEN 'R' THEN N'recetas' ELSE N'películas' END AS Tipo, Mode AS Modo,
       COUNT(*)                                                     AS Sondas,
       CAST(AVG(COALESCE(1.0 / RankPos, 0)) AS DECIMAL(5,3))        AS MRR,
       SUM(CASE WHEN RankPos = 1  THEN 1 ELSE 0 END)                AS Top1,
       SUM(CASE WHEN RankPos <= 5 THEN 1 ELSE 0 END)                AS Top5,
       SUM(CASE WHEN RankPos <= 10 THEN 1 ELSE 0 END)               AS Top10,
       SUM(CASE WHEN RankPos IS NULL THEN 1 ELSE 0 END)             AS NoAparece
FROM #res GROUP BY Kind, Mode ORDER BY Kind DESC, MRR DESC;

-- Detalle por sonda
SELECT p.PId, p.Kind, p.Query, p.Expected,
       MAX(CASE WHEN r.Mode = 'vector' THEN r.RankPos END) AS vector,
       MAX(CASE WHEN r.Mode = 'text'   THEN r.RankPos END) AS text,
       MAX(CASE WHEN r.Mode = 'hybrid' THEN r.RankPos END) AS hybrid
FROM #p AS p JOIN #res AS r ON r.PId = p.PId
GROUP BY p.PId, p.Kind, p.Query, p.Expected ORDER BY p.PId;

DROP TABLE #p, #oR, #oM, #res;
GO
