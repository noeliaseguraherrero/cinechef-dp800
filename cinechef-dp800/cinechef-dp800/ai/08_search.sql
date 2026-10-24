/*==============================================================
  CineChef - Fase 6 (Bloque F): búsqueda inteligente
  Requiere: embeddings generados (05), índices Full-Text (07),
            vw_UserProfile, fn_SafeRecipes, fn_AllowedMovies.

  Búsqueda HÍBRIDA con Reciprocal Rank Fusion (RRF):
    score = Σ 1 / (k + posición_en_cada_lista),  k = 60
  Se fusionan POSICIONES y no distancias, porque las distancias coseno
  de MiniLM están comprimidas (ver docs/embeddings.md) y no son
  comparables con las puntuaciones del Full-Text.

  Modos (@Mode):
    vector  solo similitud semántica (VECTOR_DISTANCE coseno)
    text    solo Full-Text (texto + ingredientes en recetas)
    hybrid  RRF de todas las listas (por defecto)

  Métrica coseno: mide el ángulo entre vectores e ignora su longitud,
  que es lo habitual en modelos de texto; los vectores de MiniLM
  salen normalizados, así que coseno y producto escalar ordenan igual.

  Seguridad: si se indica @UserId, la búsqueda solo devuelve recetas
  seguras para ese usuario (alergias) y películas permitidas por su edad
  (usuario inexistente => 0 filas). Mismo control de identidad que
  usp_RegisterMovieNight (error 50030).
  Errores: 50040 modo no válido, 50041 consulta vacía.
==============================================================*/
USE CineChefDB;
GO

/*--------------------------------------------------------------
  usp_SearchMovies
--------------------------------------------------------------*/
CREATE OR ALTER PROCEDURE dbo.usp_SearchMovies
    @Query  NVARCHAR(300),
    @UserId INT         = NULL,
    @Top    INT         = 10,
    @Mode   VARCHAR(10) = 'hybrid',
    @RrfK   INT         = 60
AS
BEGIN
    SET NOCOUNT ON;

    IF @Mode NOT IN ('vector', 'text', 'hybrid') THROW 50040, N'@Mode debe ser vector, text o hybrid.', 1;
    IF NULLIF(LTRIM(RTRIM(@Query)), N'') IS NULL THROW 50041, N'La consulta no puede estar vacía.', 1;

    IF @UserId IS NOT NULL AND IS_MEMBER(N'db_owner') = 0
       AND NOT EXISTS (SELECT 1 FROM dbo.UserPrincipals
                       WHERE UserId = @UserId AND PrincipalName = USER_NAME())
        THROW 50030, N'No autorizado: solo puedes actuar en tu propio nombre.', 1;

    DECLARE @q VECTOR(384) = AI_GENERATE_EMBEDDINGS(@Query USE MODEL CineChefEmbeddingModel);

    WITH cand AS (
        SELECT m.MovieId, m.Title, m.ReleaseYear, m.MinAge, m.Embedding
        FROM dbo.Movies AS m
        WHERE @UserId IS NULL
           OR EXISTS (SELECT 1 FROM dbo.fn_AllowedMovies(@UserId) AS a WHERE a.MovieId = m.MovieId)
    ),
    d AS (
        SELECT c.*, VECTOR_DISTANCE('cosine', c.Embedding, @q) AS Dist FROM cand AS c
    ),
    v AS (
        SELECT MovieId, ROW_NUMBER() OVER (ORDER BY Dist, MovieId) AS rnk FROM d
    ),
    t AS (
        SELECT c.MovieId, ROW_NUMBER() OVER (ORDER BY f.[RANK] DESC, c.MovieId) AS rnk
        FROM FREETEXTTABLE(dbo.Movies, (Title, Synopsis), @Query) AS f
        JOIN cand AS c ON c.MovieId = f.[KEY]
    )
    SELECT TOP (@Top)
           d.MovieId, d.Title, d.ReleaseYear, d.MinAge,
           CAST(s.Score AS DECIMAL(9,6)) AS Score,
           v.rnk AS VectorRank, t.rnk AS TextRank,
           d.Dist AS CosineDistance
    FROM d
    JOIN v ON v.MovieId = d.MovieId
    LEFT JOIN t ON t.MovieId = d.MovieId
    CROSS APPLY (SELECT CASE WHEN @Mode IN ('vector', 'hybrid') THEN 1.0 / (@RrfK + v.rnk) ELSE 0 END
                       + CASE WHEN @Mode IN ('text', 'hybrid')   THEN COALESCE(1.0 / (@RrfK + t.rnk), 0) ELSE 0 END AS Score) AS s
    WHERE s.Score > 0
    ORDER BY s.Score DESC, d.MovieId;
END;
GO

/*--------------------------------------------------------------
  usp_SearchRecipes
  Tres listas: vector, texto (nombre/descripción) e ingredientes
  (Full-Text sobre dbo.Ingredients, agregado por receta).
--------------------------------------------------------------*/
CREATE OR ALTER PROCEDURE dbo.usp_SearchRecipes
    @Query  NVARCHAR(300),
    @UserId INT         = NULL,
    @Top    INT         = 10,
    @Mode   VARCHAR(10) = 'hybrid',
    @RrfK   INT         = 60
AS
BEGIN
    SET NOCOUNT ON;

    IF @Mode NOT IN ('vector', 'text', 'hybrid') THROW 50040, N'@Mode debe ser vector, text o hybrid.', 1;
    IF NULLIF(LTRIM(RTRIM(@Query)), N'') IS NULL THROW 50041, N'La consulta no puede estar vacía.', 1;

    IF @UserId IS NOT NULL AND IS_MEMBER(N'db_owner') = 0
       AND NOT EXISTS (SELECT 1 FROM dbo.UserPrincipals
                       WHERE UserId = @UserId AND PrincipalName = USER_NAME())
        THROW 50030, N'No autorizado: solo puedes actuar en tu propio nombre.', 1;

    DECLARE @q VECTOR(384) = AI_GENERATE_EMBEDDINGS(@Query USE MODEL CineChefEmbeddingModel);

    WITH cand AS (
        SELECT r.RecipeId, r.Name, r.PrepMin, r.Difficulty, r.Embedding
        FROM dbo.Recipes AS r
        WHERE (@UserId IS NULL
               AND EXISTS (SELECT 1 FROM dbo.RecipeIngredients AS x WHERE x.RecipeId = r.RecipeId))
           OR (@UserId IS NOT NULL
               AND EXISTS (SELECT 1 FROM dbo.fn_SafeRecipes(@UserId) AS s WHERE s.RecipeId = r.RecipeId))
    ),
    d AS (
        SELECT c.*, VECTOR_DISTANCE('cosine', c.Embedding, @q) AS Dist FROM cand AS c
    ),
    v AS (
        SELECT RecipeId, ROW_NUMBER() OVER (ORDER BY Dist, RecipeId) AS rnk FROM d
    ),
    t AS (
        SELECT c.RecipeId, ROW_NUMBER() OVER (ORDER BY f.[RANK] DESC, c.RecipeId) AS rnk
        FROM FREETEXTTABLE(dbo.Recipes, (Name, Description), @Query) AS f
        JOIN cand AS c ON c.RecipeId = f.[KEY]
    ),
    g AS (
        SELECT ri.RecipeId, SUM(f.[RANK]) AS sc
        FROM FREETEXTTABLE(dbo.Ingredients, (Name), @Query) AS f
        JOIN dbo.RecipeIngredients AS ri ON ri.IngredientId = f.[KEY]
        GROUP BY ri.RecipeId
    ),
    gi AS (
        SELECT c.RecipeId, ROW_NUMBER() OVER (ORDER BY g.sc DESC, c.RecipeId) AS rnk
        FROM g JOIN cand AS c ON c.RecipeId = g.RecipeId
    )
    SELECT TOP (@Top)
           d.RecipeId, d.Name, d.PrepMin, d.Difficulty,
           CAST(s.Score AS DECIMAL(9,6)) AS Score,
           v.rnk AS VectorRank, t.rnk AS TextRank, gi.rnk AS IngredientRank,
           d.Dist AS CosineDistance
    FROM d
    JOIN v ON v.RecipeId = d.RecipeId
    LEFT JOIN t  ON t.RecipeId  = d.RecipeId
    LEFT JOIN gi ON gi.RecipeId = d.RecipeId
    CROSS APPLY (SELECT CASE WHEN @Mode IN ('vector', 'hybrid') THEN 1.0 / (@RrfK + v.rnk) ELSE 0 END
                       + CASE WHEN @Mode IN ('text', 'hybrid')   THEN COALESCE(1.0 / (@RrfK + t.rnk), 0)
                                                                      + COALESCE(1.0 / (@RrfK + gi.rnk), 0) ELSE 0 END AS Score) AS s
    WHERE s.Score > 0
    ORDER BY s.Score DESC, d.RecipeId;
END;
GO

/*--------------------------------------------------------------
  usp_SuggestRecipesForMovie
  Maridaje película-receta: de las recetas SEGURAS para el usuario,
  las más cercanas en significado a la película (coseno entre el
  embedding de la película y el de cada receta; no llama al modelo).
  Errores: 50010 usuario, 50011 película, 50013 película no apta por edad.
--------------------------------------------------------------*/
CREATE OR ALTER PROCEDURE dbo.usp_SuggestRecipesForMovie
    @MovieId INT,
    @UserId  INT,
    @Top     INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    IF IS_MEMBER(N'db_owner') = 0
       AND NOT EXISTS (SELECT 1 FROM dbo.UserPrincipals
                       WHERE UserId = @UserId AND PrincipalName = USER_NAME())
        THROW 50030, N'No autorizado: solo puedes actuar en tu propio nombre.', 1;

    DECLARE @age INT, @minAge TINYINT, @emb VECTOR(384);
    SELECT @age = Age FROM dbo.vw_UserProfile WHERE UserId = @UserId;
    IF @age IS NULL THROW 50010, N'El usuario no existe.', 1;

    SELECT @minAge = MinAge, @emb = Embedding FROM dbo.Movies WHERE MovieId = @MovieId;
    IF @minAge IS NULL THROW 50011, N'La película no existe.', 1;
    IF @age < @minAge  THROW 50013, N'La película no es apta para la edad del usuario.', 1;

    SELECT TOP (@Top)
           r.RecipeId, r.Name, r.PrepMin, r.Difficulty,
           VECTOR_DISTANCE('cosine', @emb, r.Embedding) AS CosineDistance
    FROM dbo.fn_SafeRecipes(@UserId) AS s
    JOIN dbo.Recipes AS r ON r.RecipeId = s.RecipeId
    ORDER BY CosineDistance, r.RecipeId;
END;
GO

/*-------- Permisos (mínimo privilegio) --------*/
GRANT EXECUTE ON dbo.usp_SearchMovies             TO role_customer, role_nutritionist, role_analyst;
GRANT EXECUTE ON dbo.usp_SearchRecipes            TO role_customer, role_nutritionist, role_analyst;
GRANT EXECUTE ON dbo.usp_SuggestRecipesForMovie   TO role_customer;
GO

-- La búsqueda genera el embedding de la consulta: hace falta permiso sobre el modelo.
BEGIN TRY
    GRANT EXECUTE ON EXTERNAL MODEL::CineChefEmbeddingModel TO role_customer, role_nutritionist, role_analyst;
END TRY
BEGIN CATCH
    PRINT CONCAT(N'AVISO: no se pudo conceder EXECUTE sobre el modelo: ', ERROR_MESSAGE());
END CATCH;
GO
