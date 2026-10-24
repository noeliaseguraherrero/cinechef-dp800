/*==============================================================
  CineChef - Fase 5 (Bloque E): experimento de formato del texto
  Pregunta: ¿qué texto conviene convertir en embedding?
    labeled    "Genres: Drama, Romance. <sinopsis>"   (como las vistas vw_*SearchText)
    unlabeled  "Drama, Romance. <sinopsis>"            (géneros sin etiqueta)
    plain      "<sinopsis>"                            (solo la sinopsis)
  Para recetas: descripción + "Ingredients: ..." / sin etiqueta / solo descripción.

  Método: se generan los tres vectores de cada película y receta en una tabla
  aparte (dbo.EmbeddingExperiment) y se mide, con consultas de prueba (sondas)
  de las que se conoce la película esperada, en qué posición del ranking aparece.
    hit@k = proporción de sondas con la esperada entre las k primeras
    MRR   = media de 1/posición (1 = siempre primera; azar con 100 elementos ~0,05)

  Requiere el modelo CineChefEmbeddingModel (ai/02) y las vistas (04_views).
  Tiempo: unas 600 llamadas al modelo; puede tardar de segundos a unos minutos.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

DROP TABLE IF EXISTS dbo.EmbeddingExperiment;
DROP TABLE IF EXISTS dbo.EmbeddingProbe;
GO

CREATE TABLE dbo.EmbeddingExperiment (
    Variant    NVARCHAR(20)  NOT NULL,
    EntityType NVARCHAR(10)  NOT NULL,
    EntityId   INT           NOT NULL,
    EntityName NVARCHAR(200) NOT NULL,
    Embedding  VECTOR(384)   NOT NULL,
    CONSTRAINT PK_EmbeddingExperiment PRIMARY KEY (Variant, EntityType, EntityId),
    CONSTRAINT CK_EmbeddingExperiment_Variant CHECK (Variant IN (N'labeled', N'unlabeled', N'plain')),
    CONSTRAINT CK_EmbeddingExperiment_Type    CHECK (EntityType IN (N'movie', N'recipe'))
);

CREATE TABLE dbo.EmbeddingProbe (
    ProbeId         INT           NOT NULL CONSTRAINT PK_EmbeddingProbe PRIMARY KEY,
    EntityType      NVARCHAR(10)  NOT NULL,
    Lang            NCHAR(2)      NOT NULL,
    QueryText       NVARCHAR(400) NOT NULL,
    ExpectedPattern NVARCHAR(200) NOT NULL,   -- patrón LIKE del título/nombre esperado
    QueryEmbedding  VECTOR(384)   NULL
);
GO

/*-------- 1. Vectores de las tres variantes: películas --------*/
INSERT dbo.EmbeddingExperiment (Variant, EntityType, EntityId, EntityName, Embedding)
SELECT v.Variant, N'movie', m.MovieId, m.Title,
       AI_GENERATE_EMBEDDINGS(
           CASE v.Variant
               WHEN N'labeled'   THEN s.SearchText
               WHEN N'unlabeled' THEN CONCAT(s.Genres, N'. ', m.Synopsis)
               ELSE m.Synopsis
           END
           USE MODEL CineChefEmbeddingModel)
FROM dbo.Movies AS m
JOIN dbo.vw_MovieSearchText AS s ON s.MovieId = m.MovieId
CROSS JOIN (VALUES (N'labeled'), (N'unlabeled'), (N'plain')) AS v(Variant);

/*-------- 2. Vectores de las tres variantes: recetas --------*/
INSERT dbo.EmbeddingExperiment (Variant, EntityType, EntityId, EntityName, Embedding)
SELECT v.Variant, N'recipe', r.RecipeId, r.Name,
       AI_GENERATE_EMBEDDINGS(
           CASE v.Variant
               WHEN N'labeled'   THEN s.SearchText
               WHEN N'unlabeled' THEN CONCAT(r.Description, N' ', s.Ingredients)
               ELSE r.Description
           END
           USE MODEL CineChefEmbeddingModel)
FROM dbo.Recipes AS r
JOIN dbo.vw_RecipeSearchText AS s ON s.RecipeId = r.RecipeId
CROSS JOIN (VALUES (N'labeled'), (N'unlabeled'), (N'plain')) AS v(Variant);
GO

/*-------- 3. Sondas de películas --------
  Las 10 películas esperadas están en el catálogo (aparecieron en la muestra de validación).
  Las consultas describen el tono, igual que se escribieron las sinopsis; no son argumentos.
  Hay también 3 sondas en español para medir cuánto pierde el modelo (entrenado sobre todo en inglés). */
INSERT dbo.EmbeddingProbe (ProbeId, EntityType, Lang, QueryText, ExpectedPattern) VALUES
 (1,  N'movie', N'en', N'A tender, magical story of friendship between a lonely child and a visitor from another world', N'E.T.%'),
 (2,  N'movie', N'en', N'A dark, anarchic and darkly funny story about rebellion against consumer culture and masculinity', N'Fight Club'),
 (3,  N'movie', N'en', N'A quiet, melancholic and reflective journey through memory and regret in old age', N'Wild Strawberries'),
 (4,  N'movie', N'en', N'A tense, ambiguous drama where truth is impossible to pin down because everyone tells a different version', N'Rashomon'),
 (5,  N'movie', N'en', N'An elegant, poetic martial arts fantasy mixing swordplay with restrained romance', N'Crouching Tiger%'),
 (6,  N'movie', N'en', N'A cold, vast, hypnotic science fiction odyssey about space, evolution and artificial intelligence', N'2001%'),
 (7,  N'movie', N'en', N'A bitter, tragicomic clash between a free spirit and an oppressive institution', N'One Flew Over%'),
 (8,  N'movie', N'en', N'An intimate, tender and quietly devastating coming-of-age story about identity and longing', N'Moonlight'),
 (9,  N'movie', N'en', N'A brutal, raw and unflinching portrait of a violent man destroyed by his own jealousy and rage', N'Raging Bull'),
 (10, N'movie', N'en', N'A harrowing, solemn historical drama about courage and moral choice during the Holocaust', N'Schindler%'),
 (11, N'movie', N'es', N'Una historia tierna y mágica de amistad entre un niño solitario y un visitante de otro mundo', N'E.T.%'),
 (12, N'movie', N'es', N'Una historia oscura, anárquica y de humor negro sobre la rebelión contra el consumismo y la masculinidad', N'Fight Club'),
 (13, N'movie', N'es', N'Un viaje tranquilo, melancólico y reflexivo por la memoria y el arrepentimiento en la vejez', N'Wild Strawberries');

/*-------- 3b. SONDAS DE RECETAS (rellénalas tú) --------
  Las recetas las generó Copilot y no las conozco. Lista algunas con:
      SELECT TOP (40) Name FROM dbo.Recipes ORDER BY NEWID();
  y escribe 5-6 consultas "de ambiente" cuya receta esperada tengas clara. Ejemplo (cambia el patrón):

  INSERT dbo.EmbeddingProbe (ProbeId, EntityType, Lang, QueryText, ExpectedPattern) VALUES
   (101, N'recipe', N'en', N'A warm, comforting bowl for a cold rainy evening', N'%<nombre real de una receta>%');
*/

/*-------- 4. Vectores de las consultas --------*/
UPDATE dbo.EmbeddingProbe
SET QueryEmbedding = AI_GENERATE_EMBEDDINGS(QueryText USE MODEL CineChefEmbeddingModel);
GO

/*==================== EVALUACIÓN ====================*/

-- E1. Control de la propia prueba: cada patrón debe coincidir con UN elemento (esperado: 0 filas)
SELECT p.ProbeId, p.ExpectedPattern, COUNT(DISTINCT e.EntityId) AS coincidencias
FROM dbo.EmbeddingProbe AS p
LEFT JOIN dbo.EmbeddingExperiment AS e
       ON e.EntityType = p.EntityType AND e.Variant = N'labeled' AND e.EntityName LIKE p.ExpectedPattern
GROUP BY p.ProbeId, p.ExpectedPattern
HAVING COUNT(DISTINCT e.EntityId) <> 1;

-- Posición de la película/receta esperada para cada sonda y variante
DROP TABLE IF EXISTS #ranks;
WITH d AS (
    SELECT p.ProbeId, p.Lang, p.EntityType, p.ExpectedPattern, e.Variant, e.EntityName,
           VECTOR_DISTANCE('cosine', e.Embedding, p.QueryEmbedding) AS Dist
    FROM dbo.EmbeddingProbe AS p
    JOIN dbo.EmbeddingExperiment AS e ON e.EntityType = p.EntityType
), r AS (
    SELECT d.*, RANK() OVER (PARTITION BY d.ProbeId, d.Variant ORDER BY d.Dist) AS Rnk
    FROM d
)
SELECT r.ProbeId, r.Lang, r.EntityType, r.Variant, r.EntityName AS ExpectedTitle, r.Rnk
INTO #ranks
FROM r
WHERE r.EntityName LIKE r.ExpectedPattern;

-- E2. Detalle por sonda: posición de la esperada en cada variante (1 = la mejor)
SELECT r.ProbeId, r.Lang, r.ExpectedTitle,
       MAX(CASE WHEN r.Variant = N'labeled'   THEN r.Rnk END) AS pos_labeled,
       MAX(CASE WHEN r.Variant = N'unlabeled' THEN r.Rnk END) AS pos_unlabeled,
       MAX(CASE WHEN r.Variant = N'plain'     THEN r.Rnk END) AS pos_plain
FROM #ranks AS r
GROUP BY r.ProbeId, r.Lang, r.ExpectedTitle
ORDER BY r.ProbeId;

-- E3. Resumen por tipo, idioma y variante (el azar daría un MRR de ~0,05)
SELECT r.EntityType, r.Lang, r.Variant,
       COUNT(*)                          AS sondas,
       SUM(IIF(r.Rnk = 1, 1, 0))         AS hit_at_1,
       SUM(IIF(r.Rnk <= 3, 1, 0))        AS hit_at_3,
       SUM(IIF(r.Rnk <= 5, 1, 0))        AS hit_at_5,
       CAST(AVG(1.0 / r.Rnk) AS DECIMAL(5,3)) AS MRR
FROM #ranks AS r
GROUP BY r.EntityType, r.Lang, r.Variant
ORDER BY r.EntityType, r.Lang, MRR DESC;

-- E4. Vista cualitativa: los 5 primeros resultados de una sonda en una variante (cambia los dos valores)
DECLARE @probe INT = 1, @variant NVARCHAR(20) = N'labeled';
SELECT TOP (5) p.QueryText, e.EntityName AS resultado,
       VECTOR_DISTANCE('cosine', e.Embedding, p.QueryEmbedding) AS distancia
FROM dbo.EmbeddingProbe AS p
JOIN dbo.EmbeddingExperiment AS e ON e.EntityType = p.EntityType AND e.Variant = @variant
WHERE p.ProbeId = @probe
ORDER BY distancia;
GO
