/*==============================================================
  CineChef - Fase 8 (Bloque D): datos sintéticos para medir rendimiento
  El catálogo real tiene 500 filas en RecipeIngredients: cabe en unas
  pocas páginas y cualquier plan es "rápido". Para que las diferencias
  de plan se vean, se crea el esquema perf con una copia ESTRUCTURAL
  (mismas claves primarias, sin índices secundarios) y datos generados:
    perf.Recipes             100 000 recetas sintéticas
    perf.RecipeIngredients   500 000 filas (5 ingredientes por receta,
                             usando los 120 ingredientes reales)
    perf.IngredientAllergens y perf.UserAllergies: copia de las reales
  No toca las tablas reales. Repetible (borra y recrea perf.*).
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

IF SCHEMA_ID(N'perf') IS NULL EXEC (N'CREATE SCHEMA perf');
GO
DROP TABLE IF EXISTS perf.RecipeIngredients, perf.Recipes, perf.IngredientAllergens, perf.UserAllergies;

CREATE TABLE perf.Recipes (
    RecipeId INT           NOT NULL CONSTRAINT PK_perf_Recipes PRIMARY KEY,
    Name     NVARCHAR(100) NOT NULL,
    PrepMin  INT           NOT NULL
);
CREATE TABLE perf.RecipeIngredients (
    RecipeId     INT NOT NULL,
    IngredientId INT NOT NULL,
    CONSTRAINT PK_perf_RecipeIngredients PRIMARY KEY (RecipeId, IngredientId)
);
CREATE TABLE perf.IngredientAllergens (
    IngredientId INT NOT NULL,
    AllergenId   INT NOT NULL,
    CONSTRAINT PK_perf_IngredientAllergens PRIMARY KEY (IngredientId, AllergenId)
);
CREATE TABLE perf.UserAllergies (
    UserId     INT NOT NULL,
    AllergenId INT NOT NULL,
    CONSTRAINT PK_perf_UserAllergies PRIMARY KEY (UserId, AllergenId)
);

DECLARE @n INT = 100000;

INSERT perf.Recipes (RecipeId, Name, PrepMin)
SELECT g.value, CONCAT(N'Synthetic recipe ', g.value), 10 + g.value % 90
FROM GENERATE_SERIES(1, @n) AS g;

SELECT ROW_NUMBER() OVER (ORDER BY IngredientId) - 1 AS idx, IngredientId
INTO #ing FROM dbo.Ingredients;
DECLARE @m INT = (SELECT COUNT(*) FROM #ing);

-- 5 ingredientes distintos por receta (23 y @m son coprimos, así que no se repiten dentro de la receta)
INSERT perf.RecipeIngredients (RecipeId, IngredientId)
SELECT r.value, i.IngredientId
FROM GENERATE_SERIES(1, @n) AS r
CROSS JOIN GENERATE_SERIES(0, 4) AS k
JOIN #ing AS i ON i.idx = (CAST(r.value AS BIGINT) * 37 + k.value * 23) % @m;

INSERT perf.IngredientAllergens (IngredientId, AllergenId) SELECT IngredientId, AllergenId FROM dbo.IngredientAllergens;
INSERT perf.UserAllergies       (UserId, AllergenId)       SELECT UserId, AllergenId       FROM dbo.UserAllergies;

UPDATE STATISTICS perf.Recipes WITH FULLSCAN;
UPDATE STATISTICS perf.RecipeIngredients WITH FULLSCAN;
DROP TABLE #ing;

SELECT t.name AS tabla, SUM(ps.row_count) AS filas, CAST(SUM(ps.used_page_count) * 8 / 1024.0 AS DECIMAL(9,1)) AS MB
FROM sys.dm_db_partition_stats AS ps
JOIN sys.tables AS t ON t.object_id = ps.object_id
WHERE SCHEMA_NAME(t.schema_id) = N'perf' AND ps.index_id IN (0, 1)
GROUP BY t.name ORDER BY t.name;
GO
