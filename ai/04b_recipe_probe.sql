/*==============================================================
  CineChef - Fase 5 (complemento): experimento de sondas con RECETAS
  El experimento 04 solo probó películas. Aquí se repite la
  comparación de variantes (labeled / unlabeled / bare) con recetas.
  No modifica dbo.Recipes: todo va a tablas temporales.
  Tarda ~2-3 min (genera 2 variantes x 100 recetas).
  labeled   = Description + ' Ingredients: ...'  (la guardada en dbo.Recipes)
  unlabeled = Description + ' ' + lista de ingredientes
  bare      = solo Description
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

DROP TABLE IF EXISTS #emb, #q;
CREATE TABLE #emb (Variant VARCHAR(10), RecipeId INT, Name NVARCHAR(200), Txt NVARCHAR(MAX), Emb VECTOR(384) NULL);

INSERT #emb (Variant, RecipeId, Name, Txt, Emb)
SELECT 'labeled', r.RecipeId, r.Name, NULL, r.Embedding FROM dbo.Recipes AS r;

INSERT #emb (Variant, RecipeId, Name, Txt)
SELECT 'unlabeled', r.RecipeId, r.Name, CONCAT(r.Description, N' ', s.Ingredients)
FROM dbo.Recipes AS r JOIN dbo.vw_RecipeSearchText AS s ON s.RecipeId = r.RecipeId;

INSERT #emb (Variant, RecipeId, Name, Txt)
SELECT 'bare', r.RecipeId, r.Name, r.Description FROM dbo.Recipes AS r;

UPDATE #emb SET Emb = AI_GENERATE_EMBEDDINGS(Txt USE MODEL CineChefEmbeddingModel) WHERE Variant <> 'labeled';

/* Sondas: consulta en lenguaje natural (inglés) + receta(s) que debería encontrar */
CREATE TABLE #q (QId INT IDENTITY, Query NVARCHAR(200), Expected NVARCHAR(200), QEmb VECTOR(384) NULL);
INSERT #q (Query, Expected) VALUES
 (N'chickpea curry with coconut milk',            N'Golden Coconut Chickpea Curry'),
 (N'creamy pasta with chicken and mushrooms',     N'Creamy Chicken Mushroom Pasta'),
 (N'spaghetti with garlic shrimp and tomato',     N'Garlic Shrimp Tomato Spaghetti'),
 (N'mexican tacos with beans and corn',           N'Black Bean Corn Tacos'),
 (N'vegetarian lentil pie',                       N'Rustic Lentil Shepherds Pie'),
 (N'spicy chili with beef and beans',             N'Smoky Beef and Bean Chili'),
 (N'light breakfast with yogurt and berries',     N'Berry Yogurt Breakfast Bowl'),
 (N'smooth cauliflower soup',                     N'Velvet Cauliflower Soup'),
 (N'mussels cooked in tomato sauce',              N'Garlic Mussel Tomato Pot'),
 (N'pork with apples and rosemary',               N'Rosemary Pork with Apples'),
 (N'sweet rice dessert with mango and coconut',   N'Mango Coconut Rice Pudding'),
 (N'baked salmon with asparagus',                 N'Roasted Salmon with Asparagus'),
 (N'bell peppers stuffed with quinoa',            N'Quinoa Stuffed Bell Peppers'),
 (N'rice bowl with tuna and avocado',             N'Tuna Avocado Rice Bowl'),
 (N'roasted cauliflower with tahini',             N'Roasted Cauliflower Tahini Plate'),
 (N'peanut tofu in lettuce wraps',                N'Peanut Tofu Lettuce Cups'),
 (N'salmon and pea cakes with lemon',             N'Salmon Pea Lemon Cakes'),
 (N'turkey meatballs with paprika',               N'Paprika Turkey Meatballs'),
 (N'salad with pear and walnuts',                 N'Autumn Pear Walnut Salad'),
 (N'tortilla folded with spinach and feta',       N'Spinach Feta Tortilla Fold');

UPDATE #q SET QEmb = AI_GENERATE_EMBEDDINGS(Query USE MODEL CineChefEmbeddingModel);

-- 0. Comprobación: todas las recetas esperadas existen (si falta alguna, cambia el nombre en #q)
SELECT q.Query, q.Expected, N'NO EXISTE' AS Aviso
FROM #q AS q WHERE NOT EXISTS (SELECT 1 FROM dbo.Recipes AS r WHERE r.Name = q.Expected);

-- 1. Posición de la receta esperada para cada sonda y variante
SELECT Variant, QId, Query, Expected, RankPos
INTO #res
FROM (
    SELECT e.Variant, q.QId, q.Query, q.Expected, e.Name,
           RANK() OVER (PARTITION BY e.Variant, q.QId
                        ORDER BY VECTOR_DISTANCE('cosine', e.Emb, q.QEmb)) AS RankPos
    FROM #emb AS e CROSS JOIN #q AS q
) AS x
WHERE x.Name = x.Expected;

-- 2. Resumen por variante: MRR, aciertos en 1.ª posición y en el top 5
SELECT Variant,
       COUNT(*)                                            AS Probes,
       CAST(AVG(1.0 / RankPos) AS DECIMAL(5,3))            AS MRR,
       SUM(CASE WHEN RankPos = 1 THEN 1 ELSE 0 END)        AS Top1,
       SUM(CASE WHEN RankPos <= 5 THEN 1 ELSE 0 END)       AS Top5
FROM #res GROUP BY Variant ORDER BY MRR DESC;

-- 3. Detalle (para el informe y para ver qué sondas fallan)
SELECT QId, Query, Expected,
       MAX(CASE WHEN Variant = 'labeled'   THEN RankPos END) AS labeled,
       MAX(CASE WHEN Variant = 'unlabeled' THEN RankPos END) AS unlabeled,
       MAX(CASE WHEN Variant = 'bare'      THEN RankPos END) AS bare
FROM #res GROUP BY QId, Query, Expected ORDER BY QId;

DROP TABLE #res, #emb, #q;
GO
