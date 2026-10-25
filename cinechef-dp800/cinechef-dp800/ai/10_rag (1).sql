/*==============================================================
  CineChef - Fase 7 (Bloque G): RAG con generación manual en Copilot
  Requiere: 05 (embeddings), 07 (Full-Text), 08 (búsqueda).

  Flujo (Retrieval-Augmented Generation):
    1. RECUPERACIÓN  usp_BuildRagPrompt busca recetas y películas con
                     la búsqueda híbrida de la Fase 6, ya filtradas por
                     alergias y edad del usuario.
    2. CONTEXTO      las filas recuperadas se convierten en texto, con
                     identificadores [R12] / [M7] para poder citarlas.
    3. PROMPT        se monta con reglas, perfil, pregunta y contexto, y se
                     guarda en dbo.RagSession (trazabilidad).
    4. GENERACIÓN    PASO MANUAL: se pega el prompt en GitHub Copilot Chat
                     (no se puede llamar a Copilot desde T-SQL).
    5. REGISTRO      usp_RecordRagAnswer guarda la respuesta.
    6. VERIFICACIÓN  usp_VerifyRagAnswer comprueba en SQL que la respuesta
                     solo menciona elementos recuperados y sin conflicto
                     de alérgenos ni de edad.
  Con @WithContext = 0 se genera el prompt SIN contexto (línea base de
  un LLM "a pelo") para compararlo con RAG.

  Errores: 50010 usuario, 50030 identidad, 50041 pregunta vacía,
           50042 sesión RAG inexistente.
  Limitación: el catálogo y la búsqueda están en inglés (MiniLM);
  la pregunta debe escribirse en inglés y la respuesta se pide en español.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.RagSession', N'U') IS NULL
    CREATE TABLE dbo.RagSession (
        RagId         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_RagSession PRIMARY KEY,
        UserId        INT           NOT NULL CONSTRAINT FK_RagSession_Users REFERENCES dbo.Users(UserId),
        Question      NVARCHAR(300) NOT NULL,
        WithContext   BIT           NOT NULL,
        RecipeIds     NVARCHAR(200) NULL,          -- ids recuperados, separados por coma
        MovieIds      NVARCHAR(200) NULL,
        Prompt        NVARCHAR(MAX) NOT NULL,
        CreatedAt     DATETIME2(0)  NOT NULL CONSTRAINT DF_RagSession_Created DEFAULT SYSUTCDATETIME(),
        Answer        NVARCHAR(MAX) NULL,
        AnswerSource  NVARCHAR(100) NULL,          -- modelo mostrado por Copilot Chat
        AnsweredAt    DATETIME2(0)  NULL
    );
GO

/*--------------------------------------------------------------
  usp_BuildRagPrompt
--------------------------------------------------------------*/
CREATE OR ALTER PROCEDURE dbo.usp_BuildRagPrompt
    @Question    NVARCHAR(300),
    @UserId      INT,
    @TopRecipes  INT = 3,
    @TopMovies   INT = 3,
    @WithContext BIT = 1,
    @RagId       INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NULLIF(LTRIM(RTRIM(@Question)), N'') IS NULL THROW 50041, N'La pregunta no puede estar vacía.', 1;

    IF IS_MEMBER(N'db_owner') = 0
       AND NOT EXISTS (SELECT 1 FROM dbo.UserPrincipals
                       WHERE UserId = @UserId AND PrincipalName = USER_NAME())
        THROW 50030, N'No autorizado: solo puedes actuar en tu propio nombre.', 1;

    DECLARE @age INT, @allergens NVARCHAR(400);
    SELECT @age = Age, @allergens = Allergens FROM dbo.vw_UserProfile WHERE UserId = @UserId;
    IF @age IS NULL THROW 50010, N'El usuario no existe.', 1;

    CREATE TABLE #r (Pos INT IDENTITY, RecipeId INT, Name NVARCHAR(200), PrepMin INT, Difficulty NVARCHAR(50),
                     Score DECIMAL(9,6), VectorRank INT, TextRank INT, IngredientRank INT, CosineDistance FLOAT);
    CREATE TABLE #m (Pos INT IDENTITY, MovieId INT, Title NVARCHAR(200), ReleaseYear INT, MinAge INT,
                     Score DECIMAL(9,6), VectorRank INT, TextRank INT, CosineDistance FLOAT);

    DECLARE @recCtx NVARCHAR(MAX) = N'', @movCtx NVARCHAR(MAX) = N'',
            @recIds NVARCHAR(200) = NULL, @movIds NVARCHAR(200) = NULL;

    IF @WithContext = 1
    BEGIN
        -- 1. Recuperación (ya filtrada por alergias y edad del usuario)
        INSERT #r (RecipeId, Name, PrepMin, Difficulty, Score, VectorRank, TextRank, IngredientRank, CosineDistance)
        EXEC dbo.usp_SearchRecipes @Query = @Question, @UserId = @UserId, @Top = @TopRecipes;

        INSERT #m (MovieId, Title, ReleaseYear, MinAge, Score, VectorRank, TextRank, CosineDistance)
        EXEC dbo.usp_SearchMovies @Query = @Question, @UserId = @UserId, @Top = @TopMovies;

        -- 2. Contexto
        SELECT @recCtx = STRING_AGG(CAST(CONCAT(N'[R', r.RecipeId, N'] ', rec.Name, N' (', rec.PrepMin, N' min, difficulty ',
                                    rec.Difficulty, N'). ', rec.Description, N' Ingredients: ', rs.Ingredients,
                                    N'. Allergens: ', ra.Allergens, N'.') AS NVARCHAR(MAX)), NCHAR(10))
                         WITHIN GROUP (ORDER BY r.Pos),
               @recIds = STRING_AGG(CAST(r.RecipeId AS NVARCHAR(10)), N',') WITHIN GROUP (ORDER BY r.Pos)
        FROM #r AS r
        JOIN dbo.Recipes            AS rec ON rec.RecipeId = r.RecipeId
        JOIN dbo.vw_RecipeSearchText AS rs ON rs.RecipeId  = r.RecipeId
        JOIN dbo.vw_RecipeAllergens  AS ra ON ra.RecipeId  = r.RecipeId;

        SELECT @movCtx = STRING_AGG(CAST(CONCAT(N'[M', m.MovieId, N'] ', mv.Title, N' (', mv.ReleaseYear, N', minimum age ',
                                    mv.MinAge, N', ', ms.Genres, N'). ', mv.Synopsis) AS NVARCHAR(MAX)), NCHAR(10))
                         WITHIN GROUP (ORDER BY m.Pos),
               @movIds = STRING_AGG(CAST(m.MovieId AS NVARCHAR(10)), N',') WITHIN GROUP (ORDER BY m.Pos)
        FROM #m AS m
        JOIN dbo.Movies             AS mv ON mv.MovieId = m.MovieId
        JOIN dbo.vw_MovieSearchText AS ms ON ms.MovieId = m.MovieId;

        SET @recCtx = COALESCE(@recCtx, N'(none found)');
        SET @movCtx = COALESCE(@movCtx, N'(none found)');
    END;

    -- 3. Prompt
    DECLARE @nl NCHAR(1) = NCHAR(10), @prompt NVARCHAR(MAX);

    IF @WithContext = 1
        SET @prompt = CONCAT(
            N'You are CineChef, an assistant that plans a movie night: one movie plus one recipe to cook while watching it.', @nl,
            N'Use ONLY the information in the CONTEXT below. Rules:', @nl,
            N'1. Recommend exactly one movie and one recipe from the context and cite them by id, for example [R12] and [M7].', @nl,
            N'2. Never suggest a recipe or movie that is not in the context.', @nl,
            N'3. Respect the user profile: never suggest anything containing the allergens listed there.', @nl,
            N'4. If nothing in the context fits the question, say so instead of inventing an answer.', @nl,
            N'5. Answer in Spanish, in at most 120 words.', @nl, @nl,
            N'USER PROFILE: age ', @age, N'; allergens to avoid: ', @allergens, N'.', @nl,
            N'QUESTION: ', @Question, @nl, @nl,
            N'CONTEXT', @nl, N'Recipes:', @nl, @recCtx, @nl, @nl, N'Movies:', @nl, @movCtx);
    ELSE
        SET @prompt = CONCAT(
            N'You are CineChef, an assistant that plans a movie night: one movie plus one recipe to cook while watching it.', @nl,
            N'Recommend exactly one movie and one recipe. Respect the user profile: never suggest anything containing the allergens listed there.', @nl,
            N'You have no catalogue available: answer from your general knowledge and do not ask for more information.', @nl,
            N'Answer in Spanish, in at most 120 words.', @nl, @nl,
            N'USER PROFILE: age ', @age, N'; allergens to avoid: ', @allergens, N'.', @nl,
            N'QUESTION: ', @Question);

    INSERT dbo.RagSession (UserId, Question, WithContext, RecipeIds, MovieIds, Prompt)
    VALUES (@UserId, @Question, @WithContext, @recIds, @movIds, @prompt);
    SET @RagId = SCOPE_IDENTITY();

    -- Salida: el prompt línea a línea (copiar la columna entera evita perder los saltos de línea)
    SELECT @RagId AS RagId, @WithContext AS WithContext, @recIds AS RecipeIds, @movIds AS MovieIds;
    SELECT s.value AS PromptLine FROM STRING_SPLIT(@prompt, @nl, 1) AS s ORDER BY s.ordinal;
END;
GO

/*--------------------------------------------------------------
  usp_RecordRagAnswer: guarda la respuesta pegada desde Copilot Chat
--------------------------------------------------------------*/
CREATE OR ALTER PROCEDURE dbo.usp_RecordRagAnswer
    @RagId        INT,
    @Answer       NVARCHAR(MAX),
    @AnswerSource NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @uid INT = (SELECT UserId FROM dbo.RagSession WHERE RagId = @RagId);
    IF @uid IS NULL THROW 50042, N'La sesión RAG no existe.', 1;

    IF IS_MEMBER(N'db_owner') = 0
       AND NOT EXISTS (SELECT 1 FROM dbo.UserPrincipals WHERE UserId = @uid AND PrincipalName = USER_NAME())
        THROW 50030, N'No autorizado: solo puedes actuar en tu propio nombre.', 1;

    UPDATE dbo.RagSession
    SET Answer = @Answer, AnswerSource = @AnswerSource, AnsweredAt = SYSUTCDATETIME()
    WHERE RagId = @RagId;
END;
GO

/*--------------------------------------------------------------
  usp_VerifyRagAnswer
  Detecta en la respuesta (a) las citas por id que el prompt pide, como
  [R80] o [M5], y (b) los nombres de recetas y películas del catálogo
  escritos tal cual. Copilot responde en español y suele traducir los
  nombres, por eso la cita por id es la señal principal.
  Después comprueba: ¿estaban en el contexto recuperado?, ¿contiene la receta
  alérgenos del usuario?, ¿es la película apta por edad?
  Limitaciones: un nombre traducido o parafraseado sin cita por id no se
  detecta; un título con puntos (E.T.) tampoco; los ids citados que no
  existen en el catálogo se ignoran.
--------------------------------------------------------------*/
CREATE OR ALTER PROCEDURE dbo.usp_VerifyRagAnswer
    @RagId      INT,
    @ShowVerdict BIT = 1      -- 0 = solo el detalle (para INSERT ... EXEC en las pruebas)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @uid INT, @ans NVARCHAR(MAX), @recIds NVARCHAR(200), @movIds NVARCHAR(200), @withCtx BIT;
    SELECT @uid = UserId, @ans = Answer, @recIds = RecipeIds, @movIds = MovieIds, @withCtx = WithContext
    FROM dbo.RagSession WHERE RagId = @RagId;
    IF @uid IS NULL THROW 50042, N'La sesión RAG no existe.', 1;

    IF IS_MEMBER(N'db_owner') = 0
       AND NOT EXISTS (SELECT 1 FROM dbo.UserPrincipals WHERE UserId = @uid AND PrincipalName = USER_NAME())
        THROW 50030, N'No autorizado: solo puedes actuar en tu propio nombre.', 1;

    DECLARE @age INT = (SELECT Age FROM dbo.vw_UserProfile WHERE UserId = @uid);
    DECLARE @from NVARCHAR(30) = N'.,;:!?()"*[]/-';
    DECLARE @norm NVARCHAR(MAX) = CONCAT(N' ', TRANSLATE(COALESCE(@ans, N''), @from, REPLICATE(N' ', LEN(@from))), N' ');

    CREATE TABLE #v (Kind NVARCHAR(10), Id INT, Name NVARCHAR(200), InContext BIT, Problem NVARCHAR(400), FoundBy NVARCHAR(20));

    -- Citas por id: el texto se parte por '[' y se miran trozos del tipo R80] / M5]
    CREATE TABLE #cite (Kind CHAR(1), Id INT);
    INSERT #cite
    SELECT DISTINCT LEFT(p.value, 1), TRY_CAST(SUBSTRING(p.value, 2, CHARINDEX(N']', p.value) - 2) AS INT)
    FROM STRING_SPLIT(COALESCE(@ans, N''), N'[') AS p
    WHERE LEFT(p.value, 1) IN (N'R', N'M') AND CHARINDEX(N']', p.value) > 2
      AND TRY_CAST(SUBSTRING(p.value, 2, CHARINDEX(N']', p.value) - 2) AS INT) IS NOT NULL;

    INSERT #v
    SELECT N'recipe', r.RecipeId, r.Name,
           CASE WHEN EXISTS (SELECT 1 FROM STRING_SPLIT(COALESCE(@recIds, N''), N',') AS s WHERE s.value = CAST(r.RecipeId AS NVARCHAR(10)))
                THEN 1 ELSE 0 END,
           (SELECT N'Contains allergen: ' + STRING_AGG(d.Name, N', ')   -- NULL si no hay alérgenos
            FROM (SELECT DISTINCT a.Name
                  FROM dbo.RecipeIngredients AS ri
                  JOIN dbo.IngredientAllergens AS ia ON ia.IngredientId = ri.IngredientId
                  JOIN dbo.UserAllergies       AS ua ON ua.AllergenId = ia.AllergenId AND ua.UserId = @uid
                  JOIN dbo.Allergens           AS a  ON a.AllergenId = ia.AllergenId
                  WHERE ri.RecipeId = r.RecipeId) AS d),
           CONCAT(CASE WHEN f.nm = 1 THEN N'name' END, CASE WHEN f.nm = 1 AND f.im = 1 THEN N'+' END, CASE WHEN f.im = 1 THEN N'id' END)
    FROM dbo.Recipes AS r
    CROSS APPLY (SELECT CASE WHEN CHARINDEX(CONCAT(N' ', TRANSLATE(r.Name, @from, REPLICATE(N' ', LEN(@from))), N' '), @norm) > 0 THEN 1 ELSE 0 END AS nm,
                        CASE WHEN EXISTS (SELECT 1 FROM #cite AS c WHERE c.Kind = 'R' AND c.Id = r.RecipeId) THEN 1 ELSE 0 END AS im) AS f
    WHERE f.nm = 1 OR f.im = 1;

    INSERT #v
    SELECT N'movie', m.MovieId, m.Title,
           CASE WHEN EXISTS (SELECT 1 FROM STRING_SPLIT(COALESCE(@movIds, N''), N',') AS s WHERE s.value = CAST(m.MovieId AS NVARCHAR(10)))
                THEN 1 ELSE 0 END,
           CASE WHEN m.MinAge > @age THEN CONCAT(N'Not suitable: minimum age ', m.MinAge, N', user is ', @age) END,
           CONCAT(CASE WHEN f.nm = 1 THEN N'name' END, CASE WHEN f.nm = 1 AND f.im = 1 THEN N'+' END, CASE WHEN f.im = 1 THEN N'id' END)
    FROM dbo.Movies AS m
    CROSS APPLY (SELECT CASE WHEN CHARINDEX(CONCAT(N' ', TRANSLATE(m.Title, @from, REPLICATE(N' ', LEN(@from))), N' '), @norm) > 0 THEN 1 ELSE 0 END AS nm,
                        CASE WHEN EXISTS (SELECT 1 FROM #cite AS c WHERE c.Kind = 'M' AND c.Id = m.MovieId) THEN 1 ELSE 0 END AS im) AS f
    WHERE f.nm = 1 OR f.im = 1;

    SELECT Kind, Id, Name, InContext, Problem, FoundBy FROM #v ORDER BY Kind, Id;

    IF @ShowVerdict = 1
    SELECT CASE
             WHEN @ans IS NULL THEN N'SIN RESPUESTA REGISTRADA'
             WHEN NOT EXISTS (SELECT 1 FROM #v WHERE Kind = N'recipe') OR NOT EXISTS (SELECT 1 FROM #v WHERE Kind = N'movie')
                  THEN N'REVISAR: no se detecta una receta y una película del catálogo en la respuesta (cita por id o nombre)'
             WHEN EXISTS (SELECT 1 FROM #v WHERE Problem IS NOT NULL) THEN N'REVISAR: conflicto de alérgenos o de edad'
             WHEN @withCtx = 1 AND EXISTS (SELECT 1 FROM #v WHERE InContext = 0) THEN N'REVISAR: menciona elementos que no estaban en el contexto'
             ELSE N'OK'
           END AS Verdict,
           (SELECT COUNT(*) FROM #v WHERE InContext = 0) AS MencionadosFueraDeContexto;
END;
GO

/*-------- Permisos --------*/
GRANT EXECUTE ON dbo.usp_BuildRagPrompt   TO role_customer;
GRANT EXECUTE ON dbo.usp_RecordRagAnswer  TO role_customer;
GRANT EXECUTE ON dbo.usp_VerifyRagAnswer  TO role_customer;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.RagSession TO role_customer, role_nutritionist, role_analyst;
GO
