# Bloque B - Desarrollo SQL asistido por IA (GitHub Copilot)

Este documento registra cada uso de GitHub Copilot en el proyecto. Para cada interacción se documentan
los cinco puntos que exige el enunciado: prompt, respuesta, partes aceptadas, partes corregidas y verificación.

> Las respuestas completas de Copilot (sin editar) se guardan en `docs/evidencias/copilot/` como `B-01_respuesta.sql`, etc.

---

## 0. Prompt de contexto (pegar al inicio de CADA chat nuevo de Copilot)

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

> Adjunta `database/02_create_tables.sql` al chat (arrastrándolo o con `#file`) para que Copilot conozca el esquema.

---

## 1. Prompts específicos (uno por interacción)

### B-01. Géneros y alérgenos -> `database/03a_lookups.sql`
```
Genera un script T-SQL que inserte en dbo.Genres 18 géneros cinematográficos habituales (Drama, Comedy,
Animation, Sci-Fi, Fantasy, Romance, Thriller, Horror, Documentary, Adventure, Family, Mystery, Musical,
Crime, War, Western, Biography, Action) y en dbo.Allergens exactamente estos 14 alérgenos de declaración
obligatoria en la UE: Gluten, Crustaceans, Eggs, Fish, Peanuts, Soybeans, Milk, Tree nuts, Celery,
Mustard, Sesame, Sulphites, Lupin, Molluscs.
```

### B-02. Ingredientes y su relación con alérgenos -> `database/03b_ingredients.sql`
```
Genera un script T-SQL que inserte en dbo.Ingredients unos 120 ingredientes culinarios comunes en inglés
(verduras, frutas, carnes, pescados, lácteos, harinas, especias, salsas, legumbres, frutos secos, etc.).
Después inserta en dbo.IngredientAllergens la relación con los alérgenos ya cargados, uniendo por nombre.
Sé riguroso: el pan y la harina de trigo llevan Gluten, la mantequilla y el queso llevan Milk, la salsa de
soja lleva Soybeans y Gluten, etc. Los ingredientes sin alérgenos no aparecen en IngredientAllergens.
```

### B-03. Recetas (en 4 tandas de 25) -> `database/03c_recipes.sql`
```
Genera un script T-SQL que inserte 25 recetas en dbo.Recipes y sus ingredientes en dbo.RecipeIngredients.
Cada Description debe tener 200-350 caracteres, ser original y evocar el ambiente y la sensación de comer
ese plato (reconfortante, ligero, festivo, picante, nostálgico...), no solo listar ingredientes.
Difficulty entre 1 y 3. Usa EXCLUSIVAMENTE ingredientes que ya existen en dbo.Ingredients (uniendo por
nombre; si necesitas uno nuevo, avísame en un comentario en lugar de inventarlo). Varía cocinas, tiempos y
estados de ánimo. Esta es la tanda 1 de 4: la siguiente la pediré después, sin repetir recetas.
```
Repite el prompt cambiando `tanda 1 de 4` por 2, 3 y 4, y añade `evita estas recetas ya creadas: <lista>`.

### B-04. Películas (en 4 tandas de 25) -> `database/03d_movies.sql`
```
Genera un script T-SQL que inserte 25 películas reales y conocidas en dbo.Movies y sus géneros en
dbo.MovieGenres (uniendo por título y año con dbo.Genres por nombre). Cada película con 1-3 géneros.
La Synopsis debe tener 200-350 caracteres, estar escrita con tus propias palabras (NO copiada de ninguna
web) y centrarse en el tono y la atmósfera (melancólica, reconfortante, tensa, divertida, nostálgica...)
más que en el argumento. MinAge solo puede ser 0, 7, 12, 16 o 18. Incluye solo películas de las que estés
seguro del año y la duración. Mezcla épocas, países y tonos; incluye cine familiar y de animación y
también adulto. Tanda 1 de 4.
```

### B-05. Usuarios ficticios y planes -> `database/03e_users_nights.sql`
```
Genera un script T-SQL que inserte 10 usuarios ficticios en dbo.Users (emails con dominio example.com,
fechas de nacimiento que den edades entre 8 y 60 años, incluyendo al menos 2 menores de 12 y 2 menores de
18), sus alergias en dbo.UserAllergies (3 usuarios sin alergias, el resto con 1-3), y 30 filas en
dbo.MovieNights usando películas y recetas ya existentes (uniendo por título y nombre), con Vibe en
inglés y Rating entre 1 y 5 o NULL. Las películas elegidas para un menor deben tener un MinAge adecuado.
```

---

## 2. Ejecución y verificación

1. Guarda la respuesta **sin editar** en `docs/evidencias/copilot/B-0X_respuesta.sql`.
2. Copia el código al archivo de `database/` correspondiente y **ejecútalo**. Anota cualquier error.
3. Corrige lo necesario (y anota qué cambiaste y por qué).
4. Ejecuta `tests/validate_data.sql` y revisa los resultados.
5. Comprueba a mano una muestra de 10 películas (año y duración reales) contra una fuente fiable.
6. Rellena la ficha de abajo.

Orden de ejecución: `02_create_tables.sql` -> `03a` -> `03b` -> `03c` -> `03d` -> `03e`.

---

## 3. Fichas de interacción (plantilla)

### B-01 - Géneros cinematográficos y alérgenos obligatorios de la UE
- Fecha: 15 de octubre de 2026
- Herramienta: GitHub Copilot Chat (VS Code / SSMS 22), modelo: GitHub Copilot (Claude 3.5 Sonnet / GPT-4o)
- Objetivo: Cargar e inicializar los catálogos base de géneros cinematográficos y los 14 alérgenos obligatorios de la UE de forma repetible y sin depender de IDs numéricos.

**1. Prompt utilizado**
> Géneros y alérgenos (los 14 de la UE)

**2. Respuesta de la IA**
Resumen: El modelo restauró el punto de control, revisó el esquema de las tablas `Genres` y `Allergens`, y generó el script de inserción en `database/03a_lookups.sql` utilizando inserciones basadas en `INSERT ... SELECT` con `NOT EXISTS` para evitar duplicados. Respuesta completa: docs/evidencias/copilot/B-01_respuesta.sql

**3. Partes aceptadas**
- La estructura general del script utilizando carga basada en nombres y cláusulas `NOT EXISTS`.
- La lista completa de los 14 alérgenos obligatorios de la UE y los 18 géneros cinematográficos.
- La generación automática de la evidencia en la ruta correspondiente.

**4. Partes corregidas**
| Problema | Cómo se detectó | Corrección |
|---|---|---|
| Falta de ejecución automática en la base de datos | Copilot realizó una validación estática de código pero no ejecutó las consultas de inserción directamente. | Se ejecutó el script manualmente en SQL Server Management Studio (SSMS) para verificar la persistencia de los datos. |

**5. Verificación**
- Consulta / prueba ejecutada: Verificación de recuentos mediante `SELECT N'Genres', COUNT(*) FROM dbo.Genres WHERE ...` y `SELECT N'Allergens', COUNT(*) FROM dbo.Allergens WHERE ...`.
- Resultado: 18 registros de géneros y 14 registros de alérgenos cargados y validados correctamente.
- Captura: docs/evidencias/B-01_verificacion.png

**Conclusión:** El prompt B-01 se completó con éxito, asegurando que los catálogos base de la aplicación queden correctamente poblados mediante un script robusto y repetible.

### B-02 - Ingredientes y relaciones con alérgenos
- Fecha: 15 de octubre de 2026
- Herramienta: GitHub Copilot Chat (VS Code / SSMS 22), modelo: GitHub Copilot (Claude 3.5 Sonnet / GPT-4o)
- Objetivo: Cargar 120 ingredientes únicos y sus asociaciones relacionales con los alérgenos mediante enlaces por nombre (`JOIN`), asegurando una carga repetible sin IDs hardcodeados.

**1. Prompt utilizado**
> 120 ingredientes con sus alérgenos.

**2. Respuesta de la IA**
Resumen: El modelo detectó que el archivo `03b_ingredients.sql` no existía y procedió a redactar una carga inicial de 123 ingredientes. Tras un análisis de validación interno de diagnóstico y conteo, corrigió automáticamente la cantidad eliminando 3 elementos secundarios para ceñirse estrictamente al requisito de 120 ingredientes y 39 relaciones. Copió el resultado a la evidencia de forma idéntica mediante validación SHA-256. Respuesta completa: docs/evidencias/copilot/B-02_respuesta.sql

**3. Partes aceptadas**
- La estructura relacional basada en consultas por nombre (`JOIN`) y cargas repetibles.
- La asociación correcta de los alérgenos principales (lácteos, huevos, harinas/pastas y pescados).
- La corrección automática del conteo exacto de los 120 ingredientes.

**4. Partes corregidas**
| Problema | Cómo se detectó | Corrección |
|---|---|---|
| Exceso inicial de elementos (123 en lugar de 120) | Mediante la comprobación de diagnóstico interna que realizó el propio modelo al verificar los límites esperados. | El modelo eliminó automáticamente los ingredientes secundarios sobrantes (*Capers, Beetroot y Dates*) antes de generar la versión definitiva del script. |

**5. Verificación**
- Consulta / prueba ejecutada: Carga del archivo `database/03b_ingredients.sql` y validación de recuentos de filas en las tablas `Ingredients` e `IngredientAllergens`.
- Resultado: 120 ingredientes y 39 relaciones de alérgenos insertados correctamente sin errores de diagnóstico.
- Captura: docs/evidencias/B-02_verificacion.png

**Conclusión:** El prompt B-02 se resolvió de forma sobresaliente, demostrando la capacidad de autocorrección de la IA ante desviaciones en los volúmenes de datos exigidos.

### B-03 - Recetas 
#### Tanda 1

1. **Prompt utilizado**
   > Genera un script T-SQL que inserte 25 recetas en dbo.Recipes... [Prompt B-03 completo del documento, tanda 1 de 4].

2. **Respuesta de la IA**
   - Creó `database/03c_recipes.sql` con 25 recetas y sus relaciones por nombre mediante `JOIN`, utilizando `NOT EXISTS` para permitir cargas repetibles. 
   - La validación previa del modelo consistió en leer los archivos localmente mediante PowerShell (verificando conteos y longitudes de 240 a 279 caracteres). 
   - El archivo `docs/evidencias/copilot/B-03_respuesta.sql` es una copia idéntica del script principal.

3. **Partes aceptadas**
   - Las 25 recetas con descripciones originales dentro del rango de longitud establecido y dificultades de 1 a 3.
   - Las relaciones resueltas estrictamente por nombre, sin utilizar IDs numéricos.

4. **Partes corregidas**
   | Problema | Cómo se detectó | Corrección |
   |---|---|---|
   | No se detectaron errores en las comprobaciones ejecutadas en SSMS: los conteos de filas coinciden exactamente con la cardinalidad esperada (25 registros por tanda), las longitudes de texto respetan los rangos de caracteres especificados y las relaciones por nombre resuelven íntegramente con los catálogos previos sin referencias huérfanas | Mediante la ejecución de las consultas de validación y coherencia en SSMS. | No se requirieron correcciones; la revisión de alérgenos y la comprobación de palabras clave de la consulta 5 arrojaron únicamente falsos positivos lógicos (ej. crema de coco asociada a la palabra *cream* sin alérgeno lácteo real). |

5. **Verificación (ejecutada por mí en SSMS)**
   - **Conteos:** 25 recetas y 125 relaciones verificadas (esperado 25 y 125).
   - **Ingredientes por receta:** Mínimo de 5 ingredientes por receta en la muestra evaluada.
   - **Revisión de alérgenos (Consulta 4):** Coherencia total entre los ingredientes y los alérgenos asignados (ej. lácteos, gluten, pescado).
   - **Coherencia descripción/alérgenos (Consulta 5):** Se revisaron 7 filas detectadas por coincidencia de texto, confirmando que todas correspondían a falsos positivos benignos (ingredientes vegetales o denominaciones sin alérgeno declarable).
   - **Capturas:** `docs/evidencias/copilot/B-03_t1_chat.png` y `docs/evidencias/B-03_t1_verificacion.png`.

#### Tanda 2

1. **Prompt utilizado**
   > Genera un script T-SQL que inserte 25 recetas en dbo.Recipes y sus ingredientes en dbo.RecipeIngredients. Cada Description debe tener entre 200-350 caracteres, ser original y evocar el ambiente y la sensación de comer ese plato... Esta es la tanda 2 de 4. Guárdala en un archivo NUEVO database/03c2_recipes.sql, sin modificar 03c_recipes.sql. Evita estas recetas ya creadas: [Lista de nombres de la Tanda 1].

2. **Respuesta de la IA**
   - Creó de forma aislada el archivo `database/03c2_recipes.sql` con 25 recetas nuevas y sus 125 relaciones correspondientes sin alterar el archivo anterior de la tanda 1.
   - Verificó que las longitudes de las descripciones estuvieran comprendidas entre 251 y 272 caracteres y que no existieran nombres duplicados respecto a la tanda previa.
   - Generó su respectiva evidencia en `docs/evidencias/copilot/B-03_t2_respuesta.sql`.

3. **Partes aceptadas**
   - Las 25 recetas adicionales con total independencia de nomenclatura respecto a la primera tanda.
   - El respeto estricto de las restricciones del esquema (relaciones por nombre mediante `JOIN` y cargas repetibles con `NOT EXISTS`).

4. **Partes corregidas**
   | Problema | Cómo se detectó | Corrección |
   |---|---|---|
   | No se detectaron errores en las comprobaciones ejecutadas en SSMS: los conteos de filas coinciden exactamente con la cardinalidad esperada (25 registros por tanda), las longitudes de texto respetan los rangos de caracteres especificados y las relaciones por nombre resuelven íntegramente con los catálogos previos sin referencias huérfanas | Mediante la validación interna del modelo y las comprobaciones posteriores en el entorno de desarrollo. | No se detectaron conflictos; todas las referencias apuntan a ingredientes reales del catálogo y no se solapan nombres de recetas. |

5. **Verificación (ejecutada por mí en SSMS)**
   - **Conteos:** 25 recetas nuevas y 125 relaciones verificadas tras la ejecución de `03c2_recipes.sql`.
   - **Independencia de tandas:** Comprobación de que el volumen total acumulado asciende correctamente a 50 recetas y 250 relaciones.
   - **Capturas:** `docs/evidencias/copilot/B-03_t2_chat.png` y `docs/evidencias/B-03_t2_verificacion.png`.

#### Tanda 3

1. **Prompt utilizado**
   > Genera un script T-SQL que inserte 25 recetas en dbo.Recipes y sus ingredientes en dbo.RecipeIngredients... Esta es la tanda 3 de 4. Guárdala en un archivo NUEVO database/03c3_recipes.sql, sin modificar los anteriores. Evita estas recetas ya creadas: [Lista acumulada tandas 1 y 2].

2. **Respuesta de la IA**
   - Creó de forma aislada el archivo `database/03c3_recipes.sql` con 25 recetas nuevas y sus 125 relaciones correspondientes.
   - Realizó una autocorrección semántica previa en el script para alinear el texto de la descripción con el ingrediente exacto del catálogo (*Kidney beans*).
   - Verificó longitudes de descripciones entre 246 y 274 caracteres y cero duplicidades con las 50 recetas anteriores.
   - Generó su respectiva evidencia en `docs/evidencias/copilot/B-03_t3_respuesta.sql`.

3. **Partes aceptadas**
   - Las 25 recetas de la tanda con asignación estricta de ingredientes existentes en `03b_ingredients.sql`.
   - La estructura de inserción segura mediante `NOT EXISTS` y resolución de relaciones por nombre.

4. **Partes corregidas**
   | Problema | Cómo se detectó | Corrección |
   |---|---|---|
   | Coherencia semántica de ingrediente | Validación automatizada interna de la IA al revisar el catálogo. | Se ajustó el texto descriptivo de la primera receta para que coincida exactamente con la nomenclatura del ingrediente real (*Kidney beans*). |

5. **Verificación (ejecutada por mí en SSMS)**
   - **Conteos:** 25 recetas y 125 relaciones verificadas en la ejecución de `03c3_recipes.sql` (acumulando 75 recetas en total).
   - **Capturas:** `docs/evidencias/copilot/B-03_t3_chat.png` y `docs/evidencias/copilot/B-03_t3_verificacion.png`.

#### Tanda 4

1. **Prompt utilizado**
   > Genera un script T-SQL que inserte 25 recetas en dbo.Recipes y sus ingredientes en dbo.RecipeIngredients... Esta es la tanda 4 de 4 (la última). Guárdala en un archivo NUEVO database/03c4_recipes.sql, sin modificar los anteriores. Evita estas recetas ya creadas: [Lista acumulada de las 75 recetas previas].

2. **Respuesta de la IA**
   - Creó de forma aislada el archivo `database/03c4_recipes.sql` con las últimas 25 recetas y sus 125 relaciones correspondientes.
   - Verificó mediante scripts auxiliares que no existiera ninguna duplicidad con las 75 recetas de las tandas 1, 2 y 3.
   - Comprobó longitudes de descripciones entre 233 y 281 caracteres y el uso exclusivo de ingredientes existentes en el catálogo.
   - Generó su respectiva evidencia en `docs/evidencias/copilot/B-03_t4_respuesta.sql`.

3. **Partes aceptadas**
   - Las 25 recetas finales con variedad óptima en tiempos, dificultad (1 a 3) y tipologías culinarias.
   - La integridad referencial y las cláusulas de protección `NOT EXISTS` en las inserciones.

4. **Partes corregidas**
   | Problema | Cómo se detectó | Corrección |
   |---|---|---|
   | No se detectaron errores en las comprobaciones ejecutadas en SSMS: los conteos de filas coinciden exactamente con la cardinalidad esperada (25 registros por tanda), las longitudes de texto respetan los rangos de caracteres especificados y las relaciones por nombre resuelven íntegramente con los catálogos previos sin referencias huérfanas | Mediante las validaciones automatizadas y cruce de exclusión de nombres previos. | Sin incidencias; todas las referencias y nombres cumplieron los requisitos con exactitud. |

5. **Verificación (ejecutada por mí en SSMS)**
   - **Conteos:** 25 recetas y 125 relaciones verificadas en la ejecución final de `03c4_recipes.sql` (alcanzando un total definitivo de **100 recetas y 500 relaciones** en `CineChefDB`).
   - **Capturas:** `docs/evidencias/copilot/B-03_t4_chat.png` y `docs/evidencias/copilot/B-03_t4_verificacion.png`.

### B-04 - Peliculas
#### Tanda 1 

1. **Prompt utilizado**
   > Genera un script T-SQL que inserte 25 películas reales y conocidas en dbo.Movies y sus géneros en dbo.MovieGenres (uniendo por título/año y nombre de género). Cada película con 1-3 géneros. La Synopsis debe tener entre 200-350 caracteres... Tanda 1 de 4.

2. **Respuesta de la IA**
   - Creó el archivo `database/03d_movies.sql` con 25 películas reales y sus 62 relaciones de género.
   - Verificó que las sinopsis cumplieran el rango de longitud (entre 254 y 296 caracteres), que cada película tuviera entre 1 y 3 géneros y que los valores de clasificación de edad (`MinAge`) fueran exclusivamente `0, 7, 12, 16, 18`.
   - Guardó la evidencia en `docs/evidencias/copilot/B-04_respuesta.sql`.

3. **Partes aceptadas**
   - Las 25 películas con géneros enlazados estrictamente por nombre mediante `JOIN`.
   - Inserciones protegidas con `NOT EXISTS` para permitir cargas repetibles sin errores.

4. **Partes corregidas**
   | Problema | Cómo se detectó | Corrección |
   |---|---|---|
   | Ninguno | Mediante la ejecución y comprobación de rangos en SSMS. | Sin incidencias; los datos de las películas y restricciones de edad encajaron perfectamente. |

5. **Verificación (ejecutada por mí en SSMS)**
   - **Conteos:** 25 películas y 62 relaciones validadas correctamente.
   - **Longitud de sinopsis:** Mínimo 254 y máximo 295 caracteres.
   - **Capturas:** `docs/evidencias/copilot/B-04_t1_chat.png` y `docs/evidencias/copilot/B-04_t1_verificacion.png`.

#### Tanda 2 

1. **Prompt utilizado**
   > Genera un script T-SQL que inserte 25 películas reales y conocidas en dbo.Movies y sus géneros en dbo.MovieGenres... Esta es la tanda 2 de 4. Guárdala en un archivo NUEVO database/03d2_movies.sql, sin modificar los anteriores. Evita estas películas ya creadas: [Lista de películas de la Tanda 1].

2. **Respuesta de la IA**
   - Creó de forma aislada el archivo `database/03d2_movies.sql` con 25 títulos nuevos y sus 59 relaciones de género.
   - Validó longitudes de sinopsis entre 261 y 302 caracteres, uso estricto de géneros existentes en el catálogo y valores permitidos para `MinAge` (`0, 7, 12, 16, 18`).
   - Guardó la evidencia en `docs/evidencias/copilot/B-04_t2_respuesta.sql`.

3. **Partes aceptadas**
   - Las 25 películas con sus respectivas asociaciones correctas y protección de inserción con `NOT EXISTS`.

4. **Partes corregidas**
   | Problema | Cómo se detectó | Corrección |
   |---|---|---|
   | Ninguno | Mediante los diagnósticos automatizados del entorno. | Sin incidencias; estructura, géneros y restricciones correctos. |

5. **Verificación (ejecutada por mí en SSMS)**
   - **Conteos:** 25 películas nuevas y 59 relaciones verificadas tras la ejecución de `03d2_movies.sql` (acumulando 50 películas en total).
   - **Capturas:** `docs/evidencias/copilot/B-04_t2_chat.png` y `docs/evidencias/copilot/B-04_t2_verificacion.png`.

#### Tanda 3 

1. **Prompt utilizado**
   > Genera un script T-SQL que inserte 25 películas reales y conocidas en dbo.Movies y sus géneros en dbo.MovieGenres... Esta es la tanda 3 de 4. Guárdala en un archivo NUEVO database/03d3_movies.sql, sin modificar los anteriores. Evita estas películas ya creadas: [Lista acumulada de las 50 películas previas].

2. **Respuesta de la IA**
   - Creó de forma aislada el archivo `database/03d3_movies.sql` con 25 títulos nuevos y sus 59 relaciones de género.
   - Validó que las sinopsis cumplieran el rango (265-301 caracteres), que la clasificación de edad (`MinAge`) respetara estrictamente los valores permitidos y que no existieran duplicados respecto a las dos tandas anteriores.
   - Guardó la evidencia en `docs/evidencias/copilot/B-04_t3_respuesta.sql`.

3. **Partes aceptadas**
   - Las 25 películas con géneros asociados correctamente mediante nombre y protección con `NOT EXISTS`.

4. **Partes corregidas**
   | Problema | Cómo se detectó | Corrección |
   |---|---|---|
   | Ninguno | Mediante los diagnósticos automáticos del entorno. | Sin incidencias; formato y restricciones correctos. |

5. **Verificación (ejecutada por mí en SSMS)**
   - **Conteos:** 25 películas y 59 relaciones verificadas tras la ejecución de `03d3_movies.sql` (acumulando 75 películas en total).
   - **Capturas:** `docs/evidencias/copilot/B-04_t3_chat.png` y `docs/evidencias/copilot/B-04_t3_verificacion.png`.

#### Tanda 4 

1. **Prompt utilizado**
   > Genera un script T-SQL que inserte 25 películas reales y conocidas en dbo.Movies y sus géneros en dbo.MovieGenres... Esta es la tanda 4 de 4 (la última). Guárdala en un archivo NUEVO database/03d4_movies.sql, sin modificar los anteriores. Evita estas películas ya creadas: [Lista acumulada de las 75 películas previas].

2. **Respuesta de la IA**
   - Creó de forma aislada el archivo `database/03d4_movies.sql` con las últimas 25 películas y sus 53 relaciones de género.
   - Verificó que el conjunto acumulado no presentara duplicados, que las sinopsis mantuvieran el rango de 263 a 299 caracteres y que los géneros existieran en el catálogo.
   - Guardó la evidencia en `docs/evidencias/copilot/B-04_t4_respuesta.sql`.

3. **Partes aceptadas**
   - Las 25 películas finales con la estructura de inserción segura `NOT EXISTS` y géneros enlazados correctamente por nombre.

4. **Partes corregidas**
   | Problema | Cómo se detectó | Corrección |
   |---|---|---|
   | Ninguno | Mediante los diagnósticos automáticos y cruce de exclusión de títulos previos. | Sin incidencias; formato, sinopsis y restricciones correctos. |

5. **Verificación (ejecutada por mí en SSMS)**
   - **Conteos:** 25 películas y 53 relaciones verificadas en la ejecución final de `03d4_movies.sql` (alcanzando un total definitivo de **100 películas y más de 230 relaciones** en `CineChefDB`).
   - **Capturas:** `docs/evidencias/copilot/B-04_t4_chat.png` y `docs/evidencias/copilot/B-04_t4_verificacion.png`.

#### Validación cruzada de datos reales (Muestra de 10 películas)

Para contrastar la veracidad de los datos generados por el modelo frente a fuentes fiables (IMDb / Wikipedia), se seleccionó una muestra aleatoria de 10 películas de la base de datos, aplicando una tolerancia de ±3 minutos en la duración por posibles diferencias en montajes o versiones:

| Película | Año BD | Año fuente | Duración BD | Duración fuente | ¿Coincide? (±3 min) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **2001: A Space Odyssey** | 1968 | 1968 | 149 min | 149 min | **Sí** |
| **Schindler's List** | 1993 | 1993 | 195 min | 195 min | **Sí** |
| **Raging Bull** | 1980 | 1980 | 129 min | 129 min | **Sí** |
| **Wild Strawberries** | 1957 | 1957 | 92 min | 92 min | **Sí** |
| **Rashomon** | 1950 | 1950 | 88 min | 88 min | **Sí** |
| **E.T. the Extra-Terrestrial** | 1982 | 1982 | 115 min | 115 min | **Sí** |
| **Crouching Tiger, Hidden Dragon** | 2000 | 2000 | 120 min | 120 min | **Sí** |
| **Moonlight** | 2016 | 2016 | 111 min | 111 min | **Sí** |
| **One Flew Over the Cuckoo's Nest** | 1975 | 1975 | 133 min | 133 min | **Sí** |
| **Fight Club** | 1999 | 1999 | 139 min | 139 min | **Sí** |

* **Criterio de clasificación de edad (`MinAge`):** Se siguió una aproximación a la clasificación por edades de referencia europea (PEGI/ICAA), asignando valores discretos estrictos (`0, 7, 12, 16 o 18`) en función del contenido temático, el tono dramático y las restricciones parentales de cada obra.

### B-05 - Usuarios, Alergias y Noches de Cine

1. **Prompt utilizado**
   > Genera un script T-SQL que inserte 10 usuarios ficticios en dbo.Users... sus alergias en dbo.UserAllergens... y 30 filas en dbo.MovieNights usando películas y recetas ya existentes... [Prompt completo B-05].

2. **Respuesta de la IA**
   - Creó el archivo `database/03e_users_nights.sql` con 10 usuarios, 9 relaciones de alergias y 30 noches de cine.
   - Realizó una autocorrección inteligente al detectar un conflicto de alérgenos en una receta asignada a un usuario alérgico al gluten, sustituyéndola por una opción segura (*Garden Quinoa Salad*).
   - Validó la integridad referencial por nombre de usuario, títulos, recetas y alérgenos, asegurando restricciones de edad parental adecuadas para los menores.
   - Guardó la evidencia en `docs/evidencias/copilot/B-05_respuesta.sql`.

3. **Partes aceptadas**
   - La distribución demográfica de los 10 usuarios (incluyendo menores) y la asignación de 30 noches de cine con clasificaciones y ratings válidos (1 a 5).

4. **Partes corregidas**
   | Problema | Cómo se detectó | Corrección |
   |---|---|---|
   | Incompatibilidad de alérgenos (Gluten) | Validación cruzada interna del modelo entre el perfil del usuario y los ingredientes de la receta asignada (*Summer Peach and Feta Couscous*). | Se reemplazó la receta conflictiva por *Garden Quinoa Salad* para garantizar la seguridad alimentaria del usuario. |

5. **Verificación (ejecutada por mí en SSMS)**
   - **Conteos:** 10 usuarios, 9 alergias y 30 noches de cine verificadas.
   - **Restricciones:** Cero conflictos de alérgenos y cumplimiento estricto de restricciones de edad parental.
   - **Capturas:** `docs/evidencias/copilot/B-05_chat.png` y `docs/evidencias/copilot/B-05_verificacion.png`.


### Qué se considera una buena ficha
- Hay al menos **una corrección real** documentada. Si Copilot acertó todo a la primera, demuestra con pruebas (no con "parece correcto") que está bien.
- La verificación es **ejecutable** (una consulta con su resultado), no una opinión.
- Se distingue lo que generó Copilot de lo que decidiste tú.
