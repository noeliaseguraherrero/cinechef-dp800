-- ==============================================================
-- CineChef - Fase 8 (Bloque D): planes de ejecución Q1 y Q2
-- Requiere haber ejecutado performance/12_perf_setup.sql y 13_perf_before_after.sql.
-- ANTES de empezar: Consulta > Incluir plan de ejecución real (Ctrl+M).
-- Ejecuta cada bloque por separado (selecciónalo y pulsa F5) y captura
-- la pestaña "Plan de ejecución" y la pestaña "Mensajes" (lecturas lógicas).
-- Capturas que hay que guardar (docs/evidencias/08_optimizacion/):
-- plan_q1_antes.png   plan_q1_despues.png
-- plan_q2_antes.png   plan_q2_despues.png
-- ==============================================================
USE CineChefDB;
GO

-- PASO 1: fase "antes" (se quitan los índices candidatos)
DROP INDEX IF EXISTS IX_perf_RecipeIngredients_IngredientId ON perf.RecipeIngredients;
DROP INDEX IF EXISTS IX_perf_IngredientAllergens_AllergenId ON perf.IngredientAllergens;
GO

-- COMPROBACION del paso 1 (ejecútala): no debe salir NINGÚN índice que empiece por IX_perf.
-- Si sale alguno, el paso 1 no se ha aplicado y las capturas "antes" saldrían mal.
SELECT OBJECT_NAME(object_id) AS Tabla, name AS Indice
FROM sys.indexes
WHERE name LIKE N'IX[_]perf%' AND object_id IN (OBJECT_ID(N'perf.RecipeIngredients'), OBJECT_ID(N'perf.IngredientAllergens'));
GO

-- PASO 2: Q1 ANTES  (captura: plan_q1_antes.png)
-- Esperado: Clustered Index Scan sobre perf.RecipeIngredients.
SET STATISTICS IO ON;
DECLARE @i INT = (SELECT IngredientId FROM dbo.Ingredients ORDER BY IngredientId OFFSET 50 ROWS FETCH NEXT 1 ROWS ONLY);
SELECT TOP (20) r.RecipeId, r.Name
FROM perf.RecipeIngredients AS ri JOIN perf.Recipes AS r ON r.RecipeId = ri.RecipeId
WHERE ri.IngredientId = @i ORDER BY r.RecipeId;
SET STATISTICS IO OFF;
GO

-- PASO 3: Q2 ANTES  (captura: plan_q2_antes.png)
-- Esperado: recorrido completo de perf.RecipeIngredients (unas 1 859 lecturas).
SET STATISTICS IO ON;
DECLARE @a INT = (SELECT AllergenId FROM dbo.Allergens WHERE Name = N'Gluten');
SELECT COUNT(DISTINCT ri.RecipeId) AS RecetasConAlergeno
FROM perf.RecipeIngredients AS ri
WHERE ri.IngredientId IN (SELECT ia.IngredientId FROM perf.IngredientAllergens AS ia WHERE ia.AllergenId = @a);
SET STATISTICS IO OFF;
GO

-- PASO 4: fase "después" (se crean los índices)
CREATE INDEX IX_perf_RecipeIngredients_IngredientId ON perf.RecipeIngredients (IngredientId);
CREATE INDEX IX_perf_IngredientAllergens_AllergenId ON perf.IngredientAllergens (AllergenId);
GO

-- PASO 5: Q1 DESPUÉS  (captura: plan_q1_despues.png)
-- Esperado: Index Seek sobre IX_perf_RecipeIngredients_IngredientId (o un recorrido
-- ordenado de la clave primaria que se detiene en 20 filas: ver docs/optimizacion.md).
SET STATISTICS IO ON;
DECLARE @i INT = (SELECT IngredientId FROM dbo.Ingredients ORDER BY IngredientId OFFSET 50 ROWS FETCH NEXT 1 ROWS ONLY);
SELECT TOP (20) r.RecipeId, r.Name
FROM perf.RecipeIngredients AS ri JOIN perf.Recipes AS r ON r.RecipeId = ri.RecipeId
WHERE ri.IngredientId = @i ORDER BY r.RecipeId;
SET STATISTICS IO OFF;
GO

-- PASO 6: Q2 DESPUÉS  (captura: plan_q2_despues.png)
-- Esperado: Index Seek sobre el índice nuevo (unas 113 lecturas).
SET STATISTICS IO ON;
DECLARE @a INT = (SELECT AllergenId FROM dbo.Allergens WHERE Name = N'Gluten');
SELECT COUNT(DISTINCT ri.RecipeId) AS RecetasConAlergeno
FROM perf.RecipeIngredients AS ri
WHERE ri.IngredientId IN (SELECT ia.IngredientId FROM perf.IngredientAllergens AS ia WHERE ia.AllergenId = @a);
SET STATISTICS IO OFF;
GO
