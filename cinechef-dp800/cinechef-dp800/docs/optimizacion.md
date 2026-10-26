# Optimización de consultas (Bloque D)

## Método
- **Por qué datos sintéticos.** El catálogo real tiene 500 filas en `RecipeIngredients`: caben en unas pocas páginas y cualquier plan es "rápido". Para observar el efecto de un índice se creó el esquema `perf` (`performance/12_perf_setup.sql`) con una copia **estructural** de las tablas (mismas claves primarias, sin índices secundarios) y datos generados: 100 000 recetas y 500 000 filas de ingredientes (5 por receta, con los 120 ingredientes reales). `perf` no forma parte de la aplicación y no toca las tablas reales.
- **Qué se mide.** Lecturas lógicas (deterministas; se obtienen de `sys.dm_exec_requests` y con `SET STATISTICS IO`) y tiempo (ruidoso a esta escala). Cada consulta se ejecuta dos veces y se registra la segunda. El script falla si el **resultado** de una consulta cambia al crear los índices.
- **Dos fases:** *before* (solo claves primarias) y *after* (índices candidatos): `IX_perf_RecipeIngredients_IngredientId` e `IX_perf_IngredientAllergens_AllergenId`.

## Resultados (`performance/13_perf_before_after.sql`)
| Consulta | Resultado | Lecturas antes | Lecturas después | Mejora |
|---|---|---|---|---|
| Q1. Recetas que contienen un ingrediente (TOP 20, ordenadas por id) | 20 | 22 | 11 | 2× |
| Q2. Recetas con algún ingrediente que lleva un alérgeno (COUNT DISTINCT) | 41 667 | 1 859 | 113 | 16,5× |
| Q3. 20 primeras recetas seguras para un usuario (patrón de `fn_SafeRecipes`) | 20 | 1 147 | 1 147 | sin cambio |

Tiempos medidos (antes → después): Q1 2,35 → 0,00 ms; Q2 133,6 → 43,4 ms; Q3 1,0 → 3,2 ms. En esta escala el tiempo varía entre ejecuciones; la medida fiable son las lecturas.

**Lectura de los resultados**
- **Q2** es el caso claro: sin índice sobre `IngredientId` hay que recorrer toda la tabla (1 859 páginas); con el índice, el plan busca solo los ingredientes con el alérgeno (113 lecturas).
- **Q1** mejora poco porque `TOP 20 ... ORDER BY RecipeId` permite al optimizador recorrer la clave primaria en orden y parar al encontrar 20 coincidencias. El índice ayuda sobre todo cuando la consulta no puede cortar antes.
- **Q3** no cambia: ya usa la clave primaria de `RecipeIngredients` por `RecipeId`, de modo que el índice nuevo no se utiliza. No toda consulta se beneficia de un índice adicional.
- El optimizador no devolvió sugerencias de índices faltantes (`sys.dm_db_missing_index_*` vacío) en esta carga.

Planes de ejecución (capturas en `docs/evidencias`): [COMPLETAR: `plan_q1_antes.png` (Clustered Index Scan), `plan_q1_despues.png` (Index Seek), y Q2 si se capturó].

## Decisión sobre el catálogo real (`database/10_indexes.sql`)
| Índice | Decisión | Motivo |
|---|---|---|
| `RecipeIngredients(IngredientId)` | **Creado** | Q2 muestra 16× menos lecturas; la clave primaria `(RecipeId, IngredientId)` no sirve para buscar "recetas con un ingrediente" |
| `IngredientAllergens(AllergenId)` | No creado | Tabla de ~40 filas (una página): no hay beneficio medible |
| `UserAllergies(AllergenId)` | No creado | ~10 filas |
| Para Q3 | Ninguno | Ya usa la clave primaria |

## Búsqueda vectorial: exacta frente a índice vectorial (`performance/14_vector_index_experiment.sql`)
Datos: 20 000 vectores **aleatorios** de 384 dimensiones en `perf.Items` (miden el coste; la calidad semántica se evaluó en las Fases 5 y 6). Función en vista previa de SQL Server 2025 (`PREVIEW_FEATURES = ON`).

| | Exacta (`VECTOR_DISTANCE` + `ORDER BY`) | Índice DiskANN (`VECTOR_SEARCH`) |
|---|---|---|
| Método | Escaneo de todos los vectores | Búsqueda en grafo aproximada |
| Lecturas lógicas | 4 016 en `Items` | Items 4 248, Worktable 739, grafo 84 [COMPLETAR: repetir con caché caliente] |
| CPU / tiempo | 16 ms / 23 ms (caché caliente); 47 ms / 55 ms (fría) | 16 ms / 14 ms |
| Calidad | Referencia | **10 de los 11** vecinos exactos (recall ≈ 91 %), con vectores aleatorios (pesimista) |

Observaciones:
- `CREATE VECTOR INDEX ... WITH (METRIC='cosine', TYPE='DiskANN')` funcionó en esta compilación.
- **La tabla con índice vectorial queda de solo lectura**: un `INSERT` posterior falla con el error 42231. Es una restricción operativa importante en la vista previa.
- `VECTOR_SEARCH` no se pudo usar dentro de un `INSERT ... SELECT` (error 15805, "metadatos no válidos"); sí como consulta directa y mediante `INSERT ... EXEC` de SQL dinámico.
- A 20 000 vectores el escaneo exacto ya cuesta ~20–50 ms, y el índice lo reduce solo moderadamente y a costa de perder alguna coincidencia. Las lecturas del índice no resultan menores que las del escaneo en esta medición.

**Decisión para CineChef:** con 100 películas y 100 recetas, la búsqueda **exacta** es la adecuada: es más simple, siempre devuelve los verdaderos vecinos más cercanos, la tabla sigue siendo escribible y el coste es insignificante. Un índice vectorial solo compensaría con decenas o cientos de miles de vectores y aceptando búsqueda aproximada y restricciones de escritura.

## Limitaciones
- Datos sintéticos y distribuidos de forma uniforme (cada ingrediente aparece en ~4 167 filas): en datos reales la selectividad varía.
- Un solo conjunto de parámetros por consulta (ingrediente nº 51, alérgeno Gluten, usuario con más alergias).
- Los tiempos en milisegundos son ruidosos; no se han repetido en bucle ni con caché fría controlada.
- La comparación de vectores usa vectores aleatorios: el recall real con embeddings semánticos puede ser mejor o peor.

## Limpieza
El esquema `perf` es solo para la medición. Para eliminarlo: `DROP TABLE perf.Items, perf.RecipeIngredients, perf.Recipes, perf.IngredientAllergens, perf.UserAllergies; DROP SCHEMA perf;`
