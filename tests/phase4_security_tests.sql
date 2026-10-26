/*==============================================================
  CineChef - Fase 4: pruebas de seguridad
  Cada prueba se ejecuta suplantando a un usuario (EXECUTE AS USER)
  y se compara con lo que ve el administrador.
  Los resultados se guardan en variables y se insertan en #c tras
  REVERT, porque un usuario suplantado puede no tener acceso a #c.
  Falla (THROW) si alguna prueba da REVISAR.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

DROP TABLE IF EXISTS #c;   -- permite repetir el script en la misma sesión tras un fallo
CREATE TABLE #c (id INT IDENTITY, prueba NVARCHAR(150), resultado NVARCHAR(10), detalle NVARCHAR(200));

/*-------- Datos de referencia leídos como administrador --------*/
DECLARE @isaac INT = (SELECT UserId FROM dbo.UserPrincipals WHERE PrincipalName = N'cc_isaac');
DECLARE @alice INT = (SELECT UserId FROM dbo.UserPrincipals WHERE PrincipalName = N'cc_alice');
DECLARE @kid   INT = (SELECT UserId FROM dbo.UserPrincipals WHERE PrincipalName = N'cc_kid');
DECLARE @totalUsers     INT = (SELECT COUNT(*) FROM dbo.Users);
DECLARE @totalAllergies INT = (SELECT COUNT(*) FROM dbo.UserAllergies);
DECLARE @isaacAllergies INT = (SELECT COUNT(*) FROM dbo.UserAllergies WHERE UserId = @isaac);
DECLARE @isaacNights    INT = (SELECT COUNT(*) FROM dbo.MovieNights   WHERE UserId = @isaac);
DECLARE @aliceNights    INT = (SELECT COUNT(*) FROM dbo.MovieNights   WHERE UserId = @alice);
DECLARE @isaacEmail NVARCHAR(256) = (SELECT Email FROM dbo.Users WHERE UserId = @isaac);
DECLARE @bornBefore90 INT = (SELECT COUNT(*) FROM dbo.Users WHERE BirthDate < '1990-01-01');
DECLARE @totalMovies INT = (SELECT COUNT(*) FROM dbo.Movies);
DECLARE @movieAny INT = (SELECT TOP 1 MovieId FROM dbo.Movies WHERE MinAge = 0  ORDER BY MovieId);
DECLARE @movie18  INT = (SELECT TOP 1 MovieId FROM dbo.Movies WHERE MinAge = 18 ORDER BY MovieId);
DECLARE @safeRecipe   INT = (SELECT TOP 1 RecipeId FROM dbo.fn_SafeRecipes(@alice) ORDER BY RecipeId);
DECLARE @glutenRecipe INT = (SELECT TOP 1 RecipeId FROM dbo.vw_RecipeAllergens WHERE Allergens LIKE N'%Gluten%' ORDER BY RecipeId);

DECLARE @a INT, @b INT, @c INT, @d INT, @g INT, @err INT, @night INT, @n INT;
DECLARE @mail NVARCHAR(256), @bd DATE;

/*==================== 1. cc_isaac (cliente con alergias) ====================*/
EXECUTE AS USER = N'cc_isaac';
    SELECT @a = COUNT(*) FROM dbo.Users;
    SELECT @b = COUNT(*) FROM dbo.UserAllergies;
    SELECT @c = COUNT(*) FROM dbo.MovieNights;
    SELECT @d = COUNT(*) FROM dbo.fn_SafeRecipes(@isaac);
    SELECT @g = COUNT(*) FROM dbo.fn_SafeRecipes(@alice);
    SELECT @mail = Email FROM dbo.Users WHERE UserId = @isaac;
REVERT;
INSERT #c (prueba, resultado, detalle) VALUES
 (N'RLS cc_isaac: solo ve su fila en Users',        IIF(@a = 1, N'OK', N'REVISAR'), CONCAT(@a, N' filas')),
 (N'RLS cc_isaac: solo ve sus alergias',            IIF(@b = @isaacAllergies AND @b > 0, N'OK', N'REVISAR'), CONCAT(@b, N' filas, esperado ', @isaacAllergies)),
 (N'RLS cc_isaac: solo ve sus planes',              IIF(@c = @isaacNights, N'OK', N'REVISAR'), CONCAT(@c, N' filas, esperado ', @isaacNights)),
 (N'fn_SafeRecipes cc_isaac con su id: 42 recetas', IIF(@d = 42, N'OK', N'REVISAR'), CONCAT(@d, N' recetas')),
 (N'fn_SafeRecipes cc_isaac con el id de otra persona: 0 (falla cerrado)', IIF(@g = 0, N'OK', N'REVISAR'), CONCAT(@g, N' recetas')),
 (N'DDM cc_isaac: ve su propio email sin máscara',  IIF(@mail = @isaacEmail, N'OK', N'REVISAR'), @mail);

/*==================== 2. cc_alice (cliente sin alergias) ====================*/
EXECUTE AS USER = N'cc_alice';
    SELECT @a = COUNT(*) FROM dbo.Users;
    SELECT @b = COUNT(*) FROM dbo.UserAllergies;
    SELECT @c = COUNT(*) FROM dbo.MovieNights;
REVERT;
INSERT #c (prueba, resultado, detalle) VALUES
 (N'RLS cc_alice: solo ve su fila en Users',   IIF(@a = 1, N'OK', N'REVISAR'), CONCAT(@a, N' filas')),
 (N'RLS cc_alice: sin alergias, 0 filas',      IIF(@b = 0, N'OK', N'REVISAR'), CONCAT(@b, N' filas')),
 (N'RLS cc_alice: solo ve sus planes',         IIF(@c = @aliceNights, N'OK', N'REVISAR'), CONCAT(@c, N' filas, esperado ', @aliceNights));

/*==================== 3. cc_nutri (nutricionista) ====================*/
SET @err = NULL;
EXECUTE AS USER = N'cc_nutri';
    SELECT @a = COUNT(*) FROM dbo.Users;
    SELECT @b = COUNT(*) FROM dbo.UserAllergies;
    SELECT @mail = Email, @bd = BirthDate FROM dbo.Users WHERE UserId = @isaac;
    SELECT @g = COUNT(*) FROM dbo.Users WHERE BirthDate < '1990-01-01';
    BEGIN TRY SELECT @c = COUNT(*) FROM dbo.MovieNights; END TRY
    BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
REVERT;
INSERT #c (prueba, resultado, detalle) VALUES
 (N'RLS cc_nutri: ve todos los usuarios',     IIF(@a = @totalUsers, N'OK', N'REVISAR'), CONCAT(@a, N' de ', @totalUsers)),
 (N'RLS cc_nutri: ve todas las alergias',     IIF(@b = @totalAllergies, N'OK', N'REVISAR'), CONCAT(@b, N' de ', @totalAllergies)),
 (N'DDM cc_nutri: el email sale enmascarado', IIF(@mail <> @isaacEmail, N'OK', N'REVISAR'), @mail),
 (N'DDM cc_nutri: la fecha de nacimiento sale como 1900-01-01', IIF(@bd = CAST('1900-01-01' AS DATE), N'OK', N'REVISAR'), CONVERT(NVARCHAR(10), @bd)),
 (N'DDM cc_nutri: LIMITACIÓN, puede filtrar por la fecha enmascarada', IIF(@g = @bornBefore90, N'OK', N'REVISAR'), CONCAT(@g, N' usuarios nacidos antes de 1990 (el valor real)')),
 (N'Permisos cc_nutri: MovieNights denegada (229)', IIF(@err = 229, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

/*==================== 4. cc_analyst (analista) ====================*/
DECLARE @e1 INT, @e2 INT, @e3 INT, @e4 INT, @e5 INT, @movies INT, @statRows INT, @minGroup INT;
DECLARE @gs TABLE (Genre NVARCHAR(50), Nights INT, RatedNights INT, AvgRating DECIMAL(4,2));
EXECUTE AS USER = N'cc_analyst';
    BEGIN TRY SELECT @n = COUNT(*) FROM dbo.Users;         END TRY BEGIN CATCH SET @e1 = ERROR_NUMBER(); END CATCH;
    BEGIN TRY SELECT @n = COUNT(*) FROM dbo.UserAllergies; END TRY BEGIN CATCH SET @e2 = ERROR_NUMBER(); END CATCH;
    BEGIN TRY SELECT @n = COUNT(*) FROM dbo.MovieNights;   END TRY BEGIN CATCH SET @e3 = ERROR_NUMBER(); END CATCH;
    BEGIN TRY SELECT @n = COUNT(*) FROM dbo.fn_SafeRecipes(@isaac); END TRY BEGIN CATCH SET @e4 = ERROR_NUMBER(); END CATCH;
    BEGIN TRY EXEC dbo.usp_RegisterMovieNight @UserId = @isaac, @MovieId = @movieAny, @RecipeId = @safeRecipe,
                                              @Vibe = N'TEST sec analyst', @NightId = @night OUTPUT;
    END TRY BEGIN CATCH SET @e5 = ERROR_NUMBER(); END CATCH;
    SELECT @movies = COUNT(*) FROM dbo.Movies;
    INSERT @gs EXEC dbo.usp_GenreRatingStats;
    SELECT @statRows = COUNT(*) FROM @gs;
    SELECT @minGroup = MIN(RatedNights) FROM @gs;
REVERT;
INSERT #c (prueba, resultado, detalle) VALUES
 (N'Permisos cc_analyst: Users denegada (229)',         IIF(@e1 = 229, N'OK', N'REVISAR'), CONCAT(N'error=', @e1)),
 (N'Permisos cc_analyst: UserAllergies denegada (229)', IIF(@e2 = 229, N'OK', N'REVISAR'), CONCAT(N'error=', @e2)),
 (N'Permisos cc_analyst: MovieNights denegada (229)',   IIF(@e3 = 229, N'OK', N'REVISAR'), CONCAT(N'error=', @e3)),
 (N'Permisos cc_analyst: fn_SafeRecipes sin permiso (229)', IIF(@e4 = 229, N'OK', N'REVISAR'), CONCAT(N'error=', @e4)),
 (N'Permisos cc_analyst: no puede registrar planes (229)',  IIF(@e5 = 229, N'OK', N'REVISAR'), CONCAT(N'error=', @e5)),
 (N'Permisos cc_analyst: lee el catálogo completo',     IIF(@movies = @totalMovies, N'OK', N'REVISAR'), CONCAT(@movies, N' películas')),
 (N'EXECUTE AS OWNER: cc_analyst obtiene estadísticas agregadas', IIF(@statRows > 0, N'OK', N'AVISO'), CONCAT(@statRows, N' géneros con datos (si es 0, con tan pocos planes ningún género alcanza el umbral: baja @MinRatedNights en 09_security.sql)')),
 (N'Estadísticas: ningún género con menos de 3 valoraciones', IIF(ISNULL(@minGroup, 3) >= 3, N'OK', N'REVISAR'), CONCAT(N'grupo mínimo: ', @minGroup));

/*==================== 5. Escritura: solo mediante procedimientos ====================*/
-- 5a. INSERT directo denegado
SET @err = NULL;
EXECUTE AS USER = N'cc_alice';
    BEGIN TRY
        INSERT dbo.MovieNights (UserId, MovieId, RecipeId, Vibe) VALUES (@alice, @movieAny, @safeRecipe, N'TEST sec direct');
    END TRY
    BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
REVERT;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Permisos cc_alice: INSERT directo en MovieNights denegado (229)', IIF(@err = 229, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

-- 5b. Registrar un plan propio mediante el procedimiento
SET @err = NULL; SET @night = NULL;
EXECUTE AS USER = N'cc_alice';
    BEGIN TRY
        EXEC dbo.usp_RegisterMovieNight @UserId = @alice, @MovieId = @movieAny, @RecipeId = @safeRecipe,
                                        @Vibe = N'TEST sec', @NightId = @night OUTPUT;
    END TRY
    BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
REVERT;
INSERT #c (prueba, resultado, detalle)
VALUES (N'usp_RegisterMovieNight: cc_alice registra su plan',
        IIF(@night IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.MovieNights WHERE NightId = @night AND UserId = @alice), N'OK', N'REVISAR'),
        CONCAT(N'NightId=', @night, N', error=', @err));

-- 5c. Intentar registrar un plan en nombre de otra persona (hallazgo 4 de B-06)
SET @err = NULL;
EXECUTE AS USER = N'cc_alice';
    BEGIN TRY
        EXEC dbo.usp_RegisterMovieNight @UserId = @isaac, @MovieId = @movieAny, @RecipeId = @safeRecipe,
                                        @Vibe = N'TEST sec spoof', @NightId = @n OUTPUT;
    END TRY
    BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
REVERT;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Identidad: cc_alice no puede registrar planes como Isaac (50030)', IIF(@err = 50030, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

-- 5d. Receta con gluten para una persona alérgica al gluten
SET @err = NULL;
EXECUTE AS USER = N'cc_isaac';
    BEGIN TRY
        EXEC dbo.usp_RegisterMovieNight @UserId = @isaac, @MovieId = @movieAny, @RecipeId = @glutenRecipe,
                                        @Vibe = N'TEST sec gluten', @NightId = @n OUTPUT;
    END TRY
    BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
REVERT;
INSERT #c (prueba, resultado, detalle)
VALUES (N'usp_RegisterMovieNight: cc_isaac con receta con gluten (50014)', IIF(@err = 50014, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

-- 5e. Control parental: menor con película de 18
SET @err = NULL;
EXECUTE AS USER = N'cc_kid';
    BEGIN TRY
        EXEC dbo.usp_RegisterMovieNight @UserId = @kid, @MovieId = @movie18, @RecipeId = @safeRecipe,
                                        @Vibe = N'TEST sec kid', @NightId = @n OUTPUT;
    END TRY
    BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
REVERT;
INSERT #c (prueba, resultado, detalle)
VALUES (N'usp_RegisterMovieNight: cc_kid con película de 18 (50013)', IIF(@err = 50013, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

-- 5f. Valorar: el propio plan sí; el de otra persona no
SET @err = NULL;
EXECUTE AS USER = N'cc_alice';
    BEGIN TRY EXEC dbo.usp_RateMovieNight @NightId = @night, @UserId = @alice, @Rating = 4; END TRY
    BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
REVERT;
INSERT #c (prueba, resultado, detalle)
VALUES (N'usp_RateMovieNight: cc_alice valora su plan',
        IIF(@err IS NULL AND (SELECT Rating FROM dbo.MovieNights WHERE NightId = @night) = 4, N'OK', N'REVISAR'),
        CONCAT(N'error=', @err));

-- La auditoría atribuye el cambio a quien actúa (hallazgo propio de la sección J de la demo)
DECLARE @auditUser SYSNAME = (SELECT TOP 1 ChangedBy FROM dbo.MovieNightRatingAudit WHERE NightId = @night AND NewRating = 4 ORDER BY AuditId DESC);
INSERT #c (prueba, resultado, detalle)
VALUES (N'Auditoría: el cambio de valoración se atribuye a cc_alice (no al inicio de sesión original)',
        IIF(@auditUser = N'cc_alice', N'OK', N'REVISAR'), CONCAT(N'ChangedBy=', @auditUser));

SET @err = NULL;
EXECUTE AS USER = N'cc_isaac';
    BEGIN TRY EXEC dbo.usp_RateMovieNight @NightId = @night, @UserId = @isaac, @Rating = 1; END TRY
    BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
REVERT;
INSERT #c (prueba, resultado, detalle)
VALUES (N'usp_RateMovieNight: cc_isaac no puede valorar el plan de Alice (50021)', IIF(@err = 50021, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

SET @err = NULL;
EXECUTE AS USER = N'cc_isaac';
    BEGIN TRY EXEC dbo.usp_RateMovieNight @NightId = @night, @UserId = @alice, @Rating = 1; END TRY
    BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
REVERT;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Identidad: cc_isaac no puede valorar haciéndose pasar por Alice (50030)', IIF(@err = 50030, N'OK', N'REVISAR'), CONCAT(N'error=', @err));

/*==================== 6. Estado de los mecanismos ====================*/
INSERT #c (prueba, resultado, detalle)
SELECT N'DDM: 2 columnas enmascaradas en Users (Email y BirthDate)',
       IIF(COUNT(*) = 2, N'OK', N'REVISAR'), CONCAT(COUNT(*), N' columnas')
FROM sys.masked_columns WHERE object_id = OBJECT_ID(N'dbo.Users');

INSERT #c (prueba, resultado, detalle)
SELECT N'RLS: política pol_UserData activada con 5 predicados',
       IIF(p.is_enabled = 1 AND (SELECT COUNT(*) FROM sys.security_predicates sp WHERE sp.object_id = p.object_id) = 5, N'OK', N'REVISAR'),
       CONCAT(N'activada=', p.is_enabled)
FROM sys.security_policies AS p WHERE p.name = N'pol_UserData';

/*==================== 7. Limpieza ====================*/
DELETE a FROM dbo.MovieNightRatingAudit AS a JOIN dbo.MovieNights AS m ON m.NightId = a.NightId WHERE m.Vibe LIKE N'TEST sec%';
DELETE FROM dbo.MovieNights WHERE Vibe LIKE N'TEST sec%';
SELECT @n = COUNT(*) FROM dbo.MovieNights;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Limpieza: MovieNights vuelve a tener 30 filas', IIF(@n = 30, N'OK', N'REVISAR'), CONCAT(@n, N' filas'));

SELECT prueba, resultado, detalle FROM #c ORDER BY id;

IF EXISTS (SELECT 1 FROM #c WHERE resultado = N'REVISAR')
    THROW 50004, N'Alguna prueba de seguridad (Fase 4) ha dado REVISAR.', 1;

DROP TABLE #c;
GO
