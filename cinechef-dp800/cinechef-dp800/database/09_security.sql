/*==============================================================
  CineChef - Fase 4: seguridad (Bloque C)
  Mecanismos implementados:
    1. Roles y principio de mínimo privilegio (GRANT / DENY).
    2. Row-Level Security (RLS) sobre Users, UserAllergies y MovieNights.
    3. Dynamic Data Masking (DDM) sobre Users.Email y Users.BirthDate.
    4. Escalada controlada con EXECUTE AS OWNER (usp_GenreRatingStats).

  Los usuarios de demostración se crean WITHOUT LOGIN: no hay
  contraseñas ni secretos en el repositorio. En un sistema real se
  asociarían a inicios de sesión de la aplicación o de Active Directory.

  Requiere: 02 (tablas), 04-07 (vistas, funciones, trigger, procedimientos)
  y los datos 03*. El script es repetible.
==============================================================*/
USE CineChefDB;
GO

/*-------- 0. Limpieza previa (para poder repetir el script) --------*/
IF EXISTS (SELECT 1 FROM sys.security_policies WHERE name = N'pol_UserData')
    DROP SECURITY POLICY Security.pol_UserData;
GO
IF SCHEMA_ID(N'Security') IS NULL
    EXEC (N'CREATE SCHEMA Security');
GO

/*-------- 1. Roles --------
  role_customer      persona usuaria de la aplicación: solo ve y modifica lo suyo.
  role_nutritionist  consulta alergias de todos los usuarios, con email y fecha enmascarados.
  role_analyst       solo catálogo y estadísticas agregadas; sin datos personales.
  Administrador      dbo / db_owner: acceso completo.                                  */
IF DATABASE_PRINCIPAL_ID(N'role_customer')     IS NULL CREATE ROLE role_customer;
IF DATABASE_PRINCIPAL_ID(N'role_nutritionist') IS NULL CREATE ROLE role_nutritionist;
IF DATABASE_PRINCIPAL_ID(N'role_analyst')      IS NULL CREATE ROLE role_analyst;
GO

/*-------- 2. Usuarios de demostración (sin inicio de sesión) --------*/
IF DATABASE_PRINCIPAL_ID(N'cc_isaac')   IS NULL CREATE USER cc_isaac   WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'cc_alice')   IS NULL CREATE USER cc_alice   WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'cc_kid')     IS NULL CREATE USER cc_kid     WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'cc_nutri')   IS NULL CREATE USER cc_nutri   WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'cc_analyst') IS NULL CREATE USER cc_analyst WITHOUT LOGIN;

IF IS_ROLEMEMBER(N'role_customer',     N'cc_isaac')   = 0 ALTER ROLE role_customer     ADD MEMBER cc_isaac;
IF IS_ROLEMEMBER(N'role_customer',     N'cc_alice')   = 0 ALTER ROLE role_customer     ADD MEMBER cc_alice;
IF IS_ROLEMEMBER(N'role_customer',     N'cc_kid')     = 0 ALTER ROLE role_customer     ADD MEMBER cc_kid;
IF IS_ROLEMEMBER(N'role_nutritionist', N'cc_nutri')   = 0 ALTER ROLE role_nutritionist ADD MEMBER cc_nutri;
IF IS_ROLEMEMBER(N'role_analyst',      N'cc_analyst') = 0 ALTER ROLE role_analyst      ADD MEMBER cc_analyst;
GO

/*-------- 3. Correspondencia usuario de la aplicación -> usuario de base de datos --------
  cc_isaac = Isaac Brown (gluten y leche), cc_alice = Alice Carter (sin alergias),
  cc_kid = el usuario más joven del resto (para demostrar el control parental). */
DELETE FROM dbo.UserPrincipals;

INSERT dbo.UserPrincipals (UserId, PrincipalName)
SELECT UserId, N'cc_isaac' FROM dbo.Users WHERE UserName = N'Isaac Brown'
UNION ALL
SELECT UserId, N'cc_alice' FROM dbo.Users WHERE UserName = N'Alice Carter'
UNION ALL
SELECT k.UserId, N'cc_kid'
FROM (SELECT TOP (1) UserId
      FROM dbo.vw_UserProfile
      WHERE UserName NOT IN (N'Isaac Brown', N'Alice Carter')
      ORDER BY Age, UserId) AS k;

IF (SELECT COUNT(*) FROM dbo.UserPrincipals) <> 3
    THROW 50040, N'No se pudieron crear las 3 correspondencias de usuario. ¿Están cargados los datos 03e?', 1;
GO

/*-------- 4. Dynamic Data Masking --------
  Email   -> aXXX@XXXX.com        BirthDate -> 1900-01-01
  Los roles sin permiso UNMASK ven el valor enmascarado.                   */
IF NOT EXISTS (SELECT 1 FROM sys.masked_columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'Email')
    ALTER TABLE dbo.Users ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');
IF NOT EXISTS (SELECT 1 FROM sys.masked_columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND name = N'BirthDate')
    ALTER TABLE dbo.Users ALTER COLUMN BirthDate ADD MASKED WITH (FUNCTION = 'default()');
GO

/*-------- 5. Row-Level Security --------
  Las funciones de predicado usan SCHEMABINDING: así los usuarios no
  necesitan permisos sobre dbo.UserPrincipals para consultar las tablas
  protegidas (se exige solo si la política se crea con SCHEMABINDING = OFF). */
CREATE OR ALTER FUNCTION Security.fn_OwnerOrAdmin (@UserId INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS allowed
    WHERE IS_MEMBER(N'db_owner') = 1
       OR EXISTS (SELECT 1 FROM dbo.UserPrincipals AS p
                  WHERE p.UserId = @UserId AND p.PrincipalName = USER_NAME());
GO

CREATE OR ALTER FUNCTION Security.fn_OwnerNutritionistOrAdmin (@UserId INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS allowed
    WHERE IS_MEMBER(N'db_owner') = 1
       OR IS_MEMBER(N'role_nutritionist') = 1
       OR EXISTS (SELECT 1 FROM dbo.UserPrincipals AS p
                  WHERE p.UserId = @UserId AND p.PrincipalName = USER_NAME());
GO

CREATE SECURITY POLICY Security.pol_UserData
    -- Historial: cada persona solo ve (y solo puede escribir) sus propios planes
    ADD FILTER PREDICATE Security.fn_OwnerOrAdmin(UserId) ON dbo.MovieNights,
    ADD BLOCK  PREDICATE Security.fn_OwnerOrAdmin(UserId) ON dbo.MovieNights AFTER INSERT,
    ADD BLOCK  PREDICATE Security.fn_OwnerOrAdmin(UserId) ON dbo.MovieNights AFTER UPDATE,
    -- Alergias y usuarios: la propia persona, el nutricionista y el administrador
    ADD FILTER PREDICATE Security.fn_OwnerNutritionistOrAdmin(UserId) ON dbo.UserAllergies,
    ADD FILTER PREDICATE Security.fn_OwnerNutritionistOrAdmin(UserId) ON dbo.Users
WITH (STATE = ON);
GO

/*-------- 6. Escalada controlada: estadísticas agregadas para el analista --------
  El analista no puede leer MovieNights, pero sí obtener estadísticas por género.
  El procedimiento se ejecuta como propietario (EXECUTE AS OWNER) para que RLS
  no filtre las filas, y devuelve solo datos agregados, sin identificar personas.
  Una noche con varios géneros cuenta en cada uno de ellos.

  Tamaño mínimo de grupo (hallazgo 2 de la revisión B-08): un género con una sola
  valoración devolvería como "media" la valoración exacta de una persona. Por eso solo
  se muestran géneros con @MinRatedNights valoraciones o más. Es una constante interna,
  no un parámetro, para que quien llama no pueda bajarla. Limitación: comparar géneros
  que comparten películas aún permite inferencias por diferencia; la defensa completa
  (ruido, privacidad diferencial) queda fuera del alcance.                           */
CREATE OR ALTER PROCEDURE dbo.usp_GenreRatingStats
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MinRatedNights INT = 3;

    SELECT g.Name                                   AS Genre,
           COUNT(*)                                 AS Nights,
           COUNT(n.Rating)                          AS RatedNights,
           AVG(CAST(n.Rating AS DECIMAL(4,2)))      AS AvgRating
    FROM dbo.MovieNights AS n
    JOIN dbo.MovieGenres AS mg ON mg.MovieId = n.MovieId
    JOIN dbo.Genres      AS g  ON g.GenreId  = mg.GenreId
    GROUP BY g.Name
    HAVING COUNT(n.Rating) >= @MinRatedNights
    ORDER BY Nights DESC, g.Name;
END;
GO

/*-------- 7. Permisos (mínimo privilegio) --------*/
-- Catálogo: lectura para los tres roles
GRANT SELECT ON dbo.Movies              TO role_customer, role_nutritionist, role_analyst;
GRANT SELECT ON dbo.Genres              TO role_customer, role_nutritionist, role_analyst;
GRANT SELECT ON dbo.MovieGenres         TO role_customer, role_nutritionist, role_analyst;
GRANT SELECT ON dbo.Recipes             TO role_customer, role_nutritionist, role_analyst;
GRANT SELECT ON dbo.Ingredients         TO role_customer, role_nutritionist, role_analyst;
GRANT SELECT ON dbo.RecipeIngredients   TO role_customer, role_nutritionist, role_analyst;
GRANT SELECT ON dbo.Allergens           TO role_customer, role_nutritionist, role_analyst;
GRANT SELECT ON dbo.IngredientAllergens TO role_customer, role_nutritionist, role_analyst;
GRANT SELECT ON dbo.vw_RecipeAllergens  TO role_customer, role_nutritionist, role_analyst;
GRANT SELECT ON dbo.vw_MovieSearchText  TO role_customer, role_nutritionist, role_analyst;
GRANT SELECT ON dbo.vw_RecipeSearchText TO role_customer, role_nutritionist, role_analyst;

-- Datos de personas: RLS limita las filas; DDM enmascara columnas
GRANT SELECT ON dbo.Users          TO role_customer, role_nutritionist;
GRANT SELECT ON dbo.UserAllergies  TO role_customer, role_nutritionist;
GRANT SELECT ON dbo.MovieNights    TO role_customer;
GRANT SELECT ON dbo.vw_UserProfile TO role_customer, role_nutritionist;
GRANT SELECT ON dbo.fn_SafeRecipes   TO role_customer, role_nutritionist;
GRANT SELECT ON dbo.fn_AllowedMovies TO role_customer, role_nutritionist;

-- Cada persona ve sin máscara SU email y SU fecha de nacimiento (RLS ya le oculta las filas ajenas)
GRANT UNMASK ON OBJECT::dbo.Users (Email)     TO role_customer;
GRANT UNMASK ON OBJECT::dbo.Users (BirthDate) TO role_customer;

-- Operaciones: solo mediante procedimientos (el encadenamiento de propiedad evita dar INSERT/UPDATE)
GRANT EXECUTE ON dbo.usp_RegisterMovieNight TO role_customer;
GRANT EXECUTE ON dbo.usp_RateMovieNight     TO role_customer;
GRANT EXECUTE ON dbo.usp_FindMovieByTitle   TO role_customer, role_nutritionist, role_analyst;
GRANT EXECUTE ON dbo.usp_GenreRatingStats   TO role_analyst;

-- Denegaciones explícitas (prevalecen sobre cualquier GRANT)
DENY INSERT, UPDATE, DELETE ON dbo.MovieNights   TO role_customer;
DENY INSERT, UPDATE, DELETE ON dbo.Users         TO role_customer, role_nutritionist, role_analyst;
DENY INSERT, UPDATE, DELETE ON dbo.UserAllergies TO role_customer, role_nutritionist, role_analyst;
DENY SELECT                 ON dbo.MovieNights   TO role_nutritionist, role_analyst;
DENY SELECT                 ON dbo.Users         TO role_analyst;
DENY SELECT                 ON dbo.UserAllergies TO role_analyst;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.UserPrincipals         TO role_customer, role_nutritionist, role_analyst;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.MovieNightRatingAudit  TO role_customer, role_nutritionist, role_analyst;
GO

/*-------- 8. Resumen de permisos (evidencia) --------*/
SELECT pr.name                                   AS rol,
       dp.state_desc                             AS estado,
       dp.permission_name                        AS permiso,
       CASE WHEN dp.class = 1 THEN OBJECT_NAME(dp.major_id) END AS objeto,
       CASE WHEN dp.class = 1 AND dp.minor_id > 0 THEN COL_NAME(dp.major_id, dp.minor_id) END AS columna
FROM sys.database_permissions AS dp
JOIN sys.database_principals  AS pr ON pr.principal_id = dp.grantee_principal_id
WHERE pr.name LIKE N'role[_]%'
ORDER BY pr.name, dp.state_desc, objeto, dp.permission_name;
GO
