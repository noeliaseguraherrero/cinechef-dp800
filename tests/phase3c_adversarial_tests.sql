/*==============================================================
  CineChef - Fase 3 (parte 3): pruebas adversarias de B-07
  Casos que intentan romper el trigger y los procedimientos:
    A. Receta sin ingredientes (error 50015).
    B. Valoración NULL: se acepta y el trigger la audita (4 -> NULL).
    C. UPDATE de varias filas: el trigger audita una fila por plan cambiado.
    D. Valoración 0 (error 50020).
    E. Plan inexistente (error 50021).
  No cubre la concurrencia (necesita dos sesiones a la vez).
  Se ejecuta como administrador (dbo). Crea datos de prueba con
  'TEST' y los borra al final. Falla (THROW) si alguna prueba da REVISAR.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

DROP TABLE IF EXISTS #c;   -- permite repetir el script en la misma sesión tras un fallo
CREATE TABLE #c (id INT IDENTITY, prueba NVARCHAR(140), resultado NVARCHAR(10), detalle NVARCHAR(200));

DECLARE @alice  INT = (SELECT UserId FROM dbo.Users WHERE UserName = N'Alice Carter');
DECLARE @movie  INT = (SELECT TOP 1 MovieId FROM dbo.Movies WHERE MinAge = 0 ORDER BY MovieId);
DECLARE @recipe INT = (SELECT TOP 1 RecipeId FROM dbo.fn_SafeRecipes(@alice) ORDER BY RecipeId);
DECLARE @err INT, @n INT, @night INT, @x INT, @emptyRecipe INT;
DECLARE @nightsBefore INT = (SELECT COUNT(*) FROM dbo.MovieNights);
DECLARE @recipesBefore INT = (SELECT COUNT(*) FROM dbo.Recipes);

-- A. Receta sin ingredientes: el procedimiento debe rechazarla con 50015
INSERT dbo.Recipes (Name, Description, PrepMin, Difficulty, Servings)
VALUES (N'TEST recipe without ingredients', N'TEST recipe used to check that a recipe with no ingredients is rejected.', 10, 1, 2);
SET @emptyRecipe = SCOPE_IDENTITY();

SET @err = NULL;
BEGIN TRY
    EXEC dbo.usp_RegisterMovieNight @UserId = @alice, @MovieId = @movie, @RecipeId = @emptyRecipe,
                                    @Vibe = N'TEST vibe A', @NightId = @x OUTPUT;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
INSERT #c (prueba, resultado, detalle)
VALUES (N'A. Receta sin ingredientes se rechaza (50015)', IIF(@err = 50015, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

SELECT @n = COUNT(*) FROM dbo.MovieNights WHERE Vibe = N'TEST vibe A';
INSERT #c (prueba, resultado, detalle)
VALUES (N'A. El rechazo no deja ningún plan registrado', IIF(@n = 0, N'OK', N'REVISAR'), CONCAT(@n, N' filas'));

-- B. Valoración NULL: se acepta y el trigger registra 4 -> NULL
EXEC dbo.usp_RegisterMovieNight @UserId = @alice, @MovieId = @movie, @RecipeId = @recipe,
                                @Vibe = N'TEST vibe B', @NightId = @night OUTPUT;
EXEC dbo.usp_RateMovieNight @NightId = @night, @UserId = @alice, @Rating = 4;
SET @err = NULL;
BEGIN TRY
    EXEC dbo.usp_RateMovieNight @NightId = @night, @UserId = @alice, @Rating = NULL;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
SELECT @n = COUNT(*) FROM dbo.MovieNightRatingAudit WHERE NightId = @night AND OldRating = 4 AND NewRating IS NULL;
INSERT #c (prueba, resultado, detalle)
VALUES (N'B. Valoración NULL aceptada y auditada (4 -> NULL)',
        IIF(@err IS NULL AND @n = 1 AND (SELECT Rating FROM dbo.MovieNights WHERE NightId = @night) IS NULL, N'OK', N'REVISAR'),
        CONCAT(N'error=', @err, N', filas de auditoría=', @n));

-- C. UPDATE de varias filas con un solo comando: una fila de auditoría por plan
INSERT dbo.MovieNights (UserId, MovieId, RecipeId, Vibe)
VALUES (@alice, @movie, @recipe, N'TEST vibe C1'), (@alice, @movie, @recipe, N'TEST vibe C2'), (@alice, @movie, @recipe, N'TEST vibe C3');
UPDATE dbo.MovieNights SET Rating = 5 WHERE Vibe LIKE N'TEST vibe C%';
SELECT @n = COUNT(*) FROM dbo.MovieNightRatingAudit AS a
JOIN dbo.MovieNights AS m ON m.NightId = a.NightId
WHERE m.Vibe LIKE N'TEST vibe C%' AND a.OldRating IS NULL AND a.NewRating = 5;
INSERT #c (prueba, resultado, detalle)
VALUES (N'C. UPDATE de 3 filas genera 3 filas de auditoría', IIF(@n = 3, N'OK', N'REVISAR'), CONCAT(@n, N' filas de auditoría'));

-- D. Valoración 0: fuera de rango
SET @err = NULL;
BEGIN TRY
    EXEC dbo.usp_RateMovieNight @NightId = @night, @UserId = @alice, @Rating = 0;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
INSERT #c (prueba, resultado, detalle)
VALUES (N'D. Valoración 0 rechazada (50020)', IIF(@err = 50020, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

-- E. Plan inexistente
SET @err = NULL;
BEGIN TRY
    EXEC dbo.usp_RateMovieNight @NightId = 2147483000, @UserId = @alice, @Rating = 3;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
INSERT #c (prueba, resultado, detalle)
VALUES (N'E. Plan inexistente rechazado (50021)', IIF(@err = 50021, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

-- Limpieza de los datos de prueba
DELETE a FROM dbo.MovieNightRatingAudit AS a JOIN dbo.MovieNights AS m ON m.NightId = a.NightId WHERE m.Vibe LIKE N'TEST vibe%';
DELETE FROM dbo.MovieNights WHERE Vibe LIKE N'TEST vibe%';
DELETE FROM dbo.Recipes WHERE RecipeId = @emptyRecipe;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Limpieza: MovieNights y Recipes vuelven a su tamaño inicial',
        IIF((SELECT COUNT(*) FROM dbo.MovieNights) = @nightsBefore AND (SELECT COUNT(*) FROM dbo.Recipes) = @recipesBefore, N'OK', N'REVISAR'),
        CONCAT((SELECT COUNT(*) FROM dbo.MovieNights), N' planes, ', (SELECT COUNT(*) FROM dbo.Recipes), N' recetas'));

SELECT prueba, resultado, detalle FROM #c ORDER BY id;

IF EXISTS (SELECT 1 FROM #c WHERE resultado <> N'OK')
    THROW 50003, N'Alguna prueba adversaria de la Fase 3 ha dado REVISAR.', 1;

DROP TABLE #c;
GO
