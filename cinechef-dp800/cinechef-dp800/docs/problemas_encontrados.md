# Problemas encontrados y cómo se resolvieron

## Fase 1

### 1. Full-Text Search y Machine Learning Services no instalados
- **Síntoma:** `SERVERPROPERTY('IsFullTextInstalled')` y `IsAdvancedAnalyticsInstalled` devolvían 0.
- **Causa:** la instalación inicial de SQL Server 2025 no incluía esas características.
- **Solución:** añadirlas a la instancia con el instalador (*add features to an existing installation*).
- **Verificación:** `database/00_verify_environment.sql` devuelve 1 en ambas columnas.

### 2. Error 31739 (`AIRuntimeHost`, HRESULT 0x80004004) al generar embeddings
- **Síntoma:** `AI_GENERATE_EMBEDDINGS` fallaba con "Error al generar inserciones a partir del proceso AIRuntimeHost".
- **Diagnóstico:** se descartaron permisos (`icacls` mostraba control total de `MSSQLLaunchpad`), modelo y tokenizador del modelo (presentes) y el log de SQL Server (sin errores). El HRESULT era genérico y la sesión de Extended Events no devolvió datos.
- **Causa:** el tokenizador estaba guardado como `tokenizers_cpp-release.dll`; SQL Server espera exactamente `tokenizers_cpp.dll`.
- **Solución:** renombrar el archivo y reintentar.
- **Verificación:** `AI_GENERATE_EMBEDDINGS(N'Test Text' ...)` devuelve el mismo vector que el ejemplo oficial de Microsoft.
- **Lección:** los nombres de las DLL en `C:\onnx_runtime` deben ser exactos (`onnxruntime.dll`, `tokenizers_cpp.dll`).
