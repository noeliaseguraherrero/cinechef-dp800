/*==============================================================
  CineChef - Fase 3: procedimientos almacenados (Bloque A)
  Requiere: vw_UserProfile, fn_SafeRecipes (04, 05) y el trigger (06).

  Códigos de error propios (THROW):
    50010 usuario inexistente        50011 película inexistente
    50012 receta inexistente         50013 película no apta por edad
    50014 receta con alérgenos del usuario
    50015 receta sin ingredientes (no se puede garantizar que sea segura)
    50020 valoración fuera de 1-5    50021 plan inexistente para ese usuario
    50030 no autorizado: se intenta actuar en nombre de otro usuario

  Control de identidad (Fase 4, hallazgo 4 de la revisión B-06): el
  usuario llega como parámetro, pero solo se acepta si coincide con
  quien ejecuta el procedimiento (USER_NAME() mapeado en
  dbo.UserPrincipals). Los administradores (db_owner) están exentos.
==============================================================*/
USE CineChefDB;
GO

/*--------------------------------------------------------------
  usp_RegisterMovieNight
  Registra un plan (película + receta) para un usuario, validando
  edad y alérgenos dentro de una transacción.
  Devuelve el identificador del plan en @NightId.

  Los controles y el INSERT van en la misma transacción. Con el
  aislamiento por defecto (READ COMMITTED) una alergia añadida
  justo entre el control y el INSERT no se detectaría; se acepta para
  este proyecto. No debe llamarse dentro de otra transacción abierta:
  el CATCH deshace la transacción completa.
--------------------------------------------------------------*/
CREATE OR ALTER PROCEDURE dbo.usp_RegisterMovieNight
    @UserId   INT,
    @MovieId  INT,
    @RecipeId INT,
    @Vibe     NVARCHAR(300) = NULL,
    @NightId  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @age      INT,
            @minAge   TINYINT,
            @conflict NVARCHAR(400),
            @msg      NVARCHAR(2048);

    SET @NightId = NULL;

    -- Identidad: solo el propio usuario (o un administrador) puede actuar en su nombre
    IF IS_MEMBER(N'db_owner') = 0
       AND NOT EXISTS (SELECT 1 FROM dbo.UserPrincipals
                       WHERE UserId = @UserId AND PrincipalName = USER_NAME())
        THROW 50030, N'No autorizado: solo puedes actuar en tu propio nombre.', 1;

    BEGIN TRY
        BEGIN TRAN;

        -- 1. Existencia de usuario, película y receta
        SELECT @age = Age FROM dbo.vw_UserProfile WHERE UserId = @UserId;
        IF @age IS NULL THROW 50010, N'El usuario no existe.', 1;

        SELECT @minAge = MinAge FROM dbo.Movies WHERE MovieId = @MovieId;
        IF @minAge IS NULL THROW 50011, N'La película no existe.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Recipes WHERE RecipeId = @RecipeId)
            THROW 50012, N'La receta no existe.', 1;

        -- 2. Control parental
        IF @age < @minAge
        BEGIN
            SET @msg = CONCAT(N'La película requiere ', @minAge, N' años y el usuario tiene ', @age, N'.');
            THROW 50013, @msg, 1;
        END;

        -- 3. Alérgenos del usuario presentes en la receta
        SELECT @conflict = STRING_AGG(d.Name, N', ')
        FROM (
            SELECT DISTINCT a.Name
            FROM dbo.RecipeIngredients   AS ri
            JOIN dbo.IngredientAllergens AS ia ON ia.IngredientId = ri.IngredientId
            JOIN dbo.UserAllergies       AS ua ON ua.AllergenId   = ia.AllergenId
                                              AND ua.UserId       = @UserId
            JOIN dbo.Allergens           AS a  ON a.AllergenId    = ia.AllergenId
            WHERE ri.RecipeId = @RecipeId
        ) AS d;

        IF @conflict IS NOT NULL
        BEGIN
            SET @msg = CONCAT(N'La receta contiene alérgenos del usuario: ', @conflict, N'.');
            THROW 50014, @msg, 1;
        END;

        -- 4. Misma regla que fn_SafeRecipes (cubre la receta sin ingredientes)
        IF NOT EXISTS (SELECT 1 FROM dbo.fn_SafeRecipes(@UserId) WHERE RecipeId = @RecipeId)
            THROW 50015, N'No se puede garantizar que la receta sea segura (sin ingredientes registrados).', 1;

        -- 5. Alta del plan
        INSERT dbo.MovieNights (UserId, MovieId, RecipeId, Vibe)
        VALUES (@UserId, @MovieId, @RecipeId, @Vibe);

        SET @NightId = SCOPE_IDENTITY();

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @NightId = NULL;
        THROW;
    END CATCH;
END;
GO

/*--------------------------------------------------------------
  usp_RateMovieNight
  Valora (1-5) o borra la valoración (NULL) de un plan. Solo el
  propietario del plan puede valorarlo. El trigger registra el cambio.
--------------------------------------------------------------*/
CREATE OR ALTER PROCEDURE dbo.usp_RateMovieNight
    @NightId INT,
    @UserId  INT,
    @Rating  TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Identidad: solo el propio usuario (o un administrador) puede actuar en su nombre
    IF IS_MEMBER(N'db_owner') = 0
       AND NOT EXISTS (SELECT 1 FROM dbo.UserPrincipals
                       WHERE UserId = @UserId AND PrincipalName = USER_NAME())
        THROW 50030, N'No autorizado: solo puedes actuar en tu propio nombre.', 1;

    IF @Rating IS NOT NULL AND @Rating NOT BETWEEN 1 AND 5
        THROW 50020, N'La valoración debe estar entre 1 y 5.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.MovieNights WHERE NightId = @NightId AND UserId = @UserId)
        THROW 50021, N'No existe ese plan para este usuario.', 1;

    UPDATE dbo.MovieNights
    SET    Rating = @Rating
    WHERE  NightId = @NightId AND UserId = @UserId;
END;
GO

/*--------------------------------------------------------------
  usp_FindMovieByTitle
  Búsqueda tolerante a erratas (fuzzy string matching):
    - JARO_WINKLER_DISTANCE: 0 = idéntico, 1 = nada en común.
      Se usa para filtrar y ordenar; penaliza menos los fallos al final
      de la palabra.
    - EDIT_DISTANCE: número de cambios de carácter; desempata.
  Se compara en minúsculas. @MaxDistance es el umbral de Jaro-Winkler.
--------------------------------------------------------------*/
CREATE OR ALTER PROCEDURE dbo.usp_FindMovieByTitle
    @SearchTitle NVARCHAR(200),
    @Top         INT   = 5,
    @MaxDistance FLOAT = 0.25
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
           m.MovieId,
           m.Title,
           m.ReleaseYear,
           EDIT_DISTANCE(LOWER(m.Title), LOWER(@SearchTitle))          AS EditDistance,
           JARO_WINKLER_DISTANCE(LOWER(m.Title), LOWER(@SearchTitle))  AS JaroWinklerDistance
    FROM dbo.Movies AS m
    WHERE JARO_WINKLER_DISTANCE(LOWER(m.Title), LOWER(@SearchTitle)) <= @MaxDistance
    ORDER BY JaroWinklerDistance, EditDistance, m.Title;
END;
GO
