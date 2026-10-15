/*==============================================================
  CineChef - Registro del modelo de embeddings local (ONNX)
  Modelo: all-MiniLM-L6-v2 (vectores de 384 dimensiones)

  IMPORTANTE: la sintaxis procede del artículo oficial de Microsoft
  escrito para SQL Server 2025 RC0. Compárala con la página actual
  de CREATE EXTERNAL MODEL en Microsoft Learn antes de ejecutarla
  (por ejemplo, PARAMETERS era un valor de relleno en RC0).
==============================================================*/
USE CineChefDB;
GO
CREATE EXTERNAL MODEL CineChefEmbeddingModel
WITH (
    LOCATION           = 'C:\onnx_runtime\model\all-MiniLM-L6-v2-onnx',  -- contiene model.onnx y tokenizer.json
    API_FORMAT         = 'ONNX Runtime',
    MODEL_TYPE         = EMBEDDINGS,
    MODEL              = 'allMiniLM',
    PARAMETERS         = '{"valid":"JSON"}',
    LOCAL_RUNTIME_PATH = 'C:\onnx_runtime\'                              -- contiene onnxruntime.dll y tokenizers_cpp.dll
);
GO

-- Prueba: debe devolver un vector de 384 valores
SELECT AI_GENERATE_EMBEDDINGS(N'Una película tranquila y reconfortante' USE MODEL CineChefEmbeddingModel) AS embedding;
GO
