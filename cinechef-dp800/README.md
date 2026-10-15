# CineChef - La noche de peli perfecta

Mini proyecto DP-800 (SQL AI Developer Associate): recomendador de **película + receta por "vibe"**
sobre **SQL Server 2025 en local**, con búsqueda vectorial y RAG.

> **Nivel seleccionado:** Nivel 3 - Avanzado
> **Estado:** Fase 1 - Preparación (completada)

## Descripción
_(Pendiente de completar.)_

## Arquitectura
_(Pendiente: diagrama.)_

## Tecnologías
SQL Server 2025, T-SQL, SSMS 22, ONNX Runtime, GitHub Copilot, Git, GitHub.

## Instalación
1. Instalar SQL Server 2025 con Full-Text Search y Machine Learning Services, y SSMS 22.
2. Ejecutar `database/00_verify_environment.sql` y comprobar que la versión mayor es 17.
3. Ejecutar `database/01_create_database.sql`.
4. Ejecutar `tests/phase1_smoke_tests.sql` y comprobar que todo sale OK.
5. Preparar ONNX local (ver `ai/`):
   1. Descargar ONNX Runtime (>= 1.19) y copiar `onnxruntime.dll` en `C:\onnx_runtime\`.
   2. Obtener el tokenizador (compilarlo desde `mlc-ai/tokenizers-cpp` o usar el que enlaza el artículo oficial de Microsoft) y **renombrarlo exactamente a `tokenizers_cpp.dll`**; con otro nombre el modelo falla con el error 31739.
   3. Clonar el modelo `all-MiniLM-L6-v2-onnx` (Hugging Face) en `C:\onnx_runtime\model\`.
   4. Ejecutar `ai/00_setup_onnx_runtime.ps1` como administrador.
   5. Ejecutar `ai/01_enable_ai_runtime.sql` y `ai/02_create_external_model.sql`.
   6. Ejecutar `ai/03_test_embeddings.sql` para validar dimensión (384) y similitud semántica.

## Base de datos
_(Pendiente.)_

## Funcionalidades DP-800 implementadas
_(Pendiente.)_

## Ejemplos
_(Pendiente.)_

## Conclusiones
_(Pendiente.)_
