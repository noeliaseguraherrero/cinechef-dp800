/*==============================================================
  CineChef - Fase 3: funciones (Bloque A)
  Son funciones en línea (inline TVF): el optimizador las expande
  dentro de la consulta que las llama, sin coste de función escalar.
  Requieren que exista dbo.vw_UserProfile (04_views.sql).
==============================================================*/
USE CineChefDB;
GO

/*--------------------------------------------------------------
  fn_SafeRecipes(@UserId)
  Recetas que no contienen ningún alérgeno del usuario.

  Falla "cerrado" en dos casos:
  - Usuario inexistente: devuelve 0 filas, no todo el catálogo (sin la
    comprobación EXISTS parecería un usuario sin alergias).
  - Receta sin ingredientes registrados: no se devuelve, porque "sin
    alérgenos registrados" no equivale a "comprobada como segura".
    (Hallazgo de la revisión B-06.)

  NOTA PARA LA FASE 4 (RLS): esta función lee dbo.UserAllergies con
  los permisos de quien la llama. Si se activa Row-Level Security y el
  llamante no ve las filas de alergias del usuario, la función las
  interpretaría como "sin alergias" y devolvería recetas peligrosas.
  Por eso se ejecutará siempre en un contexto que vea esas filas (el
  propio usuario o un procedimiento con EXECUTE AS).
--------------------------------------------------------------*/
CREATE OR ALTER FUNCTION dbo.fn_SafeRecipes (@UserId INT)
RETURNS TABLE
AS
RETURN
(
    SELECT  r.RecipeId, r.Name, r.Description, r.PrepMin, r.Difficulty, r.Servings
    FROM dbo.Recipes AS r
    WHERE EXISTS (SELECT 1 FROM dbo.Users AS u WHERE u.UserId = @UserId)
      AND EXISTS (SELECT 1 FROM dbo.RecipeIngredients AS r0 WHERE r0.RecipeId = r.RecipeId)
      AND NOT EXISTS (
            SELECT 1
            FROM dbo.RecipeIngredients   AS ri
            JOIN dbo.IngredientAllergens AS ia ON ia.IngredientId = ri.IngredientId
            JOIN dbo.UserAllergies       AS ua ON ua.AllergenId   = ia.AllergenId
                                              AND ua.UserId       = @UserId
            WHERE ri.RecipeId = r.RecipeId)
);
GO

/*--------------------------------------------------------------
  fn_AllowedMovies(@UserId)
  Películas cuya edad mínima no supera la edad del usuario
  (control parental). Usuario inexistente: 0 filas.
--------------------------------------------------------------*/
CREATE OR ALTER FUNCTION dbo.fn_AllowedMovies (@UserId INT)
RETURNS TABLE
AS
RETURN
(
    SELECT  m.MovieId, m.Title, m.ReleaseYear, m.RuntimeMin, m.MinAge, m.Synopsis
    FROM dbo.vw_UserProfile AS u
    JOIN dbo.Movies         AS m ON m.MinAge <= u.Age
    WHERE u.UserId = @UserId
);
GO