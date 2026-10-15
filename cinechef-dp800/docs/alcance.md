# CineChef - Cierre de alcance (Fase 1)

## Decisiones de diseño

| Decisión | Valor | Motivo |
|---|---|---|
| Nombre de la base de datos | `CineChefDB` | |
| Nivel objetivo | Nivel 3 (Avanzado) | Combina los bloques A-G |
| Modelo de embeddings | all-MiniLM-L6-v2 (ONNX, local) | Ejemplo oficial de Microsoft para SQL Server 2025 |
| Dimensión del vector | 384 | Definida por el modelo |
| Métrica de similitud | Coseno | Adecuada para comparar significado de textos (a justificar en la memoria) |
| Idioma del catálogo | Inglés (sinopsis y descripciones) | El modelo MiniLM está entrenado sobre todo en inglés; la interfaz y las explicaciones, en español |
| Tamaño del catálogo | 80-100 películas, 80-100 recetas | Suficiente para demostrar búsqueda sin coste de generación excesivo |
| Generación de texto (RAG) | GitHub Copilot Chat (paso manual) | SQL Server construye el contexto; Copilot redacta la respuesta |
| Datos | Ficticios y generados con IA | Sin datos personales reales ni problemas de licencia |

## Fuera de alcance
- Interfaz gráfica o aplicación web.
- Uso de Azure o Microsoft Fabric.
- Datos reales de usuarios.

## Checklist de la Fase 1
- [x] SQL Server 2025 instalado (versión mayor 17) con Full-Text Search y Machine Learning Services
- [x] SSMS 22 instalado y conectado
- [ ] Git instalado y configurado (`user.name`, `user.email`)
- [ ] Repositorio creado en GitHub y primer commit subido
- [x] `CineChefDB` creada con nivel de compatibilidad 170
- [x] Pruebas de humo (`tests/phase1_smoke_tests.sql`) ejecutadas y capturadas
- [x] ONNX Runtime, tokenizador y modelo descargados en `C:\onnx_runtime`
- [x] Modelo externo creado y `AI_GENERATE_EMBEDDINGS` devuelve 384 valores
- [ ] GitHub Copilot activo en SSMS 22 y/o VS Code
