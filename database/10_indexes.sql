/*==============================================================
  CineChef - Fase 8: índices de optimización en el catálogo real
  Solo se crea el índice que la medición de 13_perf_before_after.sql
  justifica. Repetible.

  Creado:
    IX_RecipeIngredients_IngredientId
        La PK es (RecipeId, IngredientId): sirve para "ingredientes de una
        receta", pero no para "recetas que contienen un ingrediente"
        (búsqueda Full-Text de ingredientes, filtros por alérgeno), que
        obliga a recorrer toda la tabla. En perf pasa de escaneo a seek.

  Evaluados y NO creados (sin beneficio medible):
    IngredientAllergens(AllergenId)  tabla de ~40 filas: una sola página
    UserAllergies(AllergenId)        ~10 filas
    Q3 (patrón fn_SafeRecipes)       ya usa la PK de RecipeIngredients por RecipeId
==============================================================*/
USE CineChefDB;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_RecipeIngredients_IngredientId' AND object_id = OBJECT_ID(N'dbo.RecipeIngredients'))
    CREATE INDEX IX_RecipeIngredients_IngredientId ON dbo.RecipeIngredients (IngredientId);
GO
