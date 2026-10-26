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

## Planes de ejecución (`performance/13b_execution_plans.sql`, plan real con Ctrl+M)
Capturas en `docs/evidencias/08_optimizacion/`: `plan_q1_antes.png`, `plan_q1_despues.png`, `plan_q2_antes.png`, `plan_q2_despues.png`. Medido el 26/10/2026; los resultados de cada consulta son idénticos antes y después (20 filas en Q1; 41 667 recetas en Q2). Las lecturas de la tabla siguiente son las de `Mensajes` (`SET STATISTICS IO`).

| Consulta | Operador sobre `RecipeIngredients` | Lecturas lógicas de `RecipeIngredients` | Otras lecturas |
|---|---|---|---|
| Q1 antes | Clustered Index Scan (`PK_perf_RecipeIngredients`), 20 filas leídas | 14 | Recipes 8, Ingredients 2 |
| Q1 después | Index Seek (`IX_perf_RecipeIngredients_IngredientId`), 20 filas | 3 | Recipes 8, Ingredients 2 |
| Q2 antes | Clustered Index Scan, 500 000 filas; Hash Match (semicombinación) | 1 857 | IngredientAllergens 2, Workfile 48, Allergens 2 |
| Q2 después | Index Seek sobre ambos índices nuevos; Nested Loops, 10 ejecuciones | 111 | IngredientAllergens 2, Workfile 48, Allergens 2 |

- **Q2** pasa de recorrer toda la tabla a hacer 10 búsquedas (una por ingrediente con gluten): 1 857 → 111 lecturas en `RecipeIngredients` (16,7×). Sumando `IngredientAllergens` salen las 1 859 → 113 de la tabla de resultados (16,5×).
- **Q1** ya era barata sin índice: la clave primaria viene ordenada por `RecipeId`, como el `ORDER BY`, y el Scan se detiene al reunir 20 filas. Con el índice las lecturas de `RecipeIngredients` bajan de 14 a 3 y `Recipes` se sigue leyendo igual (8 lecturas, 473 de 480 filas por el Merge Join). La mejora total es de 24 a 13 lecturas.
- Las lecturas anticipadas y físicas que aparecen en algunas capturas dependen de si la tabla estaba en memoria; las comparaciones se hacen con lecturas lógicas.

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
| Lecturas lógicas (caché caliente, última de 3 repeticiones) | 4 016 en `Items` | 5 071: `Items` 4 248 + `Worktable` 739 + grafo 84 |
| Tiempo transcurrido (caché caliente, 2.ª y 3.ª repetición de dos ejecuciones) | 23 y 33 ms (1.ª ejecución); 21 y 24 ms (2.ª, en la captura) | 13 y 7 ms (1.ª ejecución); 11 y 5 ms (2.ª, en la captura) |
| Primera ejecución (caché fría) | 31 ms / 65 ms | 62 ms / 328 ms |
| Calidad | Referencia | **10 de los 11** vecinos exactos (recall ≈ 91 %), con vectores aleatorios (pesimista) |

Medido con `performance/14b_warm_cache.sql` (26/10/2026; cada bloque se ejecuta 3 veces con `GO 3`; se hicieron dos ejecuciones y las capturas son de la segunda). Las lecturas son idénticas en ambas; los tiempos varían unos milisegundos.

Observaciones:
- El índice **no reduce las lecturas lógicas** (5 071 frente a 4 016, un 26 % más) pero **sí el tiempo** (5 a 13 ms frente a 21 a 33 ms con caché caliente, en dos ejecuciones): recorre el grafo en lugar de calcular la distancia de todos los vectores. A esta escala los tiempos oscilan entre repeticiones.
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
