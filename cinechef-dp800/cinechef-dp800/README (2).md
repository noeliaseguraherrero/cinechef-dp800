# CineChef - La noche de peli perfecta

Mini proyecto de la certificación **Microsoft DP-800: SQL AI Developer Associate**.
CineChef recomienda **una película y una receta que casen entre sí** a partir de una descripción libre del
estado de ánimo (una *vibe*), respetando alergias y control parental. Todo funciona **en local** sobre
**SQL Server 2025**, sin Azure ni Fabric.

> **Nivel seleccionado:** Nivel 3 - Avanzado
> **Modalidad:** individual

## Estado del proyecto

| Fase | Contenido | Estado |
|---|---|---|
| 1. Preparación | Entorno, repositorio, modelo ONNX local | Completada |
| 2. Base de datos | Tablas, restricciones, datos de prueba | Completada |
| Bloque B | Desarrollo SQL asistido por IA (GitHub Copilot) | Completado (ver [documentación](docs/bloque_b_copilot.md)) |
| 3. Objetos T-SQL | Vistas y funciones hechas; procedimientos, trigger y consultas avanzadas pendientes | En curso |
| 4. Seguridad | Roles, RLS, Dynamic Data Masking, EXECUTE AS | En curso |
| 5. Embeddings | Experimento de formato del texto y vectores del catálogo | Completada (ver [docs/embeddings.md](docs/embeddings.md)) |
| 6. Búsqueda | Búsqueda vectorial, Full-Text e híbrida (RRF) | Completada (ver [docs/busqueda.md](docs/busqueda.md)) |
| 7. RAG | Recuperación + contexto + generación | Pendiente |
| 8. Optimización | Planes de ejecución antes/después | Pendiente |
| 9. Cierre | Informe PDF, presentación, conclusiones | Pendiente |

Las secciones marcadas como pendientes se completarán a medida que avance el proyecto.

## Descripción

Elegir qué ver y qué cocinar para una noche en casa es una decisión doble que los buscadores clásicos
(por género o por ingrediente) no resuelven, porque no entienden sensaciones. CineChef representa
películas y recetas como **vectores en el mismo espacio de embeddings**, de modo que una consulta como

> *"Estoy cansado, quiero algo reconfortante y nostálgico"*

puede buscar a la vez en ambos catálogos y proponer un maridaje, filtrando por las alergias del usuario y
su edad.

## Arquitectura

```mermaid
flowchart TD
    U["Usuario"] --> S["SSMS 22 / T-SQL"]
    S --> DB
    subgraph DB["SQL Server 2025 (local) - CineChefDB"]
        T["Tablas, restricciones e indices"]
        V["Columnas VECTOR(384) en Movies y Recipes"]
        FT["Full-Text Search (pendiente)"]
        SEC["RLS y Dynamic Data Masking (pendiente)"]
    end
    DB --> E["Modelo de embeddings local<br/>all-MiniLM-L6-v2 via ONNX Runtime<br/>AI_GENERATE_EMBEDDINGS"]
    DB -. "contexto / prompt (paso manual)" .-> C["GitHub Copilot Chat<br/>generacion del RAG"]
```

- Los **embeddings** se generan dentro de SQL Server con un modelo ONNX local.
- La **generación de texto** del RAG la realiza GitHub Copilot Chat. No se puede invocar desde T-SQL, por lo
  que ese paso es manual: SQL Server construye el contexto y el prompt, y el resultado se documenta como evidencia.

## Tecnologías

SQL Server 2025 (Developer), T-SQL, SSMS 22, ONNX Runtime, modelo all-MiniLM-L6-v2, GitHub Copilot,
PowerShell, Git y GitHub.

## Requisitos

- Windows 11.
- SQL Server 2025 con estas características instaladas:
  - Database Engine Services.
  - **Full-Text and Semantic Extractions for Search**.
  - **Machine Learning Services** (en SQL Server 2025 puede aparecer como *AI Services and Language Extensions*).
- SQL Server Management Studio 22.
- Git y PowerShell. Opcional: `sqlcmd` para el script de carga automática.
- Opcional: VS Code con GitHub Copilot (solo para reproducir el Bloque B; no hace falta para ejecutar la solución).

## Instalación

### 1. Clonar el repositorio
```powershell
git clone <url-del-repositorio>
cd cinechef-dp800
```

### 2. Verificar el entorno
En SSMS, ejecuta `database/00_verify_environment.sql`. Debes ver versión mayor **17**, y `1` en
`full_text_instalado` y `machine_learning_services`. Si alguna es `0`, añade la característica con el
instalador de SQL Server (*add features to an existing installation*).

### 3. Crear la base de datos
Ejecuta `database/01_create_database.sql`. Crea `CineChefDB` con nivel de compatibilidad 170 y activa
`PREVIEW_FEATURES`.

### 4. Pruebas de humo
Ejecuta `tests/phase1_smoke_tests.sql`. Deben salir **8 pruebas en OK**: versión, compatibilidad, Full-Text,
Machine Learning Services, `PREVIEW_FEATURES`, tipo `VECTOR`, expresiones regulares y fuzzy matching.

### 5. Preparar el modelo de embeddings (ONNX local)
Los binarios y el modelo **no están en el repositorio** (ver `.gitignore`); hay que descargarlos:

1. Crear la carpeta `C:\onnx_runtime\model`.
2. Clonar el modelo dentro de `C:\onnx_runtime\model`:
   ```powershell
   cd C:\onnx_runtime\model
   git clone https://huggingface.co/nsense/all-MiniLM-L6-v2-onnx
   ```
   Comprueba que `model.onnx` pesa decenas de MB (si pesa pocos KB es un puntero de Git LFS: ejecuta `git lfs pull`).
3. Descargar **ONNX Runtime** (versión 1.19 o superior, Windows x64) y copiar `onnxruntime.dll` en `C:\onnx_runtime\`.
4. Obtener el tokenizador (se puede compilar desde `mlc-ai/tokenizers-cpp` o usar el que enlaza el artículo oficial
   de Microsoft sobre embeddings locales con ONNX) y **renombrarlo exactamente a `tokenizers_cpp.dll`**.
   Con otro nombre el modelo falla con el error 31739.
5. Ejecutar `ai/00_setup_onnx_runtime.ps1` en PowerShell **como administrador** (da permisos a `MSSQLLaunchpad`).
6. Desbloquear las DLL descargadas: `Unblock-File C:\onnx_runtime\*.dll`.

La carpeta debe quedar así:
```
C:\onnx_runtime\
├── onnxruntime.dll
├── tokenizers_cpp.dll
└── model\all-MiniLM-L6-v2-onnx\   (model.onnx, tokenizer.json, ...)
```

### 6. Registrar y validar el modelo
En SSMS, por este orden:
1. `ai/01_enable_ai_runtime.sql` (activa `external AI runtimes enabled`).
2. `ai/02_create_external_model.sql` (crea `CineChefEmbeddingModel`).
3. `ai/03_test_embeddings.sql`. Debe confirmar la dimensión **384** y que una frase parecida queda más cerca
   que una distinta.

> La sintaxis de `CREATE EXTERNAL MODEL` se basó en un artículo de Microsoft escrito para SQL Server 2025 RC0.
> Si no funciona en tu versión, compárala con la página actual de Microsoft Learn.

### 7. Crear las tablas y cargar los datos
Ejecuta en SSMS, por este orden exacto:

| Orden | Script | Contenido |
|---|---|---|
| 1 | `database/02_create_tables.sql` | 12 tablas (borra y recrea) |
| 2 | `database/03a_lookups.sql` | 18 géneros y 14 alérgenos |
| 3 | `database/03b_ingredients.sql` | 120 ingredientes y sus alérgenos |
| 4 | `database/03c_recipes.sql`, `03c2`, `03c3`, `03c4` | 100 recetas en 4 tandas |
| 5 | `database/03d_movies.sql`, `03d2`, `03d3`, `03d4` | 100 películas en 4 tandas |
| 6 | `database/03e_users_nights.sql` | 10 usuarios, 9 alergias, 30 planes |
| 7 | `database/04_views.sql` | 4 vistas |
| 8 | `database/05_functions.sql` | 2 funciones en línea |
| 9 | `database/06_audit_trigger.sql` | Tabla de auditoría y trigger de valoraciones |
| 10 | `database/07_procedures.sql` | 3 procedimientos almacenados |
| 11 | `database/09_security.sql` | Roles, usuarios de demostración, RLS, DDM y permisos |

O bien, en un solo paso (ver el apartado siguiente): `.\scripts\load_all.ps1`.

### 8. Generar los embeddings del catálogo (requiere el modelo del paso 6)
En SSMS, por este orden:
1. `ai/04_embedding_experiment.sql` (películas) y `ai/04b_recipe_probe.sql` (recetas): generan tres variantes del texto en tablas temporales y miden cuál ordena mejor (MRR, top-k). Elige la variante de cada tipo con sus resultados (películas: `labeled`; recetas: `plain`).
2. `ai/05_generate_embeddings.sql`: ajusta `@MovieVariant` y `@RecipeVariant` si has elegido otras y ejecuta. Rellena `Movies.Embedding` y `Recipes.Embedding` y registra la ejecución en `dbo.EmbeddingRun`.
3. `tests/phase5_embeddings_tests.sql`: comprueba que no falta ningún vector y que regenerar el texto da el mismo vector.
4. `ai/06_embedding_diagnostics.sql` (opcional): mide la distribución de distancias entre pares de películas y películas-recetas.

Estos scripts **no** forman parte de `scripts/load_all.ps1`, porque dependen del modelo ONNX preparado a mano.
Detalle y resultados del experimento en [docs/embeddings.md](docs/embeddings.md).

### 9. Búsqueda inteligente (Fase 6)
En SSMS, por este orden:
1. `ai/07_fulltext.sql`: catálogo e índices Full-Text sobre `Movies`, `Recipes` e `Ingredients`.
2. `ai/08_search.sql`: `usp_SearchMovies`, `usp_SearchRecipes` (búsqueda vectorial, Full-Text o híbrida con Reciprocal Rank Fusion) y `usp_SuggestRecipesForMovie` (maridaje película-receta), con sus permisos.
3. `tests/phase6_search_tests.sql`: 10 pruebas (índices, resultados, alergias, control parental, usuario inexistente, suplantación).
4. `ai/09_search_evaluation.sql` y `ai/09b_search_semantic_probes.sql` (opcionales): comparan vector, texto e híbrida con sondas.

Ejemplos: `EXEC dbo.usp_SearchRecipes @Query = N'comforting hot meal for a cold rainy evening', @UserId = 9;` y `EXEC dbo.usp_SuggestRecipesForMovie @MovieId = 1, @UserId = 9;`.
Tampoco forman parte de `load_all.ps1`. Resultados y limitaciones en [docs/busqueda.md](docs/busqueda.md).

### 10. Verificar la carga
Ejecuta `tests/verify_counts.sql` (conteos), `tests/validate_data.sql` (calidad de los datos), `tests/phase3_objects_tests.sql` (vistas y funciones), `tests/phase3b_tests.sql` (trigger y procedimientos) y `tests/phase4_security_tests.sql` (seguridad, suplantando a cada usuario). La demostración visual está en `tests/security_demo.sql`. Las consultas avanzadas de `database/08_advanced_queries.sql` son de solo lectura y se ejecutan a mano.

## Reproducibilidad desde cero

### Opción A: equipo nuevo
Sigue la sección **Instalación** completa (pasos 1 a 9). Los pasos 5 y 6 (ONNX) son manuales porque los
binarios no se distribuyen con el repositorio.

### Opción B: reiniciar la base de datos en tu equipo
Si el entorno y el modelo ONNX ya están preparados, recrea todo con un solo comando desde la raíz del repositorio:

```powershell
.\scripts\load_all.ps1                 # autenticación de Windows
.\scripts\load_all.ps1 -User sa        # autenticación SQL: pide la contraseña por pantalla
```

El script ejecuta con `sqlcmd` los archivos del paso 7 en orden, se detiene al primer error y termina con
`tests/verify_counts.sql`. La contraseña no se guarda en ningún archivo.

> `02_create_tables.sql` borra y recrea las tablas, así que el script se puede repetir. El modelo
> `CineChefEmbeddingModel` pertenece a la base de datos y no se toca.

### Opción C: borrar todo y empezar de cero
```sql
USE master;
ALTER DATABASE CineChefDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE CineChefDB;
```
Después repite desde el paso 3 (la base de datos nueva necesita registrar de nuevo el modelo, pasos 6 y 7).

### Resultado esperado

`tests/verify_counts.sql` debe mostrar `OK` en las 11 tablas:

| Tabla | Filas |
|---|---|
| Genres | 18 |
| Allergens | 14 |
| Ingredients | 120 |
| IngredientAllergens | 39 |
| Recipes | 100 |
| RecipeIngredients | 500 |
| Movies | 100 |
| MovieGenres | 233 |
| Users | 10 |
| UserAllergies | 9 |
| MovieNights | 30 |

## Base de datos

![Diagrama entidad-relación](docs/modelo_datos.png)

Detalle y diagrama en Mermaid: [docs/modelo_datos.md](docs/modelo_datos.md).

| Tabla | Descripción |
|---|---|
| `Movies` | Título, año, duración, edad mínima (0/7/12/16/18), sinopsis y `Embedding VECTOR(384)` |
| `Genres`, `MovieGenres` | Géneros y relación N:M con películas |
| `Recipes` | Nombre, descripción, tiempo, dificultad (1-3), raciones y `Embedding VECTOR(384)` |
| `Ingredients`, `RecipeIngredients` | Ingredientes y relación N:M con recetas (cantidad y unidad) |
| `Allergens`, `IngredientAllergens` | Los 14 alérgenos de la UE y qué ingrediente contiene cada uno |
| `Users`, `UserAllergies` | Usuarios ficticios y sus alergias (datos sensibles) |
| `UserPrincipals` | Correspondencia entre cada usuario de la aplicación y su usuario de base de datos (la usa RLS) |
| `MovieNights` | Historial de planes: usuario, película, receta, vibe y valoración |

Decisiones de diseño:
- Claves primarias y foráneas en todas las tablas; claves compuestas en las tablas puente.
- Restricciones `CHECK` en años, edades, dificultad, valoraciones y formato del email; `UNIQUE` en nombres.
- Las columnas `Embedding` admiten `NULL` y se rellenan en la Fase 5.
- Solo se crean los índices básicos; los de optimización se añadirán después para poder comparar planes antes y después.

### Datos de prueba
- 100 películas reales y 100 recetas, en inglés. Los títulos y datos básicos de las películas son hechos públicos;
  **las sinopsis y descripciones las generó GitHub Copilot con texto propio**, y los usuarios son ficticios
  (emails `@example.com`). No se copia texto de ninguna web.
- El catálogo está en inglés porque el modelo de embeddings (all-MiniLM-L6-v2) está entrenado sobre todo en inglés.
- La generación asistida por IA está documentada, con prompts, correcciones y verificación, en
  [docs/bloque_b_copilot.md](docs/bloque_b_copilot.md).

## Funcionalidades DP-800 implementadas

| Área | Estado |
|---|---|
| Diseño de base de datos (PK, FK, constraints, tipos, índices básicos) | Hecho |
| Datos de prueba suficientes | Hecho (100 + 100 + usuarios y planes) |
| Desarrollo SQL asistido por IA (Bloque B) | Hecho y documentado |
| Modelo de embeddings local (ONNX) registrado y validado | Hecho |
| Vistas y funciones en línea (con pruebas) | Hecho |
| Procedimientos y trigger | Pendiente |
| Consultas avanzadas: CTE, window functions, JSON, regex, fuzzy matching | Pendiente |
| Seguridad (roles, RLS, Dynamic Data Masking) | Pendiente |
| Generación de embeddings del catálogo y almacenamiento en `VECTOR` | En curso (scripts preparados; falta ejecutar y documentar) |
| Búsqueda vectorial e híbrida (Full-Text + vectores) | Pendiente |
| RAG (SQL Server + contexto + Copilot) | Pendiente |
| Optimización de consultas (planes antes/después) | Pendiente |

## Ejemplos

### Verificación del modelo de embeddings
`ai/03_test_embeddings.sql` confirma que los vectores tienen 384 dimensiones y que el modelo capta significado.
Distancia coseno (0 = idénticos) entre una frase base ("A calm and comforting movie to relax on the sofa") y otras:

| Frase comparada | Distancia coseno |
|---|---|
| Película parecida ("A cozy, soothing film for a quiet evening at home") | 0,031 |
| Thriller violento | 0,091 |
| Receta de sopa de tomate | 0,140 |

El orden es el esperado (más parecido = menor distancia). El rango de valores es comprimido, así que la búsqueda
híbrida combinará **posiciones en el ranking** y no distancias en bruto.

### Validación de los datos
Resultado real de `tests/verify_counts.sql`: las 11 tablas en `OK`. Las capturas están en `docs/evidencias/`.

## Estructura del repositorio

```
cinechef-dp800/
├── README.md
├── .gitignore
├── scripts/
│   └── load_all.ps1            # recrea la BD y carga los datos
├── database/
│   ├── 00_verify_environment.sql
│   ├── 01_create_database.sql
│   ├── 02_create_tables.sql
│   ├── 03a_lookups.sql
│   ├── 03b_ingredients.sql
│   ├── 03c_recipes.sql ... 03c4_recipes.sql
│   ├── 03d_movies.sql  ... 03d4_movies.sql
│   ├── 03e_users_nights.sql
│   ├── 04_views.sql
│   ├── 05_functions.sql
│   ├── 06_audit_trigger.sql
│   ├── 07_procedures.sql
│   ├── 08_advanced_queries.sql
│   └── 09_security.sql
├── ai/
│   ├── 00_setup_onnx_runtime.ps1
│   ├── 01_enable_ai_runtime.sql
│   ├── 02_create_external_model.sql
│   ├── 03_test_embeddings.sql
│   ├── 04_embedding_experiment.sql
│   ├── 04b_recipe_probe.sql
│   ├── 05_generate_embeddings.sql
│   ├── 06_embedding_diagnostics.sql
│   ├── 07_fulltext.sql
│   ├── 08_search.sql
│   ├── 09_search_evaluation.sql
│   └── 09b_search_semantic_probes.sql
├── tests/
│   ├── phase1_smoke_tests.sql
│   ├── verify_counts.sql
│   ├── phase3_objects_tests.sql
│   ├── phase3b_tests.sql
│   ├── phase4_security_tests.sql
│   ├── phase5_embeddings_tests.sql
│   ├── phase6_search_tests.sql
│   ├── security_demo.sql
│   └── validate_data.sql
├── docs/
│   ├── alcance.md
│   ├── modelo_datos.md / modelo_datos.png
│   ├── bloque_b_copilot.md
│   ├── problemas_encontrados.md
│   ├── seguridad.md
│   ├── embeddings.md
│   └── evidencias/             # capturas y respuestas de Copilot
└── presentation/
```

## Problemas encontrados

Resumen en [docs/problemas_encontrados.md](docs/problemas_encontrados.md). Los más relevantes hasta ahora:
- Full-Text Search y Machine Learning Services no estaban instalados: se añadieron a la instancia.
- Error 31739 de `AIRuntimeHost` al generar embeddings: el tokenizador debía llamarse exactamente `tokenizers_cpp.dll`.

## Conclusiones

*(Se completarán al terminar el proyecto: qué se ha aprendido, problemas y soluciones, y mejoras posibles.)*
