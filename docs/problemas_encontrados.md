# Problemas encontrados y cómo se resolvieron

Resumen cronológico de lo que no salió a la primera. Cada entrada indica el síntoma, la causa, la solución y cómo se comprobó. Las cifras proceden de los scripts y las pruebas del repositorio.

| # | Fase | Problema | Resultado |
|---|---|---|---|
| 1 | Entorno | Full-Text Search y Machine Learning Services no instalados | Resuelto |
| 2 | Entorno | Error 31739 (`AIRuntimeHost`) al generar embeddings | Resuelto |
| 3 | Datos | 123 ingredientes en lugar de 120 | Resuelto por Copilot |
| 4 | Datos | Receta con gluten asignada a un usuario alérgico | Resuelto por Copilot |
| 5 | Objetos | Receta sin ingredientes considerada segura | Resuelto |
| 6 | Objetos | Fechas de nacimiento futuras aceptadas | Resuelto |
| 7 | Objetos | Procedimiento aceptaba recetas sin ingredientes | Resuelto |
| 8 | Seguridad | La auditoría atribuía los cambios a `sa` | Resuelto |
| 9 | Seguridad | El enmascarado no impide deducir el valor real | Limitación asumida |
| 10 | Embeddings | Error 8116 con `AI_GENERATE_EMBEDDINGS` dentro de `VECTOR_DISTANCE` | Resuelto |
| 11 | Embeddings | La búsqueda en español no funciona | Limitación asumida |
| 12 | Búsqueda | Distancias coseno comprimidas | Resuelto con RRF |
| 13 | RAG | La verificación no reconocía nombres traducidos | Resuelto |
| 14 | RAG | Líneas base contaminadas por la conversación | Resuelto |
| 15 | Rendimiento | Capturas "antes" tomadas con el índice ya creado | Resuelto |
| 16 | Rendimiento | Q1 apenas mejora con el índice | Explicado |
| 17 | Rendimiento | Índice vectorial: tabla de solo lectura y `VECTOR_SEARCH` limitado | Limitación asumida |

## Fase 1: entorno

### 1. Full-Text Search y Machine Learning Services no instalados
- **Síntoma:** `SERVERPROPERTY('IsFullTextInstalled')` y `IsAdvancedAnalyticsInstalled` devolvían 0.
- **Causa:** la instalación inicial de SQL Server 2025 no incluía esas características.
- **Solución:** añadirlas a la instancia con el instalador (*add features to an existing installation*).
- **Verificación:** `database/00_verify_environment.sql` devuelve 1 en ambas columnas.

### 2. Error 31739 (`AIRuntimeHost`, HRESULT 0x80004004) al generar embeddings
- **Síntoma:** `AI_GENERATE_EMBEDDINGS` fallaba con "Error al generar inserciones a partir del proceso AIRuntimeHost".
- **Diagnóstico:** se descartaron permisos (`icacls` mostraba control total de `MSSQLLaunchpad`), modelo y tokenizador (presentes) y el log de SQL Server (sin errores). El HRESULT era genérico y la sesión de Extended Events no devolvió datos.
- **Causa:** el tokenizador estaba guardado como `tokenizers_cpp-release.dll`; SQL Server espera exactamente `tokenizers_cpp.dll`.
- **Solución:** renombrar el archivo y reintentar.
- **Verificación:** `AI_GENERATE_EMBEDDINGS(N'Test Text' ...)` devuelve el mismo vector que el ejemplo oficial de Microsoft.
- **Lección:** los nombres de las DLL en `C:\onnx_runtime` deben ser exactos (`onnxruntime.dll`, `tokenizers_cpp.dll`).

## Fases 2 y 3: datos y objetos T-SQL

Los problemas 3 a 7 salieron de las interacciones con Copilot (detalle en `docs/bloque_b_copilot.md`).

### 3. 123 ingredientes en lugar de 120 (B-02)
- **Síntoma:** la primera carga generada tenía 123 ingredientes y el requisito era 120.
- **Causa:** exceso al generar la lista.
- **Solución:** el propio Copilot detectó el desajuste al contar y eliminó *Capers*, *Beetroot* y *Dates*.
- **Verificación:** 120 ingredientes y 39 relaciones de alérgeno; los recuentos están en `tests/verify_counts.sql`.

### 4. Receta con gluten asignada a un usuario alérgico (B-05)
- **Síntoma:** al validar los datos de prueba, un usuario alérgico al gluten tenía asignada *Summer Peach and Feta Couscous*.
- **Solución:** Copilot la sustituyó por *Garden Quinoa Salad*.
- **Verificación:** las pruebas de la Fase 3 comprueban que ningún plan contradice las alergias del usuario.

### 5. Una receta sin ingredientes se consideraba segura (B-06)
- **Síntoma:** `fn_SafeRecipes` devolvía una receta sin ingredientes, porque ningún ingrediente podía contener un alérgeno.
- **Causa:** la función comprobaba la ausencia de alérgenos y no la presencia de ingredientes.
- **Solución:** la función exige al menos un ingrediente registrado (falla cerrado).
- **Verificación:** prueba nueva en `tests/phase3_objects_tests.sql` (32 pruebas en OK).

### 6. Fechas de nacimiento futuras (B-06)
- **Solución:** `CK_Users_BirthDate` rechaza fechas posteriores a hoy.
- **Verificación:** prueba nueva en `tests/phase3_objects_tests.sql`.

### 7. El procedimiento aceptaba recetas sin ingredientes (B-07)
- **Solución:** `usp_RegisterMovieNight` exige al menos un ingrediente y falla con el error 50015.
- **Verificación:** `tests/phase3b_tests.sql` (16 pruebas) y la prueba A de `tests/phase3c_adversarial_tests.sql` (7 pruebas en OK, con casos de valoración NULL, UPDATE de varias filas, valoración 0 y plan inexistente).

## Fase 4: seguridad

### 8. La auditoría atribuía los cambios a `sa`
- **Síntoma:** en la demostración de seguridad, los cambios de valoración hechos como `cc_alice` aparecían a nombre de `sa`.
- **Causa:** la auditoría guardaba solo `ORIGINAL_LOGIN()`, que es el inicio de sesión de la conexión, no el usuario de base de datos que actúa.
- **Solución:** `MovieNightRatingAudit` guarda dos columnas: `ChangedBy` (`USER_NAME()`) y `ConnectedAs` (`ORIGINAL_LOGIN()`).
- **Limitación:** si la aplicación usara un único usuario compartido, haría falta `SESSION_CONTEXT`.

### 9. El enmascarado de datos no impide deducir el valor real
- **Síntoma:** un rol con `SELECT` sobre la columna enmascarada podía filtrar (`WHERE BirthDate < '1990-01-01'`) y deducir la fecha.
- **Causa:** el enmascarado dinámico solo cambia lo que se muestra; no es control de acceso.
- **Resultado:** se demostró en `tests/security_demo.sql`; con `DENY SELECT` la consulta falla con el error 230. La mitigación queda documentada en `docs/seguridad.md` y no se aplicó, para que el nutricionista pueda ver el perfil.

## Fases 5 y 6: embeddings y búsqueda

### 10. Error 8116 con `AI_GENERATE_EMBEDDINGS` dentro de `VECTOR_DISTANCE`
- **Causa:** la función devuelve `vector` solo cuando se asigna a una columna o a una variable `VECTOR`.
- **Solución:** guardar el embedding de la consulta en una tabla temporal con una columna `VECTOR(384)` antes de comparar.

### 11. La búsqueda en español no funciona
- **Causa:** `all-MiniLM-L6-v2` está entrenado sobre todo con inglés.
- **Solución:** catálogo y consultas en inglés, interfaz en español. Es una limitación de diseño documentada.

### 12. Distancias coseno comprimidas
- **Síntoma:** los cinco primeros resultados estaban entre 0,12 y 0,14, sin diferencias claras.
- **Solución:** la búsqueda híbrida combina posiciones de ranking (RRF, k = 60) y no distancias en bruto, junto con Full-Text Search.
- **Evaluación:** 13 sondas de película y las de recetas en `tests/phase6_search_tests.sql`.

## Fase 7: RAG

### 13. La verificación no reconocía nombres traducidos
- **Causa:** Copilot responde en español y traduce los títulos, y la detección por nombre fallaba (y a veces daba falsos positivos: "Akira Kurosawa" se contó como la película *Akira*).
- **Solución:** el prompt pide citar el id (`[R80]`, `[M5]`) y `usp_VerifyRagAnswer` se apoya en esa cita.

### 14. Líneas base contaminadas por la conversación
- **Síntoma:** una línea base citaba `[M17]`, un id que solo existía en el prompt con contexto.
- **Causa:** se ejecutó en una conversación que ya había visto el prompt con contexto; además, en modo agente, Copilot puede leer el repositorio.
- **Solución:** repetirlas en conversaciones nuevas, una por pregunta y en modo Ask (sesiones 18, 19 y 20). Las sesiones anteriores se conservan en `RagSession` como evidencia.

## Fase 8: rendimiento

### 15. Capturas "antes" tomadas con el índice ya creado
- **Síntoma:** al repetir las capturas de los planes, las dos "antes" mostraban un Index Seek sobre el índice nuevo.
- **Causa:** se ejecutaron los pasos fuera de orden: los índices ya estaban creados.
- **Solución:** se repitió la secuencia empezando por borrar los índices, y se añadió al script `13b_execution_plans.sql` una comprobación de que no queda ninguno antes de medir.
- **Lección:** comprobar el estado antes de medir.

### 16. Q1 apenas mejora con el índice
- **Resultado:** `RecipeIngredients` baja de 14 a 3 lecturas, pero `Recipes` se sigue leyendo igual (8 lecturas) y el total pasa de 24 a 13.
- **Causa:** `TOP 20 ... ORDER BY RecipeId` permite recorrer la clave primaria en orden y parar a las 20 filas; el índice ayuda cuando la consulta no puede cortar antes. La mejora grande es Q2 (1 857 → 111 lecturas).

### 17. Índice vectorial DiskANN (vista previa)
- **Hallazgos:** funciona (recall de 10 de 11 con vectores aleatorios), pero la tabla queda de solo lectura (`INSERT` falla con el error 42231) y `VECTOR_SEARCH` no se admite dentro de `INSERT ... SELECT` (error 15805).
- **Medición con caché caliente:** 5 071 lecturas frente a 4 016 de la búsqueda exacta, aunque el tiempo baja de 21 a 33 ms a 5 a 13 ms (dos ejecuciones).
- **Decisión:** con 100 elementos se usa la búsqueda exacta: más simple, siempre correcta y escribible.
