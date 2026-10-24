/*==============================================================
  CineChef - Fase 5: pruebas de los embeddings almacenados
  Requiere haber ejecutado ai/05_generate_embeddings.sql.
  Falla (THROW) si alguna prueba da REVISAR.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

DROP TABLE IF EXISTS #c;   -- permite repetir el script en la misma sesión tras un fallo
CREATE TABLE #c (id INT IDENTITY, prueba NVARCHAR(150), resultado NVARCHAR(10), detalle NVARCHAR(200));

-- 1. Todos los registros tienen embedding
INSERT #c (prueba, resultado, detalle)
SELECT N'Movies: 100 filas, todas con embedding',
       IIF(COUNT(*) = 100 AND SUM(CASE WHEN Embedding IS NULL THEN 1 ELSE 0 END) = 0, N'OK', N'REVISAR'),
       CONCAT(COUNT(*), N' filas, ', SUM(CASE WHEN Embedding IS NULL THEN 1 ELSE 0 END), N' sin embedding')
FROM dbo.Movies;

INSERT #c (prueba, resultado, detalle)
SELECT N'Recipes: 100 filas, todas con embedding',
       IIF(COUNT(*) = 100 AND SUM(CASE WHEN Embedding IS NULL THEN 1 ELSE 0 END) = 0, N'OK', N'REVISAR'),
       CONCAT(COUNT(*), N' filas, ', SUM(CASE WHEN Embedding IS NULL THEN 1 ELSE 0 END), N' sin embedding')
FROM dbo.Recipes;

-- 2. Distancia de cada vector consigo mismo = 0 (vectores válidos, no nulos ni corruptos)
DECLARE @selfM FLOAT = (SELECT MAX(ABS(VECTOR_DISTANCE('cosine', Embedding, Embedding))) FROM dbo.Movies);
DECLARE @selfR FLOAT = (SELECT MAX(ABS(VECTOR_DISTANCE('cosine', Embedding, Embedding))) FROM dbo.Recipes);
INSERT #c (prueba, resultado, detalle) VALUES
 (N'Movies: distancia coseno de cada vector consigo mismo ~ 0', IIF(@selfM <= 0.0001, N'OK', N'REVISAR'), CONCAT(N'máximo ', @selfM)),
 (N'Recipes: distancia coseno de cada vector consigo mismo ~ 0', IIF(@selfR <= 0.0001, N'OK', N'REVISAR'), CONCAT(N'máximo ', @selfR));

-- 3. Registro de las ejecuciones (modelo, variante y dimensión)
INSERT #c (prueba, resultado, detalle)
SELECT N'EmbeddingRun: última ejecución de películas y recetas con 100 filas y 384 dimensiones',
       IIF((SELECT TOP 1 RowsEmbedded FROM dbo.EmbeddingRun WHERE EntityType = N'movie'  ORDER BY RunId DESC) = 100
       AND (SELECT TOP 1 RowsEmbedded FROM dbo.EmbeddingRun WHERE EntityType = N'recipe' ORDER BY RunId DESC) = 100
       AND (SELECT TOP 1 Dimensions   FROM dbo.EmbeddingRun ORDER BY RunId DESC) = 384, N'OK', N'REVISAR'),
       (SELECT TOP 1 Variant FROM dbo.EmbeddingRun ORDER BY RunId DESC);

-- 4. Reproducibilidad: volver a generar el embedding del mismo texto da el mismo vector que el almacenado
DECLARE @vm NVARCHAR(20) = (SELECT TOP 1 Variant FROM dbo.EmbeddingRun WHERE EntityType = N'movie'  ORDER BY RunId DESC);
DECLARE @vr NVARCHAR(20) = (SELECT TOP 1 Variant FROM dbo.EmbeddingRun WHERE EntityType = N'recipe' ORDER BY RunId DESC);

-- AI_GENERATE_EMBEDDINGS solo devuelve VECTOR al asignarse a una columna/variable VECTOR
-- (usado directamente dentro de VECTOR_DISTANCE da error 8116), por eso se pasa por una tabla temporal.
DROP TABLE IF EXISTS #rep;
CREATE TABLE #rep (Kind CHAR(1), Id INT, Stored VECTOR(384), Txt NVARCHAR(MAX), Regen VECTOR(384) NULL);

INSERT #rep (Kind, Id, Stored, Txt)
SELECT TOP (5) 'M', m.MovieId, m.Embedding,
       CASE @vm WHEN N'labeled' THEN s.SearchText WHEN N'unlabeled' THEN CONCAT(s.Genres, N'. ', m.Synopsis) ELSE m.Synopsis END
FROM dbo.Movies AS m JOIN dbo.vw_MovieSearchText AS s ON s.MovieId = m.MovieId ORDER BY m.MovieId;

INSERT #rep (Kind, Id, Stored, Txt)
SELECT TOP (5) 'R', r.RecipeId, r.Embedding,
       CASE @vr WHEN N'labeled' THEN s.SearchText WHEN N'unlabeled' THEN CONCAT(r.Description, N' ', s.Ingredients) ELSE r.Description END
FROM dbo.Recipes AS r JOIN dbo.vw_RecipeSearchText AS s ON s.RecipeId = r.RecipeId ORDER BY r.RecipeId;

UPDATE #rep SET Regen = AI_GENERATE_EMBEDDINGS(Txt USE MODEL CineChefEmbeddingModel);

DECLARE @repM FLOAT = (SELECT MAX(VECTOR_DISTANCE('cosine', Stored, Regen)) FROM #rep WHERE Kind = 'M');
DECLARE @repR FLOAT = (SELECT MAX(VECTOR_DISTANCE('cosine', Stored, Regen)) FROM #rep WHERE Kind = 'R');
DROP TABLE #rep;

INSERT #c (prueba, resultado, detalle) VALUES
 (N'Reproducibilidad (películas): regenerar el texto da el vector almacenado', IIF(@repM <= 0.0001, N'OK', N'REVISAR'), CONCAT(N'variante ', @vm, N', distancia máxima ', @repM)),
 (N'Reproducibilidad (recetas): regenerar el texto da el vector almacenado',   IIF(@repR <= 0.0001, N'OK', N'REVISAR'), CONCAT(N'variante ', @vr, N', distancia máxima ', @repR));

-- 5. Los vectores distinguen elementos: ninguna pareja distinta tiene distancia 0 (sin duplicados de vector)
INSERT #c (prueba, resultado, detalle)
SELECT N'Movies: no hay dos películas distintas con el mismo vector',
       IIF(COUNT(*) = 0, N'OK', N'REVISAR'), CONCAT(COUNT(*), N' parejas con distancia ~ 0')
FROM dbo.Movies AS a JOIN dbo.Movies AS b ON a.MovieId < b.MovieId
WHERE VECTOR_DISTANCE('cosine', a.Embedding, b.Embedding) < 0.000001;

SELECT prueba, resultado, detalle FROM #c ORDER BY id;

IF EXISTS (SELECT 1 FROM #c WHERE resultado <> N'OK')
    THROW 50005, N'Alguna prueba de embeddings (Fase 5) ha dado REVISAR.', 1;

DROP TABLE #c;
GO
