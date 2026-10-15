/*==============================================================
  CineChef - Fase 1: validación del modelo de embeddings
  1) Comprueba que los vectores tienen 384 dimensiones.
  2) Comprueba que el modelo capta significado: frases parecidas
     deben tener MENOR distancia coseno que frases distintas.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

-- 1) Dimensión: la asignación falla si el vector no tiene 384 componentes
DECLARE @v VECTOR(384) = AI_GENERATE_EMBEDDINGS(N'Test Text' USE MODEL CineChefEmbeddingModel);
SELECT N'Dimensión 384 verificada' AS prueba, N'OK' AS resultado;

-- 2) Similitud semántica (distancia coseno: 0 = idénticos, mayor = más distintos)
DECLARE @base  VECTOR(384) = AI_GENERATE_EMBEDDINGS(N'A calm and comforting movie to relax on the sofa' USE MODEL CineChefEmbeddingModel);
DECLARE @cerca VECTOR(384) = AI_GENERATE_EMBEDDINGS(N'A cozy, soothing film for a quiet evening at home'   USE MODEL CineChefEmbeddingModel);
DECLARE @lejos VECTOR(384) = AI_GENERATE_EMBEDDINGS(N'A violent action thriller full of explosions and car chases' USE MODEL CineChefEmbeddingModel);

SELECT
    VECTOR_DISTANCE('cosine', @base, @cerca) AS distancia_frase_parecida,   -- debe ser la menor
    VECTOR_DISTANCE('cosine', @base, @lejos) AS distancia_frase_distinta,   -- debe ser mayor
    CASE WHEN VECTOR_DISTANCE('cosine', @base, @cerca) < VECTOR_DISTANCE('cosine', @base, @lejos)
         THEN N'OK' ELSE N'FALLO' END AS resultado;
GO
