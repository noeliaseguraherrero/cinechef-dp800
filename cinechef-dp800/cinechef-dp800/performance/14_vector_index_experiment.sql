/*==============================================================
  CineChef - Fase 8 (Bloque D/E): búsqueda vectorial exacta vs. índice vectorial
  EXPERIMENTAL: CREATE VECTOR INDEX y VECTOR_SEARCH son funciones en vista
  previa de SQL Server 2025 (necesitan PREVIEW_FEATURES = ON). Si tu
  compilación no las admite, cada paso informa del error y el resto del
  script sigue; ese resultado también se documenta.

  Datos: 20 000 vectores ALEATORIOS de 384 dimensiones en perf.Items
  (no son embeddings reales: sirven para medir el COSTE de la búsqueda; la
  calidad semántica ya se evaluó en las Fases 5 y 6). Con vectores aleatorios
  los vecinos más cercanos están poco separados, así que la "recall" del
  índice aproximado aquí es un valor pesimista.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

IF SCHEMA_ID(N'perf') IS NULL EXEC (N'CREATE SCHEMA perf');
GO
DROP TABLE IF EXISTS perf.Items;
CREATE TABLE perf.Items (
    ItemId    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_perf_Items PRIMARY KEY,
    Embedding VECTOR(384)       NOT NULL
);

-- 20 000 vectores aleatorios (puede tardar 1-2 minutos)
INSERT perf.Items (Embedding)
SELECT CAST(CONCAT(N'[', v.csv, N']') AS VECTOR(384))
FROM GENERATE_SERIES(1, 20000) AS n
CROSS APPLY (SELECT STRING_AGG(CAST(CAST(CHECKSUM(NEWID()) / 2147483648.0 AS DECIMAL(9,6)) AS NVARCHAR(12)), N',') AS csv
             FROM GENERATE_SERIES(1, 384) AS d
             WHERE d.value > n.value * 0) AS v;

SELECT COUNT(*) AS Vectores FROM perf.Items;
GO

/*-------- 1. Búsqueda EXACTA (escaneo de todos los vectores) --------*/
DECLARE @q VECTOR(384) = (SELECT TOP 1 Embedding FROM perf.Items ORDER BY ItemId DESC);
DROP TABLE IF EXISTS #exact;
CREATE TABLE #exact (Pos INT IDENTITY, ItemId INT);

SET STATISTICS IO, TIME ON;
INSERT #exact (ItemId)
SELECT TOP (11) ItemId FROM perf.Items ORDER BY VECTOR_DISTANCE('cosine', Embedding, @q);
SET STATISTICS IO, TIME OFF;
-- (el primero es el propio vector de consulta; se descarta al comparar)
GO

/*-------- 2. Índice vectorial (DiskANN) --------*/
BEGIN TRY
    ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_perf_Items_Embedding' AND object_id = OBJECT_ID(N'perf.Items'))
        DROP INDEX IX_perf_Items_Embedding ON perf.Items;
    CREATE VECTOR INDEX IX_perf_Items_Embedding ON perf.Items (Embedding) WITH (METRIC = 'cosine', TYPE = 'DiskANN');
    PRINT N'Índice vectorial creado.';
END TRY
BEGIN CATCH
    PRINT CONCAT(N'AVISO (creación del índice vectorial): ', ERROR_NUMBER(), N' - ', ERROR_MESSAGE());
END CATCH;
GO

/*-------- 3. Búsqueda APROXIMADA con VECTOR_SEARCH --------
   (se puede ejecutar sola, sin repetir las secciones 1 y 2)
   3a. La consulta tal cual, para ver lecturas y tiempo (Mensajes).        */
DECLARE @q2 VECTOR(384) = (SELECT TOP 1 Embedding FROM perf.Items ORDER BY ItemId DESC);
SET STATISTICS IO, TIME ON;
SELECT t.ItemId, s.distance
FROM VECTOR_SEARCH(TABLE = perf.Items AS t, COLUMN = Embedding, SIMILAR_TO = @q2, METRIC = 'cosine', TOP_N = 11) AS s
ORDER BY s.distance;
SET STATISTICS IO, TIME OFF;
GO

/* 3b. Recall: cuántos de los 11 vecinos exactos devuelve el índice.
       Se lanza con SQL dinámico para que un error de compilación de la
       vista previa se capture y no tumbe el script.                        */
DROP TABLE IF EXISTS #ann, #exact2;
CREATE TABLE #ann    (Pos INT IDENTITY, ItemId INT, Distance FLOAT);
CREATE TABLE #exact2 (ItemId INT);
BEGIN TRY
    INSERT #ann (ItemId, Distance)
    EXEC sp_executesql N'
        DECLARE @q VECTOR(384) = (SELECT TOP 1 Embedding FROM perf.Items ORDER BY ItemId DESC);
        SELECT t.ItemId, s.distance
        FROM VECTOR_SEARCH(TABLE = perf.Items AS t, COLUMN = Embedding, SIMILAR_TO = @q, METRIC = ''cosine'', TOP_N = 11) AS s
        ORDER BY s.distance;';

    DECLARE @q3 VECTOR(384) = (SELECT TOP 1 Embedding FROM perf.Items ORDER BY ItemId DESC);
    INSERT #exact2 (ItemId)
    SELECT TOP (11) ItemId FROM perf.Items ORDER BY VECTOR_DISTANCE('cosine', Embedding, @q3);

    SELECT (SELECT COUNT(*) FROM #ann AS a JOIN #exact2 AS e ON e.ItemId = a.ItemId) AS CoincidenEnTop11,
           (SELECT COUNT(*) FROM #ann) AS DevueltosPorElIndice;
END TRY
BEGIN CATCH
    PRINT CONCAT(N'AVISO (VECTOR_SEARCH / recall): ', ERROR_NUMBER(), N' - ', ERROR_MESSAGE());
END CATCH;
GO

/*-------- 4. Limpieza opcional --------
   Un índice vectorial en vista previa puede dejar la tabla de solo lectura.
   DROP TABLE perf.Items;      -- y/o DROP SCHEMA perf tras borrar las tablas perf.*
*/
