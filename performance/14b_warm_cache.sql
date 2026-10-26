-- ==============================================================
-- CineChef - Fase 8 (Bloque D): búsqueda vectorial con caché caliente
-- Requiere haber ejecutado performance/14_vector_index_experiment.sql
-- (índice IX_perf_Items_Embedding creado).
-- Cada bloque se repite 3 veces con "GO 3": la 1.ª ejecución calienta la caché
-- y se anota la ÚLTIMA de las tres (pestaña Mensajes).
-- Capturas (docs/evidencias/08_optimizacion/):
-- vector_exacta_cache_caliente.png   vector_aproximada_cache_caliente.png
-- Anota de cada una: lecturas lógicas de perf.Items, tiempo de CPU y tiempo transcurrido.
-- ==============================================================
USE CineChefDB;
GO
SET NOCOUNT ON;
GO

-- A. Búsqueda EXACTA (escaneo completo)
DECLARE @q VECTOR(384) = (SELECT TOP 1 Embedding FROM perf.Items ORDER BY ItemId DESC);
SET STATISTICS IO, TIME ON;
SELECT TOP (11) ItemId FROM perf.Items ORDER BY VECTOR_DISTANCE('cosine', Embedding, @q);
SET STATISTICS IO, TIME OFF;
GO 3

-- B. Búsqueda APROXIMADA con el índice DiskANN
DECLARE @q2 VECTOR(384) = (SELECT TOP 1 Embedding FROM perf.Items ORDER BY ItemId DESC);
SET STATISTICS IO, TIME ON;
SELECT t.ItemId, s.distance
FROM VECTOR_SEARCH(TABLE = perf.Items AS t, COLUMN = Embedding, SIMILAR_TO = @q2, METRIC = 'cosine', TOP_N = 11) AS s
ORDER BY s.distance;
SET STATISTICS IO, TIME OFF;
GO 3
