/*==============================================================
  CineChef - Fase 3: vistas (Bloque A)
  Todas usan CREATE OR ALTER, así que el script se puede repetir.
==============================================================*/
USE CineChefDB;
GO

/*--------------------------------------------------------------
  vw_RecipeAllergens
  Alérgenos de cada receta, calculados a partir de sus ingredientes.
--------------------------------------------------------------*/
CREATE OR ALTER VIEW dbo.vw_RecipeAllergens
AS
SELECT  r.RecipeId,
        r.Name                          AS RecipeName,
        COALESCE(a.Allergens, N'None')  AS Allergens,
        COALESCE(a.AllergenCount, 0)    AS AllergenCount
FROM dbo.Recipes AS r
OUTER APPLY (
    SELECT  STRING_AGG(d.Name, N', ') WITHIN GROUP (ORDER BY d.Name) AS Allergens,
            COUNT(*)                                                  AS AllergenCount
    FROM (
        SELECT DISTINCT al.Name
        FROM dbo.RecipeIngredients   AS ri
        JOIN dbo.IngredientAllergens AS ia ON ia.IngredientId = ri.IngredientId
        JOIN dbo.Allergens           AS al ON al.AllergenId   = ia.AllergenId
        WHERE ri.RecipeId = r.RecipeId
    ) AS d
) AS a;
GO

/*--------------------------------------------------------------
  vw_MovieSearchText
  Texto que se convertirá en embedding para las películas:
  géneros + sinopsis (Fase 5).
--------------------------------------------------------------*/
CREATE OR ALTER VIEW dbo.vw_MovieSearchText
AS
SELECT  m.MovieId,
        m.Title,
        m.ReleaseYear,
        m.MinAge,
        g.Genres,
        CONCAT(N'Genres: ', g.Genres, N'. ', m.Synopsis) AS SearchText
FROM dbo.Movies AS m
OUTER APPLY (
    SELECT STRING_AGG(gn.Name, N', ') WITHIN GROUP (ORDER BY gn.Name) AS Genres
    FROM dbo.MovieGenres AS mg
    JOIN dbo.Genres      AS gn ON gn.GenreId = mg.GenreId
    WHERE mg.MovieId = m.MovieId
) AS g;
GO

/*--------------------------------------------------------------
  vw_RecipeSearchText
  Texto que se convertirá en embedding para las recetas:
  descripción + lista de ingredientes (Fase 5).
--------------------------------------------------------------*/
CREATE OR ALTER VIEW dbo.vw_RecipeSearchText
AS
SELECT  r.RecipeId,
        r.Name,
        i.Ingredients,
        CONCAT(r.Description, N' Ingredients: ', i.Ingredients) AS SearchText
FROM dbo.Recipes AS r
OUTER APPLY (
    SELECT STRING_AGG(ing.Name, N', ') WITHIN GROUP (ORDER BY ing.Name) AS Ingredients
    FROM dbo.RecipeIngredients AS ri
    JOIN dbo.Ingredients       AS ing ON ing.IngredientId = ri.IngredientId
    WHERE ri.RecipeId = r.RecipeId
) AS i;
GO

/*--------------------------------------------------------------
  vw_UserProfile
  Perfil mínimo de un usuario: edad calculada y alergias.
  Por mínimo privilegio NO expone Email ni BirthDate.
  La edad tiene en cuenta si ya ha cumplido años este año
  (DATEDIFF(YEAR, ...) por sí solo cuenta cambios de año natural).
--------------------------------------------------------------*/
CREATE OR ALTER VIEW dbo.vw_UserProfile
AS
SELECT  u.UserId,
        u.UserName,
        DATEDIFF(YEAR, u.BirthDate, CAST(GETDATE() AS DATE))
          - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, u.BirthDate, CAST(GETDATE() AS DATE)), u.BirthDate)
                      > CAST(GETDATE() AS DATE)
                 THEN 1 ELSE 0 END              AS Age,
        COALESCE(a.Allergens, N'None')          AS Allergens,
        COALESCE(a.AllergenCount, 0)            AS AllergenCount
FROM dbo.Users AS u
OUTER APPLY (
    SELECT  STRING_AGG(al.Name, N', ') WITHIN GROUP (ORDER BY al.Name) AS Allergens,
            COUNT(*)                                                   AS AllergenCount
    FROM dbo.UserAllergies AS ua
    JOIN dbo.Allergens     AS al ON al.AllergenId = ua.AllergenId
    WHERE ua.UserId = u.UserId
) AS a;
GO
