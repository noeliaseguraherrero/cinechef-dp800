/*==============================================================
  CineChef - Fase 5: diagnóstico de la calidad de los embeddings
  El experimento (04) mostró distancias muy comprimidas: los cinco primeros
  resultados de una consulta estaban entre 0,12 y 0,14. Este script mide
  cómo se reparten las distancias entre TODOS los pares de películas y entre
  películas y recetas, para documentarlo con números.
  Solo lectura. Requiere haber ejecutado 04_embedding_experiment.sql.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

-- 1. Distancia coseno entre pares de películas distintas (variante labeled)
WITH d AS (
    SELECT VECTOR_DISTANCE('cosine', a.Embedding, b.Embedding) AS dist
    FROM dbo.EmbeddingExperiment AS a
    JOIN dbo.EmbeddingExperiment AS b
      ON b.Variant = a.Variant AND b.EntityType = a.EntityType AND a.EntityId < b.EntityId
    WHERE a.Variant = N'labeled' AND a.EntityType = N'movie'
)
SELECT N'película - película' AS pares_de, COUNT(*) AS pares,
       MIN(dist) AS minima, AVG(dist) AS media, MAX(dist) AS maxima, STDEV(dist) AS desviacion
FROM d;

-- 2. Distancia coseno entre una película y una receta (los dos catálogos comparten el mismo espacio)
WITH d AS (
    SELECT VECTOR_DISTANCE('cosine', m.Embedding, r.Embedding) AS dist
    FROM dbo.EmbeddingExperiment AS m
    JOIN dbo.EmbeddingExperiment AS r ON r.Variant = m.Variant
    WHERE m.Variant = N'labeled' AND m.EntityType = N'movie' AND r.EntityType = N'recipe'
)
SELECT N'película - receta' AS pares_de, COUNT(*) AS pares,
       MIN(dist) AS minima, AVG(dist) AS media, MAX(dist) AS maxima, STDEV(dist) AS desviacion
FROM d;

-- 3. Distancia entre cada sonda en inglés y su película esperada frente a la media de todas las demás
SELECT p.ProbeId, e.EntityName AS esperada,
       VECTOR_DISTANCE('cosine', e.Embedding, p.QueryEmbedding) AS dist_esperada,
       (SELECT AVG(VECTOR_DISTANCE('cosine', e2.Embedding, p.QueryEmbedding))
        FROM dbo.EmbeddingExperiment AS e2
        WHERE e2.Variant = N'labeled' AND e2.EntityType = N'movie') AS dist_media_catalogo
FROM dbo.EmbeddingProbe AS p
JOIN dbo.EmbeddingExperiment AS e
  ON e.Variant = N'labeled' AND e.EntityType = p.EntityType AND e.EntityName LIKE p.ExpectedPattern
WHERE p.Lang = N'en' AND p.EntityType = N'movie'
ORDER BY p.ProbeId;
GO
