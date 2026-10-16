/*==============================================================
  CineChef - Fase 3 (parte 2): pruebas de trigger y procedimientos
  Las pruebas crean planes de prueba con Vibe 'TEST vibe...' y los
  borran al final (junto con sus filas de auditoría).
  Falla (THROW) si alguna prueba da REVISAR.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

CREATE TABLE #c (id INT IDENTITY, prueba NVARCHAR(140), resultado NVARCHAR(10), detalle NVARCHAR(200));

DECLARE @alice  INT = (SELECT UserId FROM dbo.Users WHERE UserName = N'Alice Carter');
DECLARE @isaac  INT = (SELECT UserId FROM dbo.Users WHERE UserName = N'Isaac Brown');
DECLARE @kid    INT = (SELECT TOP 1 UserId FROM dbo.vw_UserProfile ORDER BY Age, UserId);
DECLARE @movieAny INT = (SELECT TOP 1 MovieId FROM dbo.Movies WHERE MinAge = 0  ORDER BY MovieId);
DECLARE @movie18  INT = (SELECT TOP 1 MovieId FROM dbo.Movies WHERE MinAge = 18 ORDER BY MovieId);
DECLARE @safeRecipe   INT = (SELECT TOP 1 RecipeId FROM dbo.fn_SafeRecipes(@alice) ORDER BY RecipeId);
DECLARE @glutenRecipe INT = (SELECT TOP 1 RecipeId FROM dbo.vw_RecipeAllergens WHERE Allergens LIKE N'%Gluten%' ORDER BY RecipeId);
DECLARE @night INT, @err INT, @n INT;

-- 1. usp_RegisterMovieNight: caso correcto
BEGIN TRY
    EXEC dbo.usp_RegisterMovieNight @UserId = @alice, @MovieId = @movieAny, @RecipeId = @safeRecipe,
                                    @Vibe = N'TEST vibe', @NightId = @night OUTPUT;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT #c (prueba, resultado, detalle)
VALUES (N'usp_RegisterMovieNight: plan válido se registra',
        IIF(@night IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.MovieNights
                                           WHERE NightId = @night AND UserId = @alice AND Vibe = N'TEST vibe'),
            N'OK', N'REVISAR'),
        CONCAT(N'NightId=', @night, N', error=', @err));

-- 2. Errores esperados de usp_RegisterMovieNight
SET @err = NULL;
BEGIN TRY
    DECLARE @x INT;
    EXEC dbo.usp_RegisterMovieNight @UserId = -1, @MovieId = @movieAny, @RecipeId = @safeRecipe,
                                    @Vibe = N'TEST vibe error', @NightId = @x OUTPUT;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
INSERT #c (prueba, resultado, detalle)
VALUES (N'usp_RegisterMovieNight: usuario inexistente (50010)', IIF(@err = 50010, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

SET @err = NULL;
BEGIN TRY
    EXEC dbo.usp_RegisterMovieNight @UserId = @kid, @MovieId = @movie18, @RecipeId = @safeRecipe,
                                    @Vibe = N'TEST vibe error', @NightId = @x OUTPUT;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
INSERT #c (prueba, resultado, detalle)
VALUES (N'usp_RegisterMovieNight: menor con película de 18 (50013)', IIF(@err = 50013, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

SET @err = NULL;
BEGIN TRY
    EXEC dbo.usp_RegisterMovieNight @UserId = @isaac, @MovieId = @movieAny, @RecipeId = @glutenRecipe,
                                    @Vibe = N'TEST vibe error', @NightId = @x OUTPUT;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
INSERT #c (prueba, resultado, detalle)
VALUES (N'usp_RegisterMovieNight: receta con alérgeno del usuario (50014)', IIF(@err = 50014, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

-- 3. Los errores no dejan filas (la transacción se deshace)
SELECT @n = COUNT(*) FROM dbo.MovieNights WHERE Vibe = N'TEST vibe error';
INSERT #c (prueba, resultado, detalle)
VALUES (N'usp_RegisterMovieNight: los errores no dejan filas', IIF(@n = 0, N'OK', N'REVISAR'), CONCAT(@n, N' filas de error'));

-- 4. usp_RateMovieNight + trigger de auditoría
EXEC dbo.usp_RateMovieNight @NightId = @night, @UserId = @alice, @Rating = 4;
EXEC dbo.usp_RateMovieNight @NightId = @night, @UserId = @alice, @Rating = 5;
INSERT #c (prueba, resultado, detalle)
SELECT N'Trigger: NULL->4 y 4->5 registrados en la auditoría',
       IIF((SELECT COUNT(*) FROM dbo.MovieNightRatingAudit WHERE NightId = @night AND OldRating IS NULL AND NewRating = 4) = 1
       AND (SELECT COUNT(*) FROM dbo.MovieNightRatingAudit WHERE NightId = @night AND OldRating = 4    AND NewRating = 5) = 1,
           N'OK', N'REVISAR'),
       CONCAT((SELECT COUNT(*) FROM dbo.MovieNightRatingAudit WHERE NightId = @night), N' filas de auditoría');

-- 5. El trigger no audita cambios que no tocan la valoración
UPDATE dbo.MovieNights SET Vibe = N'TEST vibe 2' WHERE NightId = @night;
SELECT @n = COUNT(*) FROM dbo.MovieNightRatingAudit WHERE NightId = @night;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Trigger: cambiar otra columna no genera auditoría', IIF(@n = 2, N'OK', N'REVISAR'), CONCAT(@n, N' filas (esperado 2)'));

-- 6. Errores esperados de usp_RateMovieNight
SET @err = NULL;
BEGIN TRY EXEC dbo.usp_RateMovieNight @NightId = @night, @UserId = @alice, @Rating = 6; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
INSERT #c (prueba, resultado, detalle)
VALUES (N'usp_RateMovieNight: valoración 6 rechazada (50020)', IIF(@err = 50020, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

SET @err = NULL;
BEGIN TRY EXEC dbo.usp_RateMovieNight @NightId = @night, @UserId = @isaac, @Rating = 1; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
INSERT #c (prueba, resultado, detalle)
VALUES (N'usp_RateMovieNight: otro usuario no puede valorar (50021)', IIF(@err = 50021, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

-- 7. Búsqueda difusa: la película esperada debe ser el primer resultado
CREATE TABLE #f (MovieId INT, Title NVARCHAR(200), ReleaseYear SMALLINT, EditDistance INT, JaroWinklerDistance FLOAT);
DECLARE @fz TABLE (n INT IDENTITY(1,1), q NVARCHAR(200), esperado NVARCHAR(200));
INSERT @fz (q, esperado) VALUES (N'Rashomom', N'Rashomon'), (N'fight clob', N'Fight Club'),
                                (N'moonlite', N'Moonlight'), (N'wild strawberies', N'Wild Strawberries');
DECLARE @i INT = 1, @q NVARCHAR(200), @exp NVARCHAR(200), @top NVARCHAR(200);
WHILE @i <= (SELECT COUNT(*) FROM @fz)
BEGIN
    SELECT @q = q, @exp = esperado FROM @fz WHERE n = @i;
    DELETE #f;
    INSERT #f EXEC dbo.usp_FindMovieByTitle @SearchTitle = @q, @Top = 3;
    SET @top = (SELECT TOP 1 Title FROM #f ORDER BY JaroWinklerDistance, EditDistance);
    INSERT #c (prueba, resultado, detalle)
    VALUES (CONCAT(N'usp_FindMovieByTitle: "', @q, N'"'), IIF(@top = @exp, N'OK', N'REVISAR'),
            CONCAT(N'esperado ', @exp, N', obtenido ', @top));
    SET @i += 1;
END;

DELETE #f;
INSERT #f EXEC dbo.usp_FindMovieByTitle @SearchTitle = N'zzzzqqqq';
SELECT @n = COUNT(*) FROM #f;
INSERT #c (prueba, resultado, detalle)
VALUES (N'usp_FindMovieByTitle: texto sin parecido no devuelve nada', IIF(@n = 0, N'OK', N'REVISAR'), CONCAT(@n, N' filas'));
DROP TABLE #f;

-- 8. Consulta Q3 (CTE recursiva): el histograma por década suma las 100 películas
DECLARE @minY INT = (SELECT MIN(ReleaseYear) FROM dbo.Movies), @maxY INT = (SELECT MAX(ReleaseYear) FROM dbo.Movies), @tot INT;
WITH Decades AS (
    SELECT (@minY / 10) * 10 AS DecadeStart
    UNION ALL
    SELECT DecadeStart + 10 FROM Decades WHERE DecadeStart + 10 <= @maxY
), H AS (
    SELECT COUNT(m.MovieId) AS c
    FROM Decades AS d
    LEFT JOIN dbo.Movies AS m ON m.ReleaseYear >= d.DecadeStart AND m.ReleaseYear < d.DecadeStart + 10
    GROUP BY d.DecadeStart
)
SELECT @tot = SUM(c) FROM H;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Q3 (CTE recursiva): el histograma suma 100 películas', IIF(@tot = 100, N'OK', N'REVISAR'), CONCAT(@tot, N' películas'));

-- 9. Limpieza de los datos de prueba
DELETE a FROM dbo.MovieNightRatingAudit AS a JOIN dbo.MovieNights AS n ON n.NightId = a.NightId WHERE n.Vibe LIKE N'TEST vibe%';
DELETE FROM dbo.MovieNights WHERE Vibe LIKE N'TEST vibe%';
SELECT @n = COUNT(*) FROM dbo.MovieNights;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Limpieza: MovieNights vuelve a tener 30 filas', IIF(@n = 30, N'OK', N'REVISAR'), CONCAT(@n, N' filas'));

SELECT prueba, resultado, detalle FROM #c ORDER BY id;

IF EXISTS (SELECT 1 FROM #c WHERE resultado <> N'OK')
    THROW 50003, N'Alguna prueba de la Fase 3 (parte 2) ha dado REVISAR.', 1;

DROP TABLE #c;
GO
