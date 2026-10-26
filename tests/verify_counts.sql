/*==============================================================
  CineChef - Verificación de conteos tras la carga completa
  Compara el número de filas de cada tabla con el esperado.
  Falla (THROW) si algún conteo no coincide.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

SELECT t.tabla, t.esperado, t.actual,
       CASE WHEN t.esperado = t.actual THEN N'OK' ELSE N'REVISAR' END AS estado
INTO #resultado
FROM (VALUES
  (N'Genres',              18,  (SELECT COUNT(*) FROM dbo.Genres)),
  (N'Allergens',           14,  (SELECT COUNT(*) FROM dbo.Allergens)),
  (N'Ingredients',        120,  (SELECT COUNT(*) FROM dbo.Ingredients)),
  (N'IngredientAllergens', 39,  (SELECT COUNT(*) FROM dbo.IngredientAllergens)),
  (N'Recipes',            100,  (SELECT COUNT(*) FROM dbo.Recipes)),
  (N'RecipeIngredients',  500,  (SELECT COUNT(*) FROM dbo.RecipeIngredients)),
  (N'Movies',             100,  (SELECT COUNT(*) FROM dbo.Movies)),
  (N'MovieGenres',        233,  (SELECT COUNT(*) FROM dbo.MovieGenres)),
  (N'Users',               10,  (SELECT COUNT(*) FROM dbo.Users)),
  (N'UserAllergies',        9,  (SELECT COUNT(*) FROM dbo.UserAllergies)),
  (N'MovieNights',         30,  (SELECT COUNT(*) FROM dbo.MovieNights))
) t(tabla, esperado, actual);

SELECT tabla, esperado, actual, estado FROM #resultado;

IF EXISTS (SELECT 1 FROM #resultado WHERE estado <> N'OK')
    THROW 50001, N'Algún conteo no coincide con el esperado. Revisa la carga.', 1;

DROP TABLE #resultado;
GO
