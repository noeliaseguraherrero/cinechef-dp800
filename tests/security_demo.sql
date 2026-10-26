/*==============================================================
  CineChef - Fase 4: demostración de seguridad (para capturas)
  Ejecutar sección a sección. Cada bloque suplanta a un usuario
  con EXECUTE AS y termina con REVERT. Si algo falla a mitad,
  ejecuta REVERT; antes de continuar.
==============================================================*/
USE CineChefDB;
GO

/*==== A. Administrador (dbo): ve todo ====*/
SELECT USER_NAME() AS yo;
SELECT UserId, UserName, Email, BirthDate FROM dbo.Users ORDER BY UserId;      -- 10 filas, sin máscara
SELECT COUNT(*) AS alergias_totales FROM dbo.UserAllergies;                    -- 9
SELECT COUNT(*) AS planes_totales   FROM dbo.MovieNights;                      -- 30
GO

/*==== B. cc_isaac (cliente con alergias a gluten y leche) ====*/
DECLARE @isaac INT = (SELECT UserId FROM dbo.UserPrincipals WHERE PrincipalName = N'cc_isaac');
DECLARE @alice INT = (SELECT UserId FROM dbo.UserPrincipals WHERE PrincipalName = N'cc_alice');
EXECUTE AS USER = N'cc_isaac';
    SELECT USER_NAME() AS yo;
    SELECT UserId, UserName, Email, BirthDate FROM dbo.Users;                  -- solo su fila, SIN máscara
    SELECT * FROM dbo.vw_UserProfile;                                          -- su perfil
    SELECT COUNT(*) AS planes_visibles FROM dbo.MovieNights;                   -- solo los suyos
    SELECT COUNT(*) AS mis_recetas_seguras  FROM dbo.fn_SafeRecipes(@isaac);   -- 42
    SELECT COUNT(*) AS recetas_de_otra_persona FROM dbo.fn_SafeRecipes(@alice);-- 0: falla cerrado
    BEGIN TRY
        INSERT dbo.MovieNights (UserId, MovieId, RecipeId) VALUES (@isaac, 1, 1);
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje;            -- 229: INSERT directo denegado
    END CATCH;
REVERT;
GO

/*==== C. cc_alice: intenta actuar en nombre de Isaac ====*/
DECLARE @isaac INT = (SELECT UserId FROM dbo.UserPrincipals WHERE PrincipalName = N'cc_isaac');
DECLARE @n INT;
EXECUTE AS USER = N'cc_alice';
    BEGIN TRY
        EXEC dbo.usp_RegisterMovieNight @UserId = @isaac, @MovieId = 1, @RecipeId = 1, @NightId = @n OUTPUT;
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje;            -- 50030
    END CATCH;
REVERT;
GO

/*==== D. cc_kid: control parental ====*/
DECLARE @kid INT = (SELECT UserId FROM dbo.UserPrincipals WHERE PrincipalName = N'cc_kid');
DECLARE @movie18 INT = (SELECT TOP 1 MovieId FROM dbo.Movies WHERE MinAge = 18 ORDER BY MovieId);
DECLARE @n INT;
EXECUTE AS USER = N'cc_kid';
    SELECT UserName, Age FROM dbo.vw_UserProfile;
    SELECT MinAge, COUNT(*) AS peliculas_permitidas FROM dbo.fn_AllowedMovies(@kid) GROUP BY MinAge ORDER BY MinAge;
    BEGIN TRY
        EXEC dbo.usp_RegisterMovieNight @UserId = @kid, @MovieId = @movie18, @RecipeId = 1, @NightId = @n OUTPUT;
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje;            -- 50013
    END CATCH;
REVERT;
GO

/*==== E. cc_nutri: ve a todos, con datos personales enmascarados ====*/
EXECUTE AS USER = N'cc_nutri';
    SELECT USER_NAME() AS yo;
    SELECT UserId, UserName, Email, BirthDate FROM dbo.Users;                  -- 10 filas, email y fecha ENMASCARADOS
    SELECT u.UserName, a.Name AS alergeno
    FROM dbo.UserAllergies AS ua
    JOIN dbo.Users     AS u ON u.UserId     = ua.UserId
    JOIN dbo.Allergens AS a ON a.AllergenId = ua.AllergenId
    ORDER BY u.UserName;                                                       -- las 9 alergias
    BEGIN TRY
        SELECT COUNT(*) FROM dbo.MovieNights;
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje;            -- 229
    END CATCH;

    -- Limitación del enmascarado: no impide FILTRAR por el valor real
    SELECT COUNT(*) AS nacidos_antes_de_1990 FROM dbo.Users WHERE BirthDate < '1990-01-01';
    -- Observación: ¿qué edad calcula la vista con la fecha enmascarada?
    SELECT UserName, Age FROM dbo.vw_UserProfile;
REVERT;
GO

/*==== F. cc_analyst: solo catálogo y estadísticas agregadas ====*/
EXECUTE AS USER = N'cc_analyst';
    SELECT USER_NAME() AS yo;
    SELECT COUNT(*) AS peliculas FROM dbo.Movies;                              -- 100
    EXEC dbo.usp_GenreRatingStats;                                             -- agregado por género
    BEGIN TRY SELECT COUNT(*) FROM dbo.Users;       END TRY BEGIN CATCH SELECT 'Users' AS tabla, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
    BEGIN TRY SELECT COUNT(*) FROM dbo.MovieNights; END TRY BEGIN CATCH SELECT 'MovieNights' AS tabla, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
REVERT;
GO

/*==== G. GRANT / DENY / REVOKE en directo ====*/
-- 1) Se retira el permiso de búsqueda difusa al rol de clientes
REVOKE EXECUTE ON dbo.usp_FindMovieByTitle FROM role_customer;
EXECUTE AS USER = N'cc_alice';
    BEGIN TRY
        EXEC dbo.usp_FindMovieByTitle @SearchTitle = N'fight clob';
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje;            -- 229: sin permiso
    END CATCH;
REVERT;
-- 2) Se vuelve a conceder y funciona
GRANT EXECUTE ON dbo.usp_FindMovieByTitle TO role_customer;
EXECUTE AS USER = N'cc_alice';
    EXEC dbo.usp_FindMovieByTitle @SearchTitle = N'fight clob';                -- encuentra Fight Club
REVERT;
GO

/*==== H. Permisos de cada rol sobre dbo.Users (a nivel de tabla y de columna) ====
  sys.fn_my_permissions solo muestra 'SELECT' repetido por columna y no distingue entre usuarios;
  esta consulta muestra quién tiene qué, incluidos UNMASK y los DENY.                       */
SELECT pr.name AS rol,
       dp.state_desc AS estado,
       dp.permission_name AS permiso,
       COL_NAME(dp.major_id, dp.minor_id) AS columna
FROM sys.database_permissions AS dp
JOIN sys.database_principals  AS pr ON pr.principal_id = dp.grantee_principal_id
WHERE dp.major_id = OBJECT_ID(N'dbo.Users')
  AND pr.name LIKE N'role[_]%'
ORDER BY pr.name, dp.state_desc, dp.permission_name, columna;
GO

/*==== I. Ataque de inferencia sobre el enmascarado y su mitigación (hallazgo de la revisión de seguridad) ====*/
-- El administrador conoce los valores reales; el "atacante" cc_nutri solo adivina.
DECLARE @isaac INT = (SELECT UserId FROM dbo.UserPrincipals WHERE PrincipalName = N'cc_isaac');
DECLARE @realBirth DATE = (SELECT BirthDate FROM dbo.Users WHERE UserId = @isaac);
DECLARE @firstLetter NCHAR(1) = (SELECT LEFT(Email, 1) FROM dbo.Users WHERE UserId = @isaac);

EXECUTE AS USER = N'cc_nutri';
    -- La columna sale enmascarada, pero adivinar la fecha exacta devuelve 1 (acierto)
    SELECT BirthDate AS lo_que_ve_la_columna FROM dbo.Users WHERE UserId = @isaac;
    SELECT COUNT(*) AS acierta_la_fecha  FROM dbo.Users WHERE UserId = @isaac AND BirthDate = @realBirth;
    SELECT COUNT(*) AS acierta_la_inicial FROM dbo.Users WHERE UserId = @isaac AND LEFT(Email, 1) = @firstLetter;
REVERT;

-- Mitigación: negar SELECT sobre las columnas sensibles a quien no las necesita
DENY SELECT ON dbo.Users (BirthDate, Email) TO role_nutritionist;
EXECUTE AS USER = N'cc_nutri';
    BEGIN TRY
        SELECT COUNT(*) FROM dbo.Users WHERE UserId = @isaac AND BirthDate = @realBirth;
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje;            -- 230: denegado sobre la columna
    END CATCH;
    SELECT UserId, UserName FROM dbo.Users;                                    -- las columnas permitidas siguen funcionando
REVERT;
-- Se restablece el estado original (la mitigación queda demostrada pero no aplicada)
REVOKE SELECT ON dbo.Users (BirthDate, Email) FROM role_nutritionist;
GO

/*==== J. ¿A quién atribuye la auditoría el cambio de valoración? ====*/
DECLARE @alice INT = (SELECT UserId FROM dbo.UserPrincipals WHERE PrincipalName = N'cc_alice');
DECLARE @night INT = (SELECT TOP 1 NightId FROM dbo.MovieNights WHERE UserId = @alice ORDER BY NightId);
DECLARE @oldRating TINYINT = (SELECT Rating FROM dbo.MovieNights WHERE NightId = @night);
DECLARE @newRating TINYINT = IIF(@oldRating IS NULL, 3, (@oldRating % 5) + 1);   -- siempre distinta de la actual

IF @night IS NULL
    PRINT N'cc_alice no tiene planes; ejecuta primero un registro de prueba.';
ELSE
BEGIN
    EXECUTE AS USER = N'cc_alice';
        EXEC dbo.usp_RateMovieNight @NightId = @night, @UserId = @alice, @Rating = @newRating;
    REVERT;

    SELECT TOP (3) AuditId, NightId, OldRating, NewRating, ChangedBy, ChangedAt
    FROM dbo.MovieNightRatingAudit ORDER BY AuditId DESC;   -- ChangedBy: ¿cc_alice o el inicio de sesión original?

    -- Limpieza: se restaura la valoración y se borran las filas de auditoría de la prueba
    DELETE FROM dbo.MovieNightRatingAudit WHERE NightId = @night;
    UPDATE dbo.MovieNights SET Rating = @oldRating WHERE NightId = @night;
    DELETE FROM dbo.MovieNightRatingAudit WHERE NightId = @night;
END;
GO
