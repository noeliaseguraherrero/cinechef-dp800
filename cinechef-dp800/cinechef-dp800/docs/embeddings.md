# Modelos y embeddings (Bloque E)

## Modelo utilizado
- **all-MiniLM-L6-v2** en formato ONNX, ejecutado **en local** dentro de SQL Server 2025 mediante ONNX Runtime.
- Se registra con `CREATE EXTERNAL MODEL CineChefEmbeddingModel` (`ai/02_create_external_model.sql`).
- Está entrenado sobre todo con texto en inglés: por eso el catálogo está en inglés (ver «Idioma» más abajo).

## Qué texto se convierte en vector
| Tabla | Columna del vector | Texto de entrada |
|---|---|---|
| `Movies` | `Embedding VECTOR(384)` | `labeled`: `Genres: <géneros>. <sinopsis>` (`vw_MovieSearchText`) |
| `Recipes` | `Embedding VECTOR(384)` | `labeled`: `<descripción> Ingredients: <ingredientes>` (`vw_RecipeSearchText`) |

Las vistas centralizan la construcción del texto. No se incluyen el título ni el nombre del plato.

## Dimensión
**384** componentes (`float32`), fijada por el modelo. La columna `VECTOR(384)` rechaza vectores de otro tamaño.

## Cómo se generan
```
vw_MovieSearchText / vw_RecipeSearchText  ->  AI_GENERATE_EMBEDDINGS(texto USE MODEL CineChefEmbeddingModel)  ->  UPDATE ... SET Embedding
```
`ai/05_generate_embeddings.sql` repite la operación para las 100 películas y 100 recetas y anota cada ejecución
en `dbo.EmbeddingRun` (modelo, variante, dimensión, filas y tiempo).

## Cómo se almacenan
En columnas `VECTOR(384)` de las propias tablas `Movies` y `Recipes`, junto al resto de datos. Se comparan con `VECTOR_DISTANCE('cosine', a, b)`.

## Experimento de formato del texto (`ai/04_embedding_experiment.sql`)
Se compararon tres variantes del texto: con etiquetas (`Genres: ...`), con géneros sin etiqueta y solo la sinopsis/descripción.
Se midió en qué posición del ranking aparece la película esperada para 10 consultas de ambiente en inglés y 3 en español.

| Tipo | Idioma | Variante | Sondas | hit@1 | hit@3 | hit@5 | MRR |
|---|---|---|---|---|---|---|---|
| movie | en | labeled | 10 | 2 | 3 | 5 | 0,334 |
| movie | en | unlabeled | 10 | 1 | 3 | 5 | 0,236 |
| movie | en | plain | 10 | 1 | 1 | 2 | 0,168 |
| movie | es | labeled | 3 | 0 | 0 | 0 | 0,076 |
| movie | es | unlabeled | 3 | 0 | 0 | 0 | 0,070 |
| movie | es | plain | 3 | 0 | 0 | 0 | 0,046 |

**Variante elegida y motivo:** `labeled` (con etiquetas). Es la mejor o empata en todas las métricas (MRR 0,334 frente a 0,236 y 0,168).
La diferencia clara está entre incluir los géneros y no incluirlos (hit@3: 3 frente a 1 con solo la sinopsis). Entre `labeled` y `unlabeled` la diferencia es pequeña
(un acierto más en el primer puesto) y con 10 sondas no es concluyente; se elige `labeled` por empatar o ganar en todo y por coincidir con las vistas ya creadas.
**Para las recetas no hay evidencia propia** (no se escribieron sondas de recetas): se usa la misma variante por coherencia y queda como una decisión sin contrastar.

### Limitaciones del experimento
- Muestra pequeña (13 sondas de película): sirve para comparar variantes entre sí, no para medir una precisión absoluta.
- Hay otras películas que también serían respuestas razonables a una consulta; la «esperada» es solo una.
- Las sinopsis y descripciones las generó GitHub Copilot, centradas en el tono: las sondas se escribieron en ese mismo estilo.
- `hit@k` y MRR del azar con 100 elementos: MRR ≈ 0,05.
- **Sesgo a favor de las variantes con géneros:** varias sondas contienen palabras de género ("martial arts fantasy", "science fiction", "historical drama"), que coinciden con el texto añadido en `labeled` y `unlabeled`. Parte de su ventaja sobre `plain` puede deberse a eso.

## Calidad de la búsqueda semántica
- **La calidad absoluta es modesta.** Con las sondas en inglés, la variante elegida coloca la película esperada la primera en 2 de 10 ocasiones, entre las 3 primeras en 3 y entre las 5 primeras en 5.
- **Ejemplo cualitativo (sección E4):** para «A tender, magical story of friendship between a lonely child and a visitor from another world», los 5 primeros resultados fueron
  *City Lights* (0,1197), *Eternal Sunshine of the Spotless Mind* (0,1197), *Citizen Kane* (0,1269), *The Exorcist* (0,1394) y *The Lion King* (0,1422). *E.T.* no está entre ellos y *The Exorcist* sí.
- **Rango de distancias comprimido:** los cinco primeros están entre 0,12 y 0,14; el ranking existe, pero las diferencias de distancia son mínimas. Lo mismo se observó antes al comparar una película con una receta de sopa (0,14).
  Hipótesis, sin comprobar: la forma en que este modelo ONNX produce el vector (agrupación de los tokens) difiere de la del modelo original. `ai/06_embedding_diagnostics.sql` mide la distribución de distancias.
- **Consecuencia de diseño:** la búsqueda combinará posiciones de ranking (RRF) y no distancias en bruto, y se complementará con Full-Text Search.

## Idioma
Las 3 sondas en español no aciertan ninguna película en ninguna variante (hit@5 = 0; MRR entre 0,046 y 0,076, es decir, cerca del azar de ~0,05), mientras que las mismas consultas en inglés dan MRR 0,334 en la variante elegida.
El modelo all-MiniLM-L6-v2 no entiende consultas en español. **Decisión:** catálogo y consultas de búsqueda en inglés; la interfaz y las explicaciones, en español.
**Mejora posible (no implementada):** un modelo de embeddings multilingüe, o traducir la consulta antes de generar su vector.
