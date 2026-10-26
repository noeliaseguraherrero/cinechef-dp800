/*==============================================================
  CineChef - Fase 7: pruebas del RAG
  Requiere: 10_rag.sql. Usa sesiones de prueba (pregunta que empieza
  por 'TEST:') y las borra al final. Falla (THROW) si hay REVISAR.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

DROP TABLE IF EXISTS #c, #o;
CREATE TABLE #c (id INT IDENTITY, prueba NVARCHAR(150), resultado NVARCHAR(10), detalle NVARCHAR(1000));
CREATE TABLE #o (Kind NVARCHAR(10), Id INT, Name NVARCHAR(200), InContext BIT, Problem NVARCHAR(400), FoundBy NVARCHAR(20));

DECLARE @uid INT = (SELECT TOP 1 UserId FROM dbo.vw_UserProfile ORDER BY AllergenCount DESC, UserId);
DECLARE @rag INT, @rag0 INT, @n INT, @unsafe INT;

-- 1. El prompt con contexto trae 3 recetas y 3 películas y las secciones esperadas
EXEC dbo.usp_BuildRagPrompt @Question = N'TEST: comforting dinner for a rainy night with a mystery movie',
                            @UserId = @uid, @RagId = @rag OUTPUT;
INSERT #c (prueba, resultado, detalle)
SELECT N'Prompt RAG: 3 recetas y 3 películas recuperadas, con secciones CONTEXT',
       IIF((SELECT COUNT(*) FROM STRING_SPLIT(RecipeIds, N',')) = 3
           AND (SELECT COUNT(*) FROM STRING_SPLIT(MovieIds, N',')) = 3
           AND Prompt LIKE N'%CONTEXT%Recipes:%Movies:%' AND Prompt LIKE N'%[[]R%' AND Prompt LIKE N'%[[]M%',
           N'OK', N'REVISAR'),
       CONCAT(N'RagId ', RagId, N'; recetas ', RecipeIds, N'; películas ', MovieIds)
FROM dbo.RagSession WHERE RagId = @rag;

-- 2. Lo recuperado respeta alergias y edad del usuario
SELECT @unsafe = COUNT(*)
FROM dbo.RagSession AS s CROSS APPLY STRING_SPLIT(s.RecipeIds, N',') AS x
LEFT JOIN dbo.fn_SafeRecipes(@uid) AS sf ON sf.RecipeId = CAST(x.value AS INT)
WHERE s.RagId = @rag AND sf.RecipeId IS NULL;
SELECT @n = COUNT(*)
FROM dbo.RagSession AS s CROSS APPLY STRING_SPLIT(s.MovieIds, N',') AS x
LEFT JOIN dbo.fn_AllowedMovies(@uid) AS am ON am.MovieId = CAST(x.value AS INT)
WHERE s.RagId = @rag AND am.MovieId IS NULL;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Contexto RAG: ninguna receta insegura ni película no apta para el usuario',
        IIF(@unsafe = 0 AND @n = 0, N'OK', N'REVISAR'), CONCAT(@unsafe, N' recetas inseguras, ', @n, N' películas no aptas'));

-- 3. Línea base sin contexto: no incluye CONTEXT ni ids
EXEC dbo.usp_BuildRagPrompt @Question = N'TEST: comforting dinner for a rainy night with a mystery movie',
                            @UserId = @uid, @WithContext = 0, @RagId = @rag0 OUTPUT;
INSERT #c (prueba, resultado, detalle)
SELECT N'Línea base sin contexto: el prompt no contiene CONTEXT ni ids',
       IIF(Prompt NOT LIKE N'%CONTEXT%' AND Prompt NOT LIKE N'%[[]R%' AND RecipeIds IS NULL AND MovieIds IS NULL, N'OK', N'REVISAR'),
       CONCAT(N'RagId ', RagId)
FROM dbo.RagSession WHERE RagId = @rag0;

-- 4. Verificación: respuesta construida con una receta recuperada, una receta NO recuperada y una insegura
DECLARE @recOk NVARCHAR(200) = (SELECT TOP 1 rec.Name FROM dbo.RagSession s CROSS APPLY STRING_SPLIT(s.RecipeIds, N',') x
                                JOIN dbo.Recipes rec ON rec.RecipeId = CAST(x.value AS INT) WHERE s.RagId = @rag);
DECLARE @movOk NVARCHAR(200) = (SELECT TOP 1 mv.Title FROM dbo.RagSession s CROSS APPLY STRING_SPLIT(s.MovieIds, N',') x
                                JOIN dbo.Movies mv ON mv.MovieId = CAST(x.value AS INT) WHERE s.RagId = @rag);
DECLARE @recBad NVARCHAR(200) = (SELECT TOP 1 r.Name FROM dbo.Recipes r
                                 WHERE NOT EXISTS (SELECT 1 FROM dbo.fn_SafeRecipes(@uid) sf WHERE sf.RecipeId = r.RecipeId)
                                   AND EXISTS (SELECT 1 FROM dbo.RecipeIngredients ri WHERE ri.RecipeId = r.RecipeId)
                                 ORDER BY r.RecipeId);
DECLARE @fake NVARCHAR(MAX) = CONCAT(N'Te recomiendo "', @movOk, N'" con ', @recOk, N' y también ', @recBad, N'.');
EXEC dbo.usp_RecordRagAnswer @RagId = @rag, @Answer = @fake, @AnswerSource = N'prueba automática';

INSERT #o EXEC dbo.usp_VerifyRagAnswer @RagId = @rag, @ShowVerdict = 0;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Verificación: receta recuperada y segura reconocida (en contexto, sin problema)',
        IIF(EXISTS (SELECT 1 FROM #o WHERE Name = @recOk AND InContext = 1 AND Problem IS NULL), N'OK', N'REVISAR'),
        CONCAT(N'esperada: ', @recOk, N' | encontrada: ',
               (SELECT STRING_AGG(CONCAT(Name, N' ctx=', InContext, N' problema=', COALESCE(Problem, N'-')), N' ; ') FROM #o WHERE Name = @recOk)));
INSERT #c (prueba, resultado, detalle)
VALUES (N'Verificación: receta NO recuperada y con alérgenos detectada como fuera de contexto y con problema',
        IIF(EXISTS (SELECT 1 FROM #o WHERE Name = @recBad AND InContext = 0 AND Problem LIKE N'Contains allergen%'), N'OK', N'REVISAR'),
        CONCAT(N'esperada: ', @recBad, N' | encontrada: ',
               (SELECT STRING_AGG(CONCAT(Name, N' ctx=', InContext, N' problema=', COALESCE(Problem, N'-')), N' ; ') FROM #o WHERE Name = @recBad)));
INSERT #c (prueba, resultado, detalle)
VALUES (N'Verificación: película recuperada reconocida',
        IIF(EXISTS (SELECT 1 FROM #o WHERE Kind = N'movie' AND Name = @movOk AND InContext = 1), N'OK', N'REVISAR'),
        CONCAT(N'esperada: ', @movOk));

-- 4b. Cita solo por id, con nombres traducidos (lo que hace Copilot en español)
DECLARE @recId INT = (SELECT TOP 1 CAST(x.value AS INT) FROM dbo.RagSession s CROSS APPLY STRING_SPLIT(s.RecipeIds, N',') x WHERE s.RagId = @rag);
DECLARE @movId INT = (SELECT TOP 1 CAST(x.value AS INT) FROM dbo.RagSession s CROSS APPLY STRING_SPLIT(s.MovieIds, N',') x WHERE s.RagId = @rag);
DECLARE @idAns NVARCHAR(MAX) = CONCAT(N'Prepara la sopa [R', @recId, N'] y mira la película [M', @movId, N'].');
EXEC dbo.usp_RecordRagAnswer @RagId = @rag, @Answer = @idAns, @AnswerSource = N'prueba automática';
TRUNCATE TABLE #o;
INSERT #o EXEC dbo.usp_VerifyRagAnswer @RagId = @rag, @ShowVerdict = 0;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Verificación: reconoce las citas por id aunque los nombres estén traducidos',
        IIF(EXISTS (SELECT 1 FROM #o WHERE Kind = N'recipe' AND Id = @recId AND InContext = 1 AND Problem IS NULL AND FoundBy = N'id')
            AND EXISTS (SELECT 1 FROM #o WHERE Kind = N'movie' AND Id = @movId AND InContext = 1 AND FoundBy = N'id'), N'OK', N'REVISAR'),
        CONCAT(N'respuesta: ', @idAns, N' | filas: ', (SELECT COUNT(*) FROM #o)));

-- 5. Un usuario no puede construir un prompt en nombre de otro (50030)
DECLARE @err INT = 0, @other INT;
IF DATABASE_PRINCIPAL_ID(N'cc_kid') IS NULL
    INSERT #c VALUES (N'Identidad: cc_kid no puede generar un prompt para otro usuario', N'AVISO', N'cc_kid no existe');
ELSE
BEGIN
    SELECT TOP 1 @other = UserId FROM dbo.UserPrincipals WHERE PrincipalName <> N'cc_kid' ORDER BY UserId;
    BEGIN TRY
        EXECUTE AS USER = N'cc_kid';
        EXEC dbo.usp_BuildRagPrompt @Question = N'TEST: soup', @UserId = @other;
        REVERT;
    END TRY
    BEGIN CATCH
        SET @err = ERROR_NUMBER();
        REVERT;
    END CATCH;
    INSERT #c VALUES (N'Identidad: cc_kid no puede generar un prompt para otro usuario',
                      IIF(@err = 50030, N'OK', N'REVISAR'), CONCAT(N'error obtenido: ', @err));
END;

-- 6. Usuario inexistente
SET @err = 0;
BEGIN TRY EXEC dbo.usp_BuildRagPrompt @Question = N'TEST: soup', @UserId = -1; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); END CATCH;
INSERT #c VALUES (N'Usuario inexistente: error 50010', IIF(@err = 50010, N'OK', N'REVISAR'), CONCAT(N'error obtenido: ', @err));

DELETE dbo.RagSession WHERE Question LIKE N'TEST:%';

SELECT prueba, resultado, detalle FROM #c ORDER BY id;
IF EXISTS (SELECT 1 FROM #c WHERE resultado = N'REVISAR')
    THROW 50007, N'Alguna prueba del RAG (Fase 7) ha dado REVISAR.', 1;
GO
