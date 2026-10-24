/*==============================================================
  CineChef - Fase 6: pruebas de la búsqueda
  Requiere: 05_generate_embeddings, 07_fulltext, 08_search.
  Falla (THROW) si alguna prueba da REVISAR.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

DROP TABLE IF EXISTS #c, #rm, #rr, #sg;
CREATE TABLE #c  (id INT IDENTITY, prueba NVARCHAR(150), resultado NVARCHAR(10), detalle NVARCHAR(300));
CREATE TABLE #rm (Pos INT IDENTITY, MovieId INT, Title NVARCHAR(200), ReleaseYear INT, MinAge INT,
                  Score DECIMAL(9,6), VectorRank INT, TextRank INT, CosineDistance FLOAT);
CREATE TABLE #rr (Pos INT IDENTITY, RecipeId INT, Name NVARCHAR(200), PrepMin INT, Difficulty NVARCHAR(50),
                  Score DECIMAL(9,6), VectorRank INT, TextRank INT, IngredientRank INT, CosineDistance FLOAT);
CREATE TABLE #sg (Pos INT IDENTITY, RecipeId INT, Name NVARCHAR(200), PrepMin INT, Difficulty NVARCHAR(50), CosineDistance FLOAT);

-- 1. Índices Full-Text
INSERT #c (prueba, resultado, detalle)
SELECT N'Full-Text: Movies, Recipes e Ingredients indexadas',
       IIF(COUNT(*) = 3, N'OK', N'REVISAR'), CONCAT(COUNT(*), N' de 3 tablas')
FROM sys.fulltext_indexes
WHERE object_id IN (OBJECT_ID(N'dbo.Movies'), OBJECT_ID(N'dbo.Recipes'), OBJECT_ID(N'dbo.Ingredients')) AND is_enabled = 1;

-- 2. Búsqueda por significado: la receta esperada queda en el top 3
INSERT #rr (RecipeId, Name, PrepMin, Difficulty, Score, VectorRank, TextRank, IngredientRank, CosineDistance)
EXEC dbo.usp_SearchRecipes @Query = N'chickpea curry with coconut milk', @Top = 3;
INSERT #c (prueba, resultado, detalle)
SELECT N'Recetas híbrida: "chickpea curry with coconut milk" -> Golden Coconut Chickpea Curry en el top 3',
       IIF(EXISTS (SELECT 1 FROM #rr WHERE Name = N'Golden Coconut Chickpea Curry'), N'OK', N'REVISAR'),
       (SELECT STRING_AGG(Name, N' | ') WITHIN GROUP (ORDER BY Pos) FROM #rr);

-- 3. Los tres modos devuelven resultados
DECLARE @modes TABLE (m VARCHAR(10));
INSERT @modes VALUES ('vector'), ('text'), ('hybrid');
DECLARE @m VARCHAR(10), @n INT;
DECLARE cm CURSOR LOCAL FAST_FORWARD FOR SELECT m FROM @modes;
OPEN cm; FETCH NEXT FROM cm INTO @m;
WHILE @@FETCH_STATUS = 0
BEGIN
    TRUNCATE TABLE #rr;
    INSERT #rr (RecipeId, Name, PrepMin, Difficulty, Score, VectorRank, TextRank, IngredientRank, CosineDistance)
    EXEC dbo.usp_SearchRecipes @Query = N'chicken pasta', @Top = 5, @Mode = @m;
    SELECT @n = COUNT(*) FROM #rr;
    INSERT #c (prueba, resultado, detalle)
    VALUES (CONCAT(N'Recetas: modo ', @m, N' devuelve resultados'), IIF(@n > 0, N'OK', N'REVISAR'), CONCAT(@n, N' filas'));
    FETCH NEXT FROM cm INTO @m;
END;
CLOSE cm; DEALLOCATE cm;

-- 4. Seguridad: con el usuario con más alergias, ninguna receta devuelta contiene sus alérgenos
DECLARE @uid INT = (SELECT TOP 1 UserId FROM dbo.vw_UserProfile ORDER BY AllergenCount DESC, UserId);
TRUNCATE TABLE #rr;
INSERT #rr (RecipeId, Name, PrepMin, Difficulty, Score, VectorRank, TextRank, IngredientRank, CosineDistance)
EXEC dbo.usp_SearchRecipes @Query = N'creamy pasta with cheese and nuts', @UserId = @uid, @Top = 100;
DECLARE @tot INT, @unsafe INT;
SELECT @tot = COUNT(*),
       @unsafe = COUNT(*) - COUNT(sf.RecipeId)
FROM #rr AS r LEFT JOIN dbo.fn_SafeRecipes(@uid) AS sf ON sf.RecipeId = r.RecipeId;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Seguridad: la búsqueda solo devuelve recetas seguras para el usuario con más alergias',
        IIF(@tot > 0 AND @unsafe = 0, N'OK', N'REVISAR'),
        CONCAT(N'usuario ', @uid, N': ', @tot, N' recetas devueltas, ', @unsafe, N' no seguras'));

-- 5. Control parental: con el usuario más joven, ninguna película supera su edad
DECLARE @kid INT, @kidAge INT;
SELECT TOP 1 @kid = UserId, @kidAge = Age FROM dbo.vw_UserProfile ORDER BY Age, UserId;
INSERT #rm (MovieId, Title, ReleaseYear, MinAge, Score, VectorRank, TextRank, CosineDistance)
EXEC dbo.usp_SearchMovies @Query = N'violent crime thriller', @UserId = @kid, @Top = 100;
INSERT #c (prueba, resultado, detalle)
SELECT N'Control parental: la búsqueda no devuelve películas por encima de la edad del usuario',
       IIF(COUNT(*) > 0 AND MAX(MinAge) <= @kidAge, N'OK', N'REVISAR'),
       CONCAT(N'usuario ', @kid, N' (', @kidAge, N' años): ', COUNT(*), N' películas, MinAge máx. ', MAX(MinAge))
FROM #rm;

-- 6. Falla cerrado: usuario inexistente => 0 filas
TRUNCATE TABLE #rm; TRUNCATE TABLE #rr;
INSERT #rm (MovieId, Title, ReleaseYear, MinAge, Score, VectorRank, TextRank, CosineDistance)
EXEC dbo.usp_SearchMovies @Query = N'comedy', @UserId = -1;
INSERT #rr (RecipeId, Name, PrepMin, Difficulty, Score, VectorRank, TextRank, IngredientRank, CosineDistance)
EXEC dbo.usp_SearchRecipes @Query = N'soup', @UserId = -1;
INSERT #c (prueba, resultado, detalle)
SELECT N'Usuario inexistente: ambas búsquedas devuelven 0 filas',
       IIF((SELECT COUNT(*) FROM #rm) = 0 AND (SELECT COUNT(*) FROM #rr) = 0, N'OK', N'REVISAR'),
       CONCAT((SELECT COUNT(*) FROM #rm), N' películas, ', (SELECT COUNT(*) FROM #rr), N' recetas');

-- 7. Maridaje: 5 recetas seguras, ordenadas por distancia
DECLARE @mv INT = (SELECT TOP 1 MovieId FROM dbo.fn_AllowedMovies(@uid) ORDER BY MovieId);
INSERT #sg (RecipeId, Name, PrepMin, Difficulty, CosineDistance)
EXEC dbo.usp_SuggestRecipesForMovie @MovieId = @mv, @UserId = @uid, @Top = 5;
SELECT @tot = COUNT(*), @unsafe = COUNT(*) - COUNT(sf.RecipeId)
FROM #sg AS g LEFT JOIN dbo.fn_SafeRecipes(@uid) AS sf ON sf.RecipeId = g.RecipeId;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Maridaje: 5 recetas seguras ordenadas por distancia',
        IIF(@tot = 5 AND @unsafe = 0
            AND NOT EXISTS (SELECT 1 FROM #sg AS a JOIN #sg AS b ON b.Pos = a.Pos + 1 WHERE b.CosineDistance < a.CosineDistance),
            N'OK', N'REVISAR'),
        CONCAT(N'película ', @mv, N', usuario ', @uid, N': ', @tot, N' recetas, ', @unsafe, N' no seguras'));

-- 8. Suplantación: un usuario no puede buscar "como" otro (error 50030)
DECLARE @err INT = 0, @other INT;
IF DATABASE_PRINCIPAL_ID(N'cc_kid') IS NULL
    INSERT #c VALUES (N'Identidad: cc_kid no puede buscar en nombre de otro usuario', N'AVISO', N'cc_kid no existe (ejecuta 09_security.sql)');
ELSE
BEGIN
    SELECT TOP 1 @other = UserId FROM dbo.UserPrincipals WHERE PrincipalName <> N'cc_kid' ORDER BY UserId;
    TRUNCATE TABLE #rr;
    BEGIN TRY
        EXECUTE AS USER = N'cc_kid';
        INSERT #rr (RecipeId, Name, PrepMin, Difficulty, Score, VectorRank, TextRank, IngredientRank, CosineDistance)
        EXEC dbo.usp_SearchRecipes @Query = N'soup', @UserId = @other;
        REVERT;
    END TRY
    BEGIN CATCH
        SET @err = ERROR_NUMBER();
        REVERT;
    END CATCH;
    INSERT #c (prueba, resultado, detalle)
    VALUES (N'Identidad: cc_kid no puede buscar en nombre de otro usuario',
            IIF(@err = 50030, N'OK', N'REVISAR'), CONCAT(N'error obtenido: ', @err));
END;

SELECT prueba, resultado, detalle FROM #c ORDER BY id;

IF EXISTS (SELECT 1 FROM #c WHERE resultado = N'REVISAR')
    THROW 50006, N'Alguna prueba de búsqueda (Fase 6) ha dado REVISAR.', 1;
GO
