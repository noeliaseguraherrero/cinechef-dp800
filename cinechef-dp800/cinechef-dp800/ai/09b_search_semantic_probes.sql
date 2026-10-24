/*==============================================================
  CineChef - Fase 6: sondas SEMÁNTICAS de recetas
  Las sondas de 09_search_evaluation.sql repiten palabras del nombre de
  la receta, así que el Full-Text gana por construcción. Aquí las
  consultas describen una intención (ocasión, dieta, tipo de plato) y
  casi no comparten palabras con los nombres. Cada consulta tiene varias
  recetas aceptables (criterio fijado a mano ANTES de ver resultados;
  se puntúa la primera aceptable que aparece). Solo lectura.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

DROP TABLE IF EXISTS #p, #e, #o, #res;
CREATE TABLE #p (PId INT IDENTITY, Query NVARCHAR(300));
CREATE TABLE #e (PId INT, Expected NVARCHAR(200));
CREATE TABLE #o (Pos INT IDENTITY, RecipeId INT, Name NVARCHAR(200), PrepMin INT, Difficulty NVARCHAR(50),
                 Score DECIMAL(9,6), VectorRank INT, TextRank INT, IngredientRank INT, CosineDistance FLOAT);
CREATE TABLE #res (PId INT, Mode VARCHAR(10), RankPos INT NULL);

INSERT #p (Query) VALUES
 (N'comforting hot meal for a cold rainy evening'),
 (N'healthy plant-based dinner without meat'),
 (N'light seafood dish'),
 (N'something sweet to finish the dinner'),
 (N'easy meal to start the morning'),
 (N'fresh crunchy salad for a hot day'),
 (N'hearty meat dish for a big appetite'),
 (N'spicy food with warm spices');

INSERT #e (PId, Expected) VALUES
 (1, N'Rainy Day Tomato Pasta'), (1, N'Turkey Kale Tomato Soup'), (1, N'Velvet Cauliflower Soup'), (1, N'Creamy Pea and Ham Soup'), (1, N'Rustic Lentil Shepherds Pie'),
 (2, N'Black Bean Corn Tacos'), (2, N'Lentil Carrot Coconut Dal'), (2, N'Garden Quinoa Salad'), (2, N'Golden Coconut Chickpea Curry'), (2, N'Peanut Tofu Lettuce Cups'),
 (3, N'Garlic Mussel Tomato Pot'), (3, N'Tuna Avocado Rice Bowl'), (3, N'Roasted Salmon with Asparagus'), (3, N'Salmon Pea Lemon Cakes'), (3, N'Spicy Tuna Tomato Toasts'), (3, N'Garlic Shrimp Tomato Spaghetti'),
 (4, N'Mango Coconut Rice Pudding'), (4, N'Warm Peach Cinnamon Couscous'),
 (5, N'Berry Yogurt Breakfast Bowl'), (5, N'Cheddar Cornmeal Breakfast Bake'), (5, N'Mozzarella Cherry Tomato Frittata'),
 (6, N'Garden Quinoa Salad'), (6, N'Autumn Pear Walnut Salad'),
 (7, N'Smoky Beef and Bean Chili'), (7, N'Beef Steak with Chimichurri Mood'), (7, N'Rosemary Beef and Mushroom Pie'), (7, N'Rustic Sausage and Cabbage Skillet'), (7, N'Paprika Turkey Meatballs'),
 (8, N'Golden Coconut Chickpea Curry'), (8, N'Lentil Carrot Coconut Dal'), (8, N'Smoky Beef and Bean Chili'), (8, N'Spicy Tuna Tomato Toasts');

SELECT e.PId, e.Expected, N'no existe en el catálogo' AS Aviso
FROM #e AS e WHERE NOT EXISTS (SELECT 1 FROM dbo.Recipes AS r WHERE r.Name = e.Expected);

DECLARE @pid INT, @qry NVARCHAR(300), @mode VARCHAR(10);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT p.PId, p.Query, m.Mode FROM #p AS p CROSS JOIN (VALUES ('vector'), ('text'), ('hybrid')) AS m(Mode);
OPEN cur; FETCH NEXT FROM cur INTO @pid, @qry, @mode;
WHILE @@FETCH_STATUS = 0
BEGIN
    TRUNCATE TABLE #o;
    INSERT #o (RecipeId, Name, PrepMin, Difficulty, Score, VectorRank, TextRank, IngredientRank, CosineDistance)
    EXEC dbo.usp_SearchRecipes @Query = @qry, @Top = 100, @Mode = @mode;
    INSERT #res VALUES (@pid, @mode,
        (SELECT MIN(o.Pos) FROM #o AS o JOIN #e AS e ON e.PId = @pid AND e.Expected = o.Name));
    FETCH NEXT FROM cur INTO @pid, @qry, @mode;
END;
CLOSE cur; DEALLOCATE cur;

SELECT Mode AS Modo, COUNT(*) AS Sondas,
       CAST(AVG(COALESCE(1.0 / RankPos, 0)) AS DECIMAL(5,3)) AS MRR,
       SUM(CASE WHEN RankPos = 1  THEN 1 ELSE 0 END)         AS Top1,
       SUM(CASE WHEN RankPos <= 3 THEN 1 ELSE 0 END)         AS Top3,
       SUM(CASE WHEN RankPos <= 5 THEN 1 ELSE 0 END)         AS Top5,
       SUM(CASE WHEN RankPos IS NULL THEN 1 ELSE 0 END)      AS NoAparece
FROM #res GROUP BY Mode ORDER BY MRR DESC;

SELECT p.PId, p.Query,
       MAX(CASE WHEN r.Mode = 'vector' THEN r.RankPos END) AS vector,
       MAX(CASE WHEN r.Mode = 'text'   THEN r.RankPos END) AS text,
       MAX(CASE WHEN r.Mode = 'hybrid' THEN r.RankPos END) AS hybrid
FROM #p AS p JOIN #res AS r ON r.PId = p.PId GROUP BY p.PId, p.Query ORDER BY p.PId;

DROP TABLE #p, #e, #o, #res;
GO
