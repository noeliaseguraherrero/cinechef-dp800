# Búsqueda inteligente (Bloque F)

## Qué se ha implementado
| Objeto | Función |
|---|---|
| `ai/07_fulltext.sql` | Catálogo `CineChefFT`; índices Full-Text en `Movies(Title, Synopsis)`, `Recipes(Name, Description)` e `Ingredients(Name)` |
| `usp_SearchMovies` | Búsqueda de películas: vector, texto o híbrida; filtra por edad si se indica `@UserId` |
| `usp_SearchRecipes` | Búsqueda de recetas con tres listas (vector, texto, ingredientes); filtra por alergias si se indica `@UserId` |
| `usp_SuggestRecipesForMovie` | Maridaje: recetas seguras más cercanas (coseno) al embedding de la película |

## Diseño
- **Reciprocal Rank Fusion**: `score = Σ 1 / (60 + posición)`. Se combinan posiciones y no distancias, porque las distancias coseno de MiniLM están comprimidas (ver [embeddings.md](embeddings.md)) y no son comparables con la puntuación del Full-Text.
- **Métrica coseno**: mide el ángulo entre vectores e ignora su longitud; es la habitual para embeddings de texto. Con vectores normalizados ordena igual que el producto escalar.
- **Búsqueda exacta**: `VECTOR_DISTANCE` sobre las 100 filas de cada tabla. A este tamaño no hay índice vectorial que compense (ver Fase 8).
- **Seguridad**: con `@UserId`, solo se devuelven recetas seguras (`fn_SafeRecipes`) y películas permitidas (`fn_AllowedMovies`); usuario inexistente da 0 filas; la identidad se comprueba como en `usp_RegisterMovieNight` (error 50030). Los permisos de ejecución, incluido el del modelo de embeddings, se conceden por rol.

## Evaluación
Tres conjuntos de sondas, todos con la respuesta esperada fijada a mano.

**A. Sondas léxicas** (`09_search_evaluation.sql`; la consulta repite palabras del nombre de la receta)

| Tipo | Modo | Top1 | Top5 | Top10 | No aparece |
|---|---|---|---|---|---|
| Recetas (20) | text | 19 | 20 | 20 | 0 |
| Recetas (20) | hybrid | 18 | 20 | 20 | 0 |
| Recetas (20) | vector | 12 | 17 | 17 | 0 |
| Películas (7) | hybrid | 2 | 3 | 4 | 0 |
| Películas (7) | text | 2 | 3 | 4 | 2 |
| Películas (7) | vector | 0 | 0 | 1 | 0 |

**B. Sondas semánticas de recetas** (`09b_search_semantic_probes.sql`; consultas por intención, varias recetas aceptables)

| Modo | MRR | Top1 | Top3 | Top5 |
|---|---|---|---|---|
| text | 0,490 | 3 | 5 | 5 |
| hybrid | 0,352 | 2 | 2 | 4 |
| vector | 0,128 | 0 | 0 | 3 |

## Conclusiones (y límites)
1. **El vector por sí solo no basta** con all-MiniLM-L6-v2 en este catálogo: en películas solo 1 de 7 sondas entra en el top 10 y en las sondas semánticas de recetas es el modo con peor MRR.
2. **El Full-Text gana en este conjunto**, también en las consultas por intención, porque las descripciones e ingredientes comparten vocabulario con ellas (warm, spicy, breakfast…). **La búsqueda híbrida no mejora al texto** aquí: la lista vectorial, más débil, diluye la fusión.
3. **Dónde sí aporta el vector**: (a) como respaldo cuando el texto no encuentra nada (películas Jaws y The Godfather: el texto devuelve 0 resultados y la híbrida los devuelve, aunque en posiciones 39 y 68); (b) en el maridaje película-receta, donde no hay vocabulario común y solo es posible comparar significado.
4. **Límites de la evaluación**: pocas sondas (20 + 8 recetas, 7 películas), criterio de acierto elegido por la autora, catálogo pequeño y sinopsis generadas. Los números orientan; no son una medición general. No se han ajustado los pesos de la fusión con estas mismas sondas, para no sobreajustar.
5. **Mejoras posibles**: RRF ponderado, un modelo multilingüe o de mayor calidad, o reordenar los candidatos del Full-Text con el vector.
