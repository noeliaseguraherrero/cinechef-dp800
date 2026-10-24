/*==============================================================
  CineChef - Fase 5 (Bloque E): embeddings definitivos del catálogo
  Rellena Movies.Embedding y Recipes.Embedding con el modelo local
  (CineChefEmbeddingModel, all-MiniLM-L6-v2, 384 dimensiones).

  Texto que se convierte en vector (según @MovieVariant):
    labeled    vw_MovieSearchText.SearchText / vw_RecipeSearchText.SearchText
    unlabeled  géneros + sinopsis / descripción + ingredientes, sin etiquetas
    plain      solo sinopsis / solo descripción

  Elige @MovieVariant con los resultados de 04_embedding_experiment.sql.
  El script es repetible: vuelve a generar todos los vectores y deja
  constancia de cada ejecución en dbo.EmbeddingRun.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.EmbeddingRun', N'U') IS NULL
    CREATE TABLE dbo.EmbeddingRun (
        RunId        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_EmbeddingRun PRIMARY KEY,
        EntityType   NVARCHAR(10)  NOT NULL,
        Variant      NVARCHAR(20)  NOT NULL,
        ModelName    NVARCHAR(100) NOT NULL,
        Dimensions   SMALLINT      NOT NULL,
        RowsEmbedded INT           NOT NULL,
        StartedAt    DATETIME2(0)  NOT NULL,
        FinishedAt   DATETIME2(0)  NOT NULL
    );
GO

/*-------- VARIANTE ELEGIDA POR TIPO (labeled | unlabeled | plain) --------
  Películas: labeled (MRR 0,334 en 04_embedding_experiment.sql).
  Recetas:   plain   (MRR 0,692 frente a 0,579 de labeled en 04b_recipe_probe.sql;
             los ingredientes se buscarán con Full-Text, no con el vector).
  (En 04b la variante se llamaba 'bare'; es la misma que 'plain'.)  */
DECLARE @MovieVariant  NVARCHAR(20) = N'labeled';
DECLARE @RecipeVariant NVARCHAR(20) = N'plain';

IF @MovieVariant NOT IN (N'labeled', N'unlabeled', N'plain')
   OR @RecipeVariant NOT IN (N'labeled', N'unlabeled', N'plain')
    THROW 50050, N'Las variantes deben ser labeled, unlabeled o plain.', 1;

DECLARE @t0 DATETIME2(0), @rows INT;

/*-------- Películas --------*/
SET @t0 = SYSUTCDATETIME();
UPDATE m
SET Embedding = AI_GENERATE_EMBEDDINGS(
        CASE @MovieVariant
            WHEN N'labeled'   THEN s.SearchText
            WHEN N'unlabeled' THEN CONCAT(s.Genres, N'. ', m.Synopsis)
            ELSE m.Synopsis
        END
        USE MODEL CineChefEmbeddingModel)
FROM dbo.Movies AS m
JOIN dbo.vw_MovieSearchText AS s ON s.MovieId = m.MovieId;
SET @rows = @@ROWCOUNT;
INSERT dbo.EmbeddingRun (EntityType, Variant, ModelName, Dimensions, RowsEmbedded, StartedAt, FinishedAt)
VALUES (N'movie', @MovieVariant, N'CineChefEmbeddingModel (all-MiniLM-L6-v2, ONNX local)', 384, @rows, @t0, SYSUTCDATETIME());

/*-------- Recetas --------*/
SET @t0 = SYSUTCDATETIME();
UPDATE r
SET Embedding = AI_GENERATE_EMBEDDINGS(
        CASE @RecipeVariant
            WHEN N'labeled'   THEN s.SearchText
            WHEN N'unlabeled' THEN CONCAT(r.Description, N' ', s.Ingredients)
            ELSE r.Description
        END
        USE MODEL CineChefEmbeddingModel)
FROM dbo.Recipes AS r
JOIN dbo.vw_RecipeSearchText AS s ON s.RecipeId = r.RecipeId;
SET @rows = @@ROWCOUNT;
INSERT dbo.EmbeddingRun (EntityType, Variant, ModelName, Dimensions, RowsEmbedded, StartedAt, FinishedAt)
VALUES (N'recipe', @RecipeVariant, N'CineChefEmbeddingModel (all-MiniLM-L6-v2, ONNX local)', 384, @rows, @t0, SYSUTCDATETIME());
GO

/*-------- Resumen --------*/
SELECT TOP (2) RunId, EntityType, Variant, RowsEmbedded, Dimensions,
       DATEDIFF(SECOND, StartedAt, FinishedAt) AS segundos
FROM dbo.EmbeddingRun ORDER BY RunId DESC;

SELECT (SELECT COUNT(*) FROM dbo.Movies  WHERE Embedding IS NULL) AS peliculas_sin_embedding,
       (SELECT COUNT(*) FROM dbo.Recipes WHERE Embedding IS NULL) AS recetas_sin_embedding;
GO
