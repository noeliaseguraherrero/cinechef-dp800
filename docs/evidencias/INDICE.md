# Evidencias de ejecución

Capturas recuperadas de las ejecuciones en SSMS y de los chats de GitHub Copilot, ordenadas por fase. Incluyen resultados correctos y también errores y ejecuciones fallidas que se corrigieron (marcados `error_`, `REVISAR` o `CONTAMINADA`).


## 01_entorno

| Archivo | Qué muestra |
|---|---|
| `01_entorno/diagnostico_eventos_extendidos.png` | Diagnóstico con eventos extendidos |
| `01_entorno/diagnostico_sp_readerrorlog.png` | Diagnóstico con sp_readerrorlog |
| `01_entorno/diagnostico_xe_sessions.png` | Consulta de sesiones de eventos extendidos |
| `01_entorno/distancia_pelicula_receta.png` | Distancia coseno película-receta de sopa (0,14) |
| `01_entorno/embedding_primera_prueba.png` | Primer embedding generado |
| `01_entorno/embedding_prueba_texto.png` | Embedding de prueba |
| `01_entorno/error_31739_airuntimehost.png` | Error 31739 de AIRuntimeHost (tokenizador mal nombrado) |
| `01_entorno/modelo_externo_creado.png` | CREATE EXTERNAL MODEL y primer vector |
| `01_entorno/onnx_carpeta_modelo_explorador.png` | Archivos del modelo all-MiniLM-L6-v2 en el explorador |
| `01_entorno/onnx_carpeta_modelo_powershell.png` | Carpeta de ONNX Runtime y del modelo en PowerShell |
| `01_entorno/onnx_dll_antes.png` | DLL de ONNX Runtime |
| `01_entorno/onnx_permisos_icacls.png` | Permisos de C:\onnx_runtime para MSSQLLaunchpad (icacls) |
| `01_entorno/pruebas_humo_8_OK.png` | 8 pruebas de humo en OK |
| `01_entorno/pruebas_humo_8_OK_primera_version.png` | Pruebas de humo (primera ejecución) |
| `01_entorno/validacion_modelo_384_dim.png` | Dimensión 384 y distancias coseno (0,031 frente a 0,091) |
| `01_entorno/validacion_modelo_384_dim_v2.png` | Validación del modelo (versión previa) |
| `01_entorno/verificacion_entorno.png` | Verificación del entorno: SQL Server 2025 17.0.1145.4, Full-Text y ML Services |
| `01_entorno/verificacion_entorno_inicial.png` | Verificación inicial: ML Services = 0 (antes de añadirlo) |
| `01_entorno/verificacion_entorno_inicial_2.png` | Verificación inicial: Full-Text y ML Services sin instalar |

## 02_datos

| Archivo | Qué muestra |
|---|---|
| `02_datos/consulta_ingredientes_wine.png` | Consulta de ingredientes con 'wine' |
| `02_datos/estructura_tablas.png` | Tablas, columnas, claves foráneas y checks |
| `02_datos/estructura_tablas_v2.png` | Estructura de las 11 tablas |
| `02_datos/muestra_10_peliculas.png` | Muestra de 10 películas (año y duración) |
| `02_datos/recetas_seguras_por_usuario.png` | Recetas seguras por usuario |
| `02_datos/recetas_tanda1_longitudes.png` | Recetas tanda 1: 25 recetas y longitudes |
| `02_datos/validate_data_alergenos_recetas.png` | Recetas afectadas por cada alérgeno |
| `02_datos/validate_data_generos_alergenos.png` | Géneros y alérgenos |
| `02_datos/validate_data_resultados.png` | Resultados de validate_data.sql |
| `02_datos/verificacion_recuentos.png` | Recuento esperado y real de las 11 tablas en OK |

## 03_objetos

| Archivo | Qué muestra |
|---|---|
| `03_objetos/pruebas_adversarias_7_OK.png` | 7 pruebas adversarias (B-07) |
| `03_objetos/pruebas_trigger_procedimientos_16_OK.png` | 16 pruebas de trigger y procedimientos |
| `03_objetos/pruebas_vistas_funciones_32_OK.png` | 32 pruebas de vistas y funciones |
| `03_objetos/pruebas_vistas_funciones_previo.png` | Pruebas de vistas y funciones (versión previa) |

## 04_seguridad

| Archivo | Qué muestra |
|---|---|
| `04_seguridad/demo_ataque_inferencia_DENY.png` | Ataque de inferencia y DENY SELECT (error 230) |
| `04_seguridad/demo_auditoria_cc_alice.png` | Auditoría con ChangedBy = cc_alice |
| `04_seguridad/demo_cc_analyst.png` | Demostración: cc_analyst, estadísticas y accesos denegados |
| `04_seguridad/demo_cc_kid_y_cc_nutri.png` | Demostración: control parental y cc_nutri con datos enmascarados |
| `04_seguridad/demo_dbo_y_cc_isaac.png` | Demostración: dbo y cc_isaac |
| `04_seguridad/pruebas_seguridad_35_OK.png` | 35 pruebas de seguridad |

## 05_embeddings

| Archivo | Qué muestra |
|---|---|
| `05_embeddings/error_8116_pruebas_fase5.png` | Error 8116 en la prueba de reproducibilidad |
| `05_embeddings/experimento_recetas_04b.png` | Experimento de formato del texto con recetas |
| `05_embeddings/generacion_embeddings_labeled.png` | Generación de embeddings (variante labeled) |
| `05_embeddings/generacion_embeddings_plain.png` | Generación de embeddings (recetas plain) |
| `05_embeddings/muestra_40_recetas_aleatorias.png` | Muestra de recetas para las sondas |
| `05_embeddings/muestra_recetas_lista.png` | Listado de nombres de recetas |
| `05_embeddings/pruebas_fase5_8_OK.png` | 8 pruebas de embeddings en OK (recetas plain) |
| `05_embeddings/pruebas_fase5_labeled.png` | Pruebas de embeddings (variante labeled) |

## 06_busqueda

| Archivo | Qué muestra |
|---|---|
| `06_busqueda/consulta_ramen_fideos.png` | Recetas de fideos en el catálogo |
| `06_busqueda/error_130_pruebas_fase6.png` | Error Msg 130 en las pruebas de búsqueda |
| `06_busqueda/evaluacion_vector_texto_hibrida.png` | Evaluación: vector, texto e híbrida |
| `06_busqueda/fulltext_catalogo.png` | Catálogo Full-Text e índices |
| `06_busqueda/pruebas_busqueda_10_OK.png` | 10 pruebas de búsqueda en OK |
| `06_busqueda/ramen_seguridad_y_busqueda.png` | Seguridad de las recetas de fideos y búsqueda sin filtro |
| `06_busqueda/sondas_semanticas.png` | Sondas semánticas de recetas |

## 07_rag

| Archivo | Qué muestra |
|---|---|
| `07_rag/P1_con_contexto_copilot.png` | Copilot con contexto, pregunta 1 |
| `07_rag/P1_con_contexto_copilot_v2.png` | Copilot con contexto, pregunta 1 (otra captura) |
| `07_rag/P1_sin_contexto_CONTAMINADA.png` | Línea base contaminada: usa el catálogo de otra conversación |
| `07_rag/P1_sin_contexto_copilot.png` | Copilot sin contexto, pregunta 1 (línea base limpia) |
| `07_rag/P1_sin_contexto_copilot_v2.png` | Copilot sin contexto, pregunta 1 (otra captura) |
| `07_rag/P1_sin_contexto_rechazo_inicial.png` | Primera línea base: Copilot pide contexto |
| `07_rag/P2_con_contexto_copilot.png` | Copilot con contexto, pregunta 2 |
| `07_rag/P2_sin_contexto_copilot.png` | Copilot sin contexto, pregunta 2 (línea base limpia) |
| `07_rag/P2_sin_contexto_copilot_v2.png` | Copilot sin contexto, pregunta 2 (otra captura) |
| `07_rag/P2_sin_contexto_copilot_v3.png` | Copilot sin contexto, pregunta 2 (otra captura) |
| `07_rag/P3_con_contexto_copilot.png` | Copilot con contexto, pregunta 3 |
| `07_rag/P3_con_contexto_copilot_v2.png` | Copilot con contexto, pregunta 3 (otra captura) |
| `07_rag/P3_sin_contexto_CONTAMINADA.png` | Línea base contaminada: cita [M17] |
| `07_rag/P3_sin_contexto_copilot.png` | Copilot sin contexto, pregunta 3 (línea base limpia) |
| `07_rag/P3_sin_contexto_copilot_v2.png` | Copilot sin contexto, pregunta 3 (otra captura) |
| `07_rag/prompt_generado_P1.png` | Prompt generado por SQL (pregunta 1) |
| `07_rag/pruebas_rag_REVISAR_alergenos.png` | Prueba del RAG con REVISAR por alérgenos |
| `07_rag/pruebas_rag_primera_ejecucion.png` | Pruebas del RAG (primera ejecución) |
| `07_rag/pruebas_rag_resultados.png` | Resultados de las pruebas del RAG |
| `07_rag/pruebas_rag_resultados_2.png` | Pruebas del RAG: contexto y línea base |
| `07_rag/pruebas_rag_resultados_3.png` | Pruebas del RAG: más resultados |
| `07_rag/pruebas_rag_resultados_4.png` | Pruebas del RAG: resultados finales |
| `07_rag/registro_respuesta_sesion_9.png` | Registro de la respuesta de la sesión 9 |
| `07_rag/registro_y_verificacion_sesion13_REVISAR.png` | Sesión 13 (línea base contaminada): REVISAR |
| `07_rag/verificacion_sesion09_OK.png` | Verificación sesión 9 (pregunta 1, con contexto): OK |
| `07_rag/verificacion_sesion09_OK_v2.png` | Verificación sesión 9: OK (otra captura) |
| `07_rag/verificacion_sesion13_REVISAR.png` | Verificación sesión 13: REVISAR |
| `07_rag/verificacion_sesion14_REVISAR.png` | Verificación sesión 14: REVISAR |
| `07_rag/verificacion_sesion15_OK.png` | Verificación sesión 15 (pregunta 2, con contexto): OK |
| `07_rag/verificacion_sesion16_OK.png` | Verificación sesión 16 (pregunta 3, con contexto): OK |
| `07_rag/verificacion_sesion17_REVISAR_contaminada.png` | Verificación sesión 17 (contaminada): REVISAR |
| `07_rag/verificacion_sesion18_REVISAR.png` | Verificación sesión 18 (pregunta 1 sin contexto): REVISAR |
| `07_rag/verificacion_sesion19_REVISAR.png` | Verificación sesión 19 (pregunta 2 sin contexto): REVISAR |
| `07_rag/verificacion_sesion20_REVISAR.png` | Verificación sesión 20 (pregunta 3 sin contexto): REVISAR (Akira) |

## 08_optimizacion

| Archivo | Qué muestra |
|---|---|
| `08_optimizacion/error_10741_top_offset.png` | Error 10741 (TOP con OFFSET) |
| `08_optimizacion/esquema_perf_setup.png` | Esquema perf: tablas y filas generadas |
| `08_optimizacion/indice_creado_recipeingredients.png` | Índice IX_RecipeIngredients_IngredientId creado |
| `08_optimizacion/indice_vectorial_error_42231.png` | Índice vectorial: tabla de solo lectura (42231) y lecturas |
| `08_optimizacion/indice_vectorial_mensajes_1.png` | Índice vectorial: mensajes (primer intento) |
| `08_optimizacion/indice_vectorial_recall_10_de_11.png` | Recall 10 de 11 y VECTOR_SEARCH |
| `08_optimizacion/resultados_antes_despues.png` | Lecturas antes y después de los índices |
| `08_optimizacion/plan_q1_antes.png` | Plan de Q1 sin índice: Clustered Index Scan sobre RecipeIngredients |
| `08_optimizacion/plan_q1_despues.png` | Plan de Q1 con índice: Index Seek (14 → 3 lecturas en RecipeIngredients) |
| `08_optimizacion/plan_q2_antes.png` | Plan de Q2 sin índice: Clustered Index Scan de 500 000 filas (1 857 lecturas) |
| `08_optimizacion/plan_q2_despues.png` | Plan de Q2 con índices: Index Seek (111 lecturas) |
| `08_optimizacion/vector_exacta_cache_caliente.png` | Búsqueda vectorial exacta con caché caliente (4 016 lecturas) |
| `08_optimizacion/vector_aproximada_cache_caliente.png` | Búsqueda con índice DiskANN y caché caliente (5 071 lecturas) |

## copilot

| Archivo | Qué muestra |
|---|---|
| `copilot/B-02_chat.png` | Chat de Copilot: ingredientes (B-02) |
| `copilot/B-03_t1_chat.png` | Chat de Copilot: recetas, tanda 1 (B-03) |
| `copilot/B-03_t1_resumen.png` | Resumen de Copilot: recetas, tanda 1 (B-03) |
| `copilot/configuracion_modo_agent_auto.png` | Cuadro de chat: modo Agent, modelo Auto |
| `copilot/selector_modelo_auto.png` | Selector de modelo: solo Auto disponible |
