# Bloque B - Desarrollo SQL asistido por IA (GitHub Copilot)

Este documento registra cada uso de GitHub Copilot en el proyecto. Para cada interacción se documentan
los cinco puntos que exige el enunciado: **prompt, respuesta, partes aceptadas, partes corregidas y verificación**.

> Las respuestas completas de Copilot (sin editar) se guardaron en `docs/evidencias/copilot/` (`B-01_respuesta.sql`, etc.).

## Resumen

**Configuración de Copilot.** Todas las interacciones se hicieron en VS Code con GitHub Copilot Chat en **modo Agent** y con el selector de modelo en **Auto**: Copilot elige el modelo en cada petición, por lo que no se puede atribuir una respuesta concreta a un modelo concreto. Con el plan utilizado, el selector solo permite Auto (el resto de modelos requiere ampliar el plan).

| Ref. | Qué se pidió | Archivo resultante | Corrección real documentada | Quién la hizo |
|---|---|---|---|---|
| B-01 | Géneros y alérgenos de la UE | `03a_lookups.sql` | Ejecutar el script en SSMS (Copilot solo validó de forma estática) | Yo |
| B-02 | 120 ingredientes y sus alérgenos | `03b_ingredients.sql` | 123 ingredientes iniciales recortados a 120 | Copilot (autocorrección), contrastada por mí |
| B-03 | 100 recetas en 4 tandas de 25 | `03c_recipes.sql` a `03c4_recipes.sql` | Tanda 3: descripción ajustada al nombre real del ingrediente | Copilot, contrastada por mí |
| B-04 | 100 películas en 4 tandas de 25 | `03d_movies.sql` a `03d4_movies.sql` | Ninguna; datos contrastados con una fuente externa (10 películas) | Yo |
| B-05 | 10 usuarios, alergias y 30 planes | `03e_users_nights.sql` | Receta con gluten asignada a un usuario alérgico, sustituida | Copilot, contrastada por mí |
| B-06 | Revisión de vistas y funciones | `04_views.sql`, `05_functions.sql` | 2 cambios de código (receta sin ingredientes; fecha de nacimiento futura) | Yo, a partir de los hallazgos de Copilot |
| B-07 | Revisión de trigger y procedimientos | `06_audit_trigger.sql`, `07_procedures.sql` | Validación de recetas sin ingredientes en el procedimiento | Yo, a partir del hallazgo de Copilot |

En total hay **7 interacciones documentadas** (B-03 y B-04 en cuatro tandas cada una). Las cinco primeras generaron los datos de
prueba; B-06 y B-07 usaron Copilot como **revisor** del código ya escrito.

**Otros asistentes de IA.** El borrador de los scripts de las Fases 3 a 9 y de la documentación se redactó con Claude (Anthropic);
Copilot se usó para los datos (B-01 a B-05) y para las revisiones B-06 y B-07. Todo el código se ejecutó y se verificó con las pruebas
indicadas en cada ficha.

---

## 0. Prompt de contexto (pegado al inicio de cada chat nuevo de Copilot)

```
Eres un asistente de desarrollo para SQL Server 2025 (T-SQL). Estoy construyendo "CineChef", una base de
datos que recomienda una película y una receta según el estado de ánimo del usuario. Todos los datos son
ficticios y en INGLÉS (títulos, sinopsis, nombres de recetas e ingredientes). El esquema ya existe en la
base de datos CineChefDB (te adjunto 02_create_tables.sql).

Reglas para todo lo que generes:
- Responde SOLO con un bloque de código T-SQL, sin explicaciones largas.
- Usa N'...' en todas las cadenas Unicode y escapa las comillas simples duplicándolas.
- No uses IDs numéricos para relacionar tablas: relaciona siempre por NOMBRE/TÍTULO mediante
  INSERT ... SELECT desde un VALUES(...) unido con JOIN a las tablas ya cargadas.
- Respeta las restricciones CHECK y UNIQUE del esquema. No inventes columnas.
- No incluyas la columna Embedding (se rellena más adelante).
- No incluyas datos personales reales, contraseñas ni claves.
- Si no estás seguro de un dato real (año, duración), no incluyas esa película.
```

Se adjuntó `database/02_create_tables.sql` al chat para que Copilot conociera el esquema.

## 1. Prompts de referencia

Texto completo previsto para cada interacción. Las fichas de la sección 2 indican el enunciado que se escribió en el chat.

**B-01 · Géneros y alérgenos → `database/03a_lookups.sql`**
```
Genera un script T-SQL que inserte en dbo.Genres 18 géneros cinematográficos habituales (Drama, Comedy,
Animation, Sci-Fi, Fantasy, Romance, Thriller, Horror, Documentary, Adventure, Family, Mystery, Musical,
Crime, War, Western, Biography, Action) y en dbo.Allergens exactamente estos 14 alérgenos de declaración
obligatoria en la UE: Gluten, Crustaceans, Eggs, Fish, Peanuts, Soybeans, Milk, Tree nuts, Celery,
Mustard, Sesame, Sulphites, Lupin, Molluscs.
```

**B-02 · Ingredientes y alérgenos → `database/03b_ingredients.sql`**
```
Genera un script T-SQL que inserte en dbo.Ingredients unos 120 ingredientes culinarios comunes en inglés
(verduras, frutas, carnes, pescados, lácteos, harinas, especias, salsas, legumbres, frutos secos, etc.).
Después inserta en dbo.IngredientAllergens la relación con los alérgenos ya cargados, uniendo por nombre.
Sé riguroso: el pan y la harina de trigo llevan Gluten, la mantequilla y el queso llevan Milk, la salsa de
soja lleva Soybeans y Gluten, etc. Los ingredientes sin alérgenos no aparecen en IngredientAllergens.
```

**B-03 · Recetas, 4 tandas de 25 → `database/03c_recipes.sql`, `03c2` a `03c4`**
```
Genera un script T-SQL que inserte 25 recetas en dbo.Recipes y sus ingredientes en dbo.RecipeIngredients.
Cada Description debe tener 200-350 caracteres, ser original y evocar el ambiente y la sensación de comer
ese plato (reconfortante, ligero, festivo, picante, nostálgico...), no solo listar ingredientes.
Difficulty entre 1 y 3. Usa EXCLUSIVAMENTE ingredientes que ya existen en dbo.Ingredients (uniendo por
nombre; si necesitas uno nuevo, avísame en un comentario en lugar de inventarlo). Varía cocinas, tiempos y
estados de ánimo. Esta es la tanda 1 de 4: la siguiente la pediré después, sin repetir recetas.
```
En las tandas 2 a 4 se cambió el número de tanda, se pidió un archivo nuevo (`03c2_recipes.sql`, etc.) y se añadió «Evita estas recetas ya creadas: <lista>».

**B-04 · Películas, 4 tandas de 25 → `database/03d_movies.sql`, `03d2` a `03d4`**
```
Genera un script T-SQL que inserte 25 películas reales y conocidas en dbo.Movies y sus géneros en
dbo.MovieGenres (uniendo por título y año con dbo.Genres por nombre). Cada película con 1-3 géneros.
La Synopsis debe tener 200-350 caracteres, estar escrita con tus propias palabras (NO copiada de ninguna
web) y centrarse en el tono y la atmósfera (melancólica, reconfortante, tensa, divertida, nostálgica...)
más que en el argumento. MinAge solo puede ser 0, 7, 12, 16 o 18. Incluye solo películas de las que estés
seguro del año y la duración. Mezcla épocas, países y tonos; incluye cine familiar y de animación y
también adulto. Tanda 1 de 4.
```

**B-05 · Usuarios, alergias y planes → `database/03e_users_nights.sql`**
```
Genera un script T-SQL que inserte 10 usuarios ficticios en dbo.Users (emails con dominio example.com,
fechas de nacimiento que den edades entre 8 y 60 años, incluyendo al menos 2 menores de 12 y 2 menores de
18), sus alergias en dbo.UserAllergies (3 usuarios sin alergias, el resto con 1-3), y 30 filas en
dbo.MovieNights usando películas y recetas ya existentes (uniendo por título y nombre), con Vibe en
inglés y Rating entre 1 y 5 o NULL. Las películas elegidas para un menor deben tener un MinAge adecuado.
```

Orden de ejecución: `02_create_tables.sql` → `03a` → `03b` → `03c` a `03c4` → `03d` a `03d4` → `03e`.

---

## 2. Registro de interacciones

### B-01 - Géneros cinematográficos y alérgenos obligatorios de la UE
- **Fecha:** 15/10/2026
- **Herramienta:** GitHub Copilot Chat en VS Code. **Modo:** Agent. **Modelo:** Auto (selección automática de Copilot)
- **Objetivo:** cargar los catálogos base (18 géneros y los 14 alérgenos de declaración obligatoria en la UE) de forma repetible y sin IDs numéricos.

**1. Prompt utilizado**
> Géneros y alérgenos (los 14 de la UE)

(Texto completo de referencia: sección 1, B-01.)

**2. Respuesta de la IA**
Revisó el esquema de `Genres` y `Allergens` y generó `database/03a_lookups.sql` con `INSERT ... SELECT` protegidos con `NOT EXISTS`
para poder repetir la carga. Respuesta completa: `docs/evidencias/copilot/B-01_respuesta.sql`.

**3. Partes aceptadas**
- La estructura del script (carga por nombre y `NOT EXISTS`).
- Las listas completas de 14 alérgenos y 18 géneros.

**4. Partes corregidas**
| Problema | Cómo se detectó | Corrección |
|---|---|---|
| Copilot solo validó el código de forma estática; no ejecutó las inserciones | Su propia respuesta no mostraba ninguna ejecución en SQL Server | Ejecuté el script en SSMS y comprobé los datos cargados |

**5. Verificación (ejecutada por mí en SSMS)**
- `SELECT N'Genres', COUNT(*) FROM dbo.Genres;` y `SELECT N'Allergens', COUNT(*) FROM dbo.Allergens;`
- Resultado: **18 géneros y 14 alérgenos**.

**Conclusión:** el script cumplió lo pedido a la primera; mi aportación fue ejecutarlo y contar las filas.

### B-02 - Ingredientes y relaciones con alérgenos
- **Fecha:** 15/10/2026
- **Herramienta:** GitHub Copilot Chat en VS Code. **Modo:** Agent. **Modelo:** Auto
- **Objetivo:** cargar 120 ingredientes y su relación con los alérgenos, uniendo por nombre y con carga repetible.

**1. Prompt utilizado**
> 120 ingredientes con sus alérgenos.

(Texto completo de referencia: sección 1, B-02.)

**2. Respuesta de la IA**
Comprobó que `03b_ingredients.sql` no existía y redactó una primera carga de **123** ingredientes. Tras contar, eliminó tres
ingredientes secundarios para ceñirse a 120 y a 39 relaciones, y copió el resultado a la evidencia (comprobación SHA-256).
Respuesta completa: `docs/evidencias/copilot/B-02_respuesta.sql`.

**3. Partes aceptadas**
- La estructura por nombre (`JOIN`) y repetible.
- La asignación de alérgenos principales (lácteos, huevos, harinas y pastas, pescados).
- El recuento final de 120 ingredientes.

**4. Partes corregidas**
| Problema | Cómo se detectó | Corrección |
|---|---|---|
| 123 ingredientes en lugar de 120 | Comprobación de recuento que hizo el propio modelo | El modelo eliminó *Capers*, *Beetroot* y *Dates* antes de la versión definitiva |

**5. Verificación (ejecutada por mí en SSMS)**
- Recuentos de `Ingredients` e `IngredientAllergens` tras cargar `03b_ingredients.sql`.
- Resultado: **120 ingredientes y 39 relaciones de alérgeno**, sin errores. Los recuentos se mantienen en `tests/verify_counts.sql`.

**Conclusión:** Copilot corrigió su propio exceso al contar. La coherencia de los alérgenos asignados la comprobé yo con las pruebas de la Fase 3.

### B-03 - Recetas (4 tandas de 25)
- **Fecha:** 15/10/2026
- **Herramienta:** GitHub Copilot Chat en VS Code. **Modo:** Agent. **Modelo:** Auto
- **Objetivo:** cargar 100 recetas originales con sus ingredientes, cada tanda en un archivo nuevo para no modificar los anteriores.

#### Tanda 1 → `database/03c_recipes.sql`

**1. Prompt utilizado**
> Genera un script T-SQL que inserte 25 recetas en dbo.Recipes y sus ingredientes en dbo.RecipeIngredients ... Esta es la tanda 1 de 4.

**2. Respuesta de la IA**
Creó `03c_recipes.sql` con 25 recetas y sus relaciones por nombre (`JOIN` y `NOT EXISTS`). Comprobó antes, leyendo los archivos con
PowerShell, los recuentos y longitudes de descripción (240 a 279 caracteres). Evidencia: `docs/evidencias/copilot/B-03_respuesta.sql`.

**3. Partes aceptadas**
- Las 25 recetas con descripciones originales dentro del rango y dificultad de 1 a 3.
- Las relaciones resueltas por nombre, sin IDs numéricos.

**4. Partes corregidas**
| Problema | Cómo se detectó | Corrección |
|---|---|---|
| Ninguno en el código | Consultas de validación en SSMS | Sin cambios. La consulta 5 (descripción frente a alérgenos) marcó 7 filas por coincidencia de texto; las revisé una a una y eran falsos positivos (por ejemplo, «crema de coco» asociada a la palabra *cream* sin lácteo real) |

**5. Verificación (ejecutada por mí en SSMS)**
- Recuentos: 25 recetas y 125 relaciones (esperado 25 y 125); mínimo de 5 ingredientes por receta.
- Consulta 4: coherencia entre ingredientes y alérgenos (lácteos, gluten, pescado).
- Consulta 5: 7 filas revisadas, todas falsos positivos.

#### Tanda 2 → `database/03c2_recipes.sql`

**1. Prompt utilizado**
> Genera un script T-SQL que inserte 25 recetas ... Esta es la tanda 2 de 4. Guárdala en un archivo NUEVO database/03c2_recipes.sql, sin modificar 03c_recipes.sql. Evita estas recetas ya creadas: [nombres de la tanda 1].

**2. Respuesta de la IA**
Creó `03c2_recipes.sql` con 25 recetas nuevas y 125 relaciones, sin tocar la tanda 1. Comprobó descripciones de 251 a 272 caracteres y que no hubiera nombres repetidos. Evidencia: `docs/evidencias/copilot/B-03_t2_respuesta.sql`.

**3. Partes aceptadas**
- Las 25 recetas nuevas, sin solapamiento con la tanda 1.
- Relaciones por nombre y carga repetible (`NOT EXISTS`).

**4. Partes corregidas**
| Problema | Cómo se detectó | Corrección |
|---|---|---|
| Ninguno | Conteos y comprobación de nombres en SSMS | Sin cambios |

**5. Verificación (ejecutada por mí en SSMS)**
- 25 recetas y 125 relaciones nuevas; total acumulado de **50 recetas y 250 relaciones**.

#### Tanda 3 → `database/03c3_recipes.sql`

**1. Prompt utilizado**
> Genera un script T-SQL que inserte 25 recetas ... Esta es la tanda 3 de 4. Guárdala en un archivo NUEVO database/03c3_recipes.sql, sin modificar los anteriores. Evita estas recetas ya creadas: [lista acumulada de las tandas 1 y 2].

**2. Respuesta de la IA**
Creó `03c3_recipes.sql` con 25 recetas y 125 relaciones. Antes de entregarlo ajustó el texto de la descripción de una receta para
que coincidiera con el nombre exacto del ingrediente del catálogo (*Kidney beans*). Comprobó descripciones de 246 a 274 caracteres y
ningún duplicado con las 50 recetas anteriores. Evidencia: `docs/evidencias/copilot/B-03_t3_respuesta.sql`.

**3. Partes aceptadas**
- Las 25 recetas, con ingredientes que existen en `03b_ingredients.sql`.
- La inserción protegida con `NOT EXISTS`.

**4. Partes corregidas**
| Problema | Cómo se detectó | Corrección |
|---|---|---|
| La descripción de una receta nombraba un ingrediente distinto del catálogo | Comprobación del propio modelo contra el catálogo | Texto ajustado a *Kidney beans*; confirmé el resultado en SSMS |

**5. Verificación (ejecutada por mí en SSMS)**
- 25 recetas y 125 relaciones; total acumulado de **75 recetas**.

#### Tanda 4 → `database/03c4_recipes.sql`

**1. Prompt utilizado**
> Genera un script T-SQL que inserte 25 recetas ... Esta es la tanda 4 de 4 (la última). Guárdala en un archivo NUEVO database/03c4_recipes.sql, sin modificar los anteriores. Evita estas recetas ya creadas: [lista acumulada de las 75 previas].

**2. Respuesta de la IA**
Creó `03c4_recipes.sql` con las últimas 25 recetas y 125 relaciones. Comprobó con scripts auxiliares que no había duplicados con las
75 anteriores, descripciones de 233 a 281 caracteres y solo ingredientes del catálogo. Evidencia: `docs/evidencias/copilot/B-03_t4_respuesta.sql`.

**3. Partes aceptadas**
- Las 25 recetas finales, con variedad de tiempos, dificultad y cocinas.
- Integridad referencial y protección `NOT EXISTS`.

**4. Partes corregidas**
| Problema | Cómo se detectó | Corrección |
|---|---|---|
| Ninguno | Conteos y cruce de nombres en SSMS | Sin cambios |

**5. Verificación (ejecutada por mí en SSMS)**
- 25 recetas y 125 relaciones; total definitivo de **100 recetas y 500 relaciones** en `CineChefDB`.

**Conclusión de B-03:** el generador funcionó bien con reglas claras y un archivo por tanda. No hubo correcciones de código; la
calidad de los datos se comprobó con recuentos, longitudes y una revisión manual de las coincidencias de alérgenos.

### B-04 - Películas (4 tandas de 25)
- **Fecha:** 16/10/2026
- **Herramienta:** GitHub Copilot Chat en VS Code. **Modo:** Agent. **Modelo:** Auto
- **Objetivo:** cargar 100 películas reales con sinopsis propias y sus géneros, una tanda por archivo.

#### Tanda 1 → `database/03d_movies.sql`

**1. Prompt utilizado**
> Genera un script T-SQL que inserte 25 películas reales y conocidas en dbo.Movies y sus géneros en dbo.MovieGenres ... Tanda 1 de 4.

**2. Respuesta de la IA**
Creó `03d_movies.sql` con 25 películas y 62 relaciones de género. Comprobó sinopsis de 254 a 296 caracteres, de 1 a 3 géneros por película y `MinAge` solo en 0, 7, 12, 16 y 18. Evidencia: `docs/evidencias/copilot/B-04_respuesta.sql`.

**3. Partes aceptadas**
- Las 25 películas, con géneros enlazados por nombre y carga repetible.

**4. Partes corregidas**
| Problema | Cómo se detectó | Corrección |
|---|---|---|
| Ninguno en el código | Ejecución y comprobación de rangos en SSMS | Sin cambios; los datos se contrastaron con una fuente externa (ver más abajo) |

**5. Verificación (ejecutada por mí en SSMS)**
- 25 películas y 62 relaciones; sinopsis de 254 a 295 caracteres.

#### Tanda 2 → `database/03d2_movies.sql`

**1. Prompt utilizado**
> ... Esta es la tanda 2 de 4. Guárdala en un archivo NUEVO database/03d2_movies.sql, sin modificar los anteriores. Evita estas películas ya creadas: [lista de la tanda 1].

**2. Respuesta de la IA**
Creó `03d2_movies.sql` con 25 películas nuevas y 59 relaciones. Validó sinopsis de 261 a 302 caracteres, géneros existentes y `MinAge` permitido. Evidencia: `docs/evidencias/copilot/B-04_t2_respuesta.sql`.

**3. Partes aceptadas:** las 25 películas, con asociaciones correctas y `NOT EXISTS`.

**4. Partes corregidas**
| Problema | Cómo se detectó | Corrección |
|---|---|---|
| Ninguno | Diagnósticos del entorno y conteos en SSMS | Sin cambios |

**5. Verificación (ejecutada por mí en SSMS)**
- 25 películas y 59 relaciones; total acumulado de **50 películas**.

#### Tanda 3 → `database/03d3_movies.sql`

**1. Prompt utilizado**
> ... Esta es la tanda 3 de 4. Guárdala en un archivo NUEVO database/03d3_movies.sql, sin modificar los anteriores. Evita estas películas ya creadas: [lista de las 50 previas].

**2. Respuesta de la IA**
Creó `03d3_movies.sql` con 25 películas nuevas y 59 relaciones. Validó sinopsis de 265 a 301 caracteres, `MinAge` permitido y ausencia de duplicados. Evidencia: `docs/evidencias/copilot/B-04_t3_respuesta.sql`.

**3. Partes aceptadas:** las 25 películas, con géneros por nombre y `NOT EXISTS`.

**4. Partes corregidas**
| Problema | Cómo se detectó | Corrección |
|---|---|---|
| Ninguno | Diagnósticos del entorno y conteos en SSMS | Sin cambios |

**5. Verificación (ejecutada por mí en SSMS)**
- 25 películas y 59 relaciones; total acumulado de **75 películas**.

#### Tanda 4 → `database/03d4_movies.sql`

**1. Prompt utilizado**
> ... Esta es la tanda 4 de 4 (la última). Guárdala en un archivo NUEVO database/03d4_movies.sql, sin modificar los anteriores. Evita estas películas ya creadas: [lista de las 75 previas].

**2. Respuesta de la IA**
Creó `03d4_movies.sql` con las últimas 25 películas y 53 relaciones. Comprobó que el conjunto acumulado no tuviera duplicados, sinopsis de 263 a 299 caracteres y géneros existentes. Evidencia: `docs/evidencias/copilot/B-04_t4_respuesta.sql`.

**3. Partes aceptadas:** las 25 películas finales, con `NOT EXISTS` y géneros por nombre.

**4. Partes corregidas**
| Problema | Cómo se detectó | Corrección |
|---|---|---|
| Ninguno | Diagnósticos del entorno y cruce de títulos en SSMS | Sin cambios |

**5. Verificación (ejecutada por mí en SSMS)**
- 25 películas y 53 relaciones; total definitivo de **100 películas y 233 relaciones de género** (`tests/verify_counts.sql`).

#### Validación de los datos reales (muestra de 10 películas)

Como las cuatro tandas no necesitaron correcciones de código, la comprobación de que los datos generados son reales se hizo
contrastando una muestra de 10 películas con una fuente externa (tolerancia de ±3 minutos en la duración por posibles montajes distintos).
**Fuentes consultadas:** IMDb y Wikipedia. **Fecha:** hacia el 16/10/2026 (fecha aproximada, no anotada en el momento).

| Película | Año BD | Año fuente | Duración BD | Duración fuente | ¿Coincide? |
|---|:---:|:---:|:---:|:---:|:---:|
| 2001: A Space Odyssey | 1968 | 1968 | 149 min | 149 min | Sí |
| Schindler's List | 1993 | 1993 | 195 min | 195 min | Sí |
| Raging Bull | 1980 | 1980 | 129 min | 129 min | Sí |
| Wild Strawberries | 1957 | 1957 | 92 min | 92 min | Sí |
| Rashomon | 1950 | 1950 | 88 min | 88 min | Sí |
| E.T. the Extra-Terrestrial | 1982 | 1982 | 115 min | 115 min | Sí |
| Crouching Tiger, Hidden Dragon | 2000 | 2000 | 120 min | 120 min | Sí |
| Moonlight | 2016 | 2016 | 111 min | 111 min | Sí |
| One Flew Over the Cuckoo's Nest | 1975 | 1975 | 133 min | 133 min | Sí |
| Fight Club | 1999 | 1999 | 139 min | 139 min | Sí |

Resultado: **10 de 10 coinciden**. Con una muestra de 10 sobre 100 no se puede afirmar que las 100 películas sean correctas; la muestra
cubre solo el 10 % del catálogo.

**Criterio de `MinAge`.** Es una aproximación a la clasificación por edades europea (PEGI/ICAA) con los valores 0, 7, 12, 16 y 18 según
contenido y tono. No es una clasificación oficial.

**Conclusión de B-04:** Copilot produjo datos válidos y sin errores de formato en las cuatro tandas. Que los datos sean reales solo está
comprobado para la muestra de 10 películas.

### B-05 - Usuarios, alergias y noches de cine
- **Fecha:** 16/10/2026
- **Herramienta:** GitHub Copilot Chat en VS Code. **Modo:** Agent. **Modelo:** Auto
- **Objetivo:** cargar 10 usuarios ficticios, sus alergias y 30 planes con películas aptas para la edad y recetas sin los alérgenos del usuario.

**1. Prompt utilizado**
> Genera un script T-SQL que inserte 10 usuarios ficticios en dbo.Users ... sus alergias en dbo.UserAllergies ... y 30 filas en dbo.MovieNights usando películas y recetas ya existentes ... [prompt completo de la sección 1, B-05].

**2. Respuesta de la IA**
Creó `database/03e_users_nights.sql` con 10 usuarios, 9 relaciones de alergia y 30 planes. Al validar el perfil de cada usuario contra los
ingredientes de la receta asignada detectó un conflicto de gluten y sustituyó la receta (*Summer Peach and Feta Couscous*) por
*Garden Quinoa Salad*. Evidencia: `docs/evidencias/copilot/B-05_respuesta.sql`.

**3. Partes aceptadas**
- La distribución de los 10 usuarios (con menores) y los 30 planes con valoraciones de 1 a 5 o NULL.

**4. Partes corregidas**
| Problema | Cómo se detectó | Corrección |
|---|---|---|
| Receta con gluten asignada a un usuario alérgico | Validación cruzada del propio modelo entre perfil y receta | Receta sustituida por *Garden Quinoa Salad*; comprobé el resultado con `fn_SafeRecipes` (Fase 3) |

**5. Verificación (ejecutada por mí en SSMS)**
- 10 usuarios, 9 alergias y 30 planes.
- Cero conflictos de alérgenos entre planes y alergias, y cumplimiento de la edad mínima en los planes de menores.

**Conclusión:** la corrección de seguridad la hizo Copilot al validar; la comprobé con una consulta independiente en lugar de
fiarme de su propia validación.

### B-06 - Revisión de vistas y funciones (Fase 3)
- **Fecha:** 16/10/2026
- **Herramienta:** borrador de los scripts redactado con Claude; revisión con GitHub Copilot Chat en VS Code. **Modo:** Agent. **Modelo:** Auto
- **Objetivo:** que Copilot revisara `04_views.sql` y `05_functions.sql` buscando errores, casos límite y riesgos de seguridad, sin modificar los archivos.

**1. Prompt utilizado**
> Revisa estas vistas y funciones de SQL Server 2025. Busca: errores de sintaxis, casos límite no contemplados (usuarios sin alergias, recetas sin ingredientes, usuarios inexistentes), riesgos de seguridad, problemas de rendimiento y cualquier cosa que puedas explicar de forma más sencilla. Explica con tus palabras qué hace fn_SafeRecipes y por qué se comprueba que el usuario exista. No modifiques los archivos: responde con una lista de hallazgos.

**2. Respuesta de la IA**
Devolvió **15 hallazgos** y una explicación de `fn_SafeRecipes`. No ejecutó código en SQL Server.

**3. Partes aceptadas**
- Confirmaciones de comportamiento correcto: hallazgos 1, 2, 3 y 8.
- Asuntos derivados a la Fase 4 (seguridad): 4 (existir no es estar autorizado), 5 (RLS) y 9 (la vista no es frontera de seguridad).
- Limitación documentada: 7 (no se modela la contaminación cruzada).
- Pospuestos: 14 (Fase 8) y 15 (Fase 5).
- La explicación de `fn_SafeRecipes`, correcta.

**4. Partes corregidas**
| Hallazgo | Cómo se detectó | Corrección |
|---|---|---|
| 6. Una receta sin ingredientes se consideraba segura | Revisión estática de Copilot | `fn_SafeRecipes` exige al menos un ingrediente registrado (falla cerrado) |
| 11. Se permitían fechas de nacimiento futuras | Revisión estática de Copilot | `CK_Users_BirthDate` en `02_create_tables.sql` rechaza fechas posteriores a hoy |

Rechazados con justificación: 10 (zona horaria; proyecto local de un solo servidor), 12 (29 de febrero; sin impacto práctico) y 13 (cubierto por las pruebas).

**5. Verificación (ejecutada por mí en SSMS)**
- `tests/phase3_objects_tests.sql`: **32 pruebas en OK**, incluidas dos nuevas para las correcciones (receta sin ingredientes no devuelta; fecha futura rechazada).
- Reconstrucción completa con `scripts/load_all.ps1`.

**Conclusión:** de 15 hallazgos, 4 eran confirmaciones, 2 llevaron a cambios de código, 3 a trabajo de seguridad ya previsto, 1 a una limitación asumida,
2 se pospusieron y 3 se rechazaron. La revisión de Copilot fue útil para encontrar casos límite, pero no distingue entre un defecto y un
comportamiento correcto, y es estática; hicieron falta pruebas ejecutables para confirmar cada cambio.

### B-07 - Revisión del trigger y los procedimientos (Fase 3, segunda parte)
- **Fecha:** 16/10/2026
- **Herramienta:** GitHub Copilot Chat en VS Code. **Modo:** Agent. **Modelo:** Auto
- **Objetivo:** que Copilot explicara `06_audit_trigger.sql` y `07_procedures.sql`, propusiera casos de prueba que intentaran romperlos y señalara riesgos de seguridad, sin modificar los archivos.

**1. Prompt utilizado**
> Revisa 06_audit_trigger.sql y 07_procedures.sql. (1) Explica con palabras qué hace el trigger y por qué compara inserted con deleted. (2) Propón 5 casos de prueba que intenten romper estos objetos (entradas límite, concurrencia, valores NULL, actualizaciones de varias filas). (3) Indica qué riesgos de seguridad ves. No modifiques los archivos.

**2. Respuesta de la IA**
- **Trigger:** explicó correctamente el uso conjunto de `inserted` y `deleted` para detectar cambios de valoración.
- **Casos de prueba:** propuso escenarios con transiciones de `NULL`, actualizaciones de varias filas, límites de `Rating` y concurrencia.
- **Defecto lógico (caso 5):** `usp_RegisterMovieNight` permitía registrar recetas sin ingredientes, porque `fn_SafeRecipes` las consideraba seguras al no tener alérgenos registrados.
- **Riesgos de seguridad:** suplantación de identidad al pasar `@UserId` como parámetro libre y dependencia de las políticas de seguridad a nivel de fila (RLS).

**3. Partes aceptadas**
- La explicación del trigger y su diseño orientado a conjuntos.
- Los riesgos de autorización de usuarios y de parámetros abiertos, que justifican la Fase 4.

**4. Partes corregidas**
| Hallazgo | Cómo se detectó | Corrección |
|---|---|---|
| Se aceptaban recetas sin ingredientes en el procedimiento | Revisión de Copilot (caso 5) | `usp_RegisterMovieNight` exige al menos un ingrediente (error 50015) |

**5. Verificación (ejecutada por mí en SSMS)**
- `tests/phase3b_tests.sql`: **16 pruebas en OK**. Entre ellas: errores 50010, 50013, 50014, 50020 y 50021; los errores no dejan filas;
  el trigger audita `NULL→4` y `4→5` pero no cambios en otras columnas; y la búsqueda difusa por título.
- Receta sin ingredientes (error 50015): `tests/phase3_objects_tests.sql` comprueba que `fn_SafeRecipes` no la devuelve, y la prueba A de `tests/phase3c_adversarial_tests.sql` comprueba que el procedimiento la rechaza con el error 50015 sin dejar ningún plan.
- Casos adversarios: no registré uno a uno los que ejecuté en su momento. Para dejar evidencia ejecutable los cubrí después con `tests/phase3c_adversarial_tests.sql`: **A** receta sin ingredientes (50015), **B** valoración `NULL` aceptada y auditada (4 → NULL), **C** `UPDATE` de varias filas (una fila de auditoría por plan), **D** valoración 0 (50020) y **E** plan inexistente (50021). La concurrencia entre dos sesiones queda sin probar.
- Resultado de `phase3c_adversarial_tests.sql`: **7 pruebas en OK** (los cinco casos, la comprobación de que el rechazo no deja planes y la limpieza).

**Conclusión:** la revisión adversaria encontró un defecto lógico real que una revisión sintáctica no habría visto. Los riesgos de suplantación de identidad
que señaló se resolvieron en la Fase 4 (control de identidad con `UserPrincipals`, RLS y error 50030).

---

## 3. Reflexión sobre el uso de Copilot

- **Dónde ayudó:** generar volúmenes grandes de datos con reglas claras (B-01 a B-05), explicar objetos (trigger, función segura) y proponer casos límite (B-06, B-07).
- **Qué no hizo:** ejecutar el código en SQL Server. Todas sus validaciones fueron estáticas o con scripts auxiliares; los recuentos y las pruebas los ejecuté yo en SSMS.
- **Qué corrigió él y qué corregí yo:** las correcciones de B-02, B-03 (tanda 3) y B-05 las hizo Copilot al validar su propio resultado. Los cambios de código de B-06 y B-07 los hice yo a partir de sus hallazgos.
- **Límite:** Copilot no distingue un defecto de un comportamiento correcto (B-06), y los datos generados son verosímiles pero no verificados al completo: solo se contrastó una muestra de 10 películas.
- **Regla seguida:** ninguna afirmación de Copilot se aceptó sin una consulta o prueba ejecutable que la respalde.
