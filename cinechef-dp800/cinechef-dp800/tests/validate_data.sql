/*==============================================================
  CineChef - Validación de los datos de prueba (Bloque B)
  Ejecutar tras cargar 03a-03e. Cada bloque indica qué se espera.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

-- 1. Volumen de datos por tabla (esperado: ~80-100 películas y recetas, 18 géneros, 14 alérgenos)
SELECT 'Movies' AS tabla, COUNT(*) AS filas FROM dbo.Movies
UNION ALL SELECT 'Genres', COUNT(*) FROM dbo.Genres
UNION ALL SELECT 'MovieGenres', COUNT(*) FROM dbo.MovieGenres
UNION ALL SELECT 'Recipes', COUNT(*) FROM dbo.Recipes
UNION ALL SELECT 'Ingredients', COUNT(*) FROM dbo.Ingredients
UNION ALL SELECT 'RecipeIngredients', COUNT(*) FROM dbo.RecipeIngredients
UNION ALL SELECT 'Allergens', COUNT(*) FROM dbo.Allergens
UNION ALL SELECT 'IngredientAllergens', COUNT(*) FROM dbo.IngredientAllergens
UNION ALL SELECT 'Users', COUNT(*) FROM dbo.Users
UNION ALL SELECT 'UserAllergies', COUNT(*) FROM dbo.UserAllergies
UNION ALL SELECT 'MovieNights', COUNT(*) FROM dbo.MovieNights;

-- 2. Películas sin género (esperado: 0 filas)
SELECT m.MovieId, m.Title FROM dbo.Movies m
WHERE NOT EXISTS (SELECT 1 FROM dbo.MovieGenres mg WHERE mg.MovieId = m.MovieId);

-- 3. Recetas sin ingredientes (esperado: 0 filas)
SELECT r.RecipeId, r.Name FROM dbo.Recipes r
WHERE NOT EXISTS (SELECT 1 FROM dbo.RecipeIngredients ri WHERE ri.RecipeId = r.RecipeId);

-- 4. Ingredientes que no se usan en ninguna receta (informativo)
SELECT i.IngredientId, i.Name FROM dbo.Ingredients i
WHERE NOT EXISTS (SELECT 1 FROM dbo.RecipeIngredients ri WHERE ri.IngredientId = i.IngredientId);

-- 5. Longitud de textos (esperado: sinopsis y descripciones entre ~150 y ~400 caracteres)
SELECT 'Synopsis' AS campo, MIN(LEN(Synopsis)) AS minimo, AVG(LEN(Synopsis)) AS media, MAX(LEN(Synopsis)) AS maximo FROM dbo.Movies
UNION ALL
SELECT 'Description', MIN(LEN(Description)), AVG(LEN(Description)), MAX(LEN(Description)) FROM dbo.Recipes;

-- 6. Distribución de edades recomendadas (esperado: hay películas en varios tramos, sobre todo 0 y 12+)
SELECT MinAge, COUNT(*) AS peliculas FROM dbo.Movies GROUP BY MinAge ORDER BY MinAge;

-- 7. Películas por género (esperado: ningún género vacío)
SELECT g.Name, COUNT(mg.MovieId) AS peliculas
FROM dbo.Genres g LEFT JOIN dbo.MovieGenres mg ON mg.GenreId = g.GenreId
GROUP BY g.Name ORDER BY peliculas, g.Name;

-- 8. Posibles alérgenos omitidos por la IA (revisar a mano: pueden salir falsos positivos
--    como "coconut milk", "peanut butter" o "cocoa butter")
SELECT i.Name AS ingrediente, 'Milk' AS alergeno_esperado
FROM dbo.Ingredients i
WHERE (i.Name LIKE N'%milk%' OR i.Name LIKE N'%butter%' OR i.Name LIKE N'%cheese%' OR i.Name LIKE N'%cream%' OR i.Name LIKE N'%yogurt%' OR i.Name LIKE N'%yoghurt%')
  AND NOT EXISTS (SELECT 1 FROM dbo.IngredientAllergens ia JOIN dbo.Allergens a ON a.AllergenId = ia.AllergenId
                  WHERE ia.IngredientId = i.IngredientId AND a.Name = N'Milk')
UNION ALL
SELECT i.Name, 'Eggs' FROM dbo.Ingredients i
WHERE i.Name LIKE N'%egg%'
  AND NOT EXISTS (SELECT 1 FROM dbo.IngredientAllergens ia JOIN dbo.Allergens a ON a.AllergenId = ia.AllergenId
                  WHERE ia.IngredientId = i.IngredientId AND a.Name = N'Eggs')
UNION ALL
SELECT i.Name, 'Gluten' FROM dbo.Ingredients i
WHERE (i.Name LIKE N'%flour%' OR i.Name LIKE N'%bread%' OR i.Name LIKE N'%pasta%' OR i.Name LIKE N'%noodle%' OR i.Name LIKE N'%wheat%')
  AND NOT EXISTS (SELECT 1 FROM dbo.IngredientAllergens ia JOIN dbo.Allergens a ON a.AllergenId = ia.AllergenId
                  WHERE ia.IngredientId = i.IngredientId AND a.Name = N'Gluten')
UNION ALL
SELECT i.Name, 'Fish' FROM dbo.Ingredients i
WHERE (i.Name LIKE N'%salmon%' OR i.Name LIKE N'%tuna%' OR i.Name LIKE N'%cod%' OR i.Name LIKE N'%anchov%')
  AND NOT EXISTS (SELECT 1 FROM dbo.IngredientAllergens ia JOIN dbo.Allergens a ON a.AllergenId = ia.AllergenId
                  WHERE ia.IngredientId = i.IngredientId AND a.Name = N'Fish');

-- 9. Control parental: planes en los que un menor ve una película no apta (esperado: 0 filas)
SELECT u.UserName, DATEDIFF(YEAR, u.BirthDate, GETDATE()) AS edad_aprox, m.Title, m.MinAge
FROM dbo.MovieNights n
JOIN dbo.Users  u ON u.UserId  = n.UserId
JOIN dbo.Movies m ON m.MovieId = n.MovieId
WHERE DATEDIFF(YEAR, u.BirthDate, GETDATE()) < m.MinAge;

-- 10. Seguridad alimentaria: planes con una receta que contiene un alérgeno del usuario (esperado: 0 filas)
SELECT u.UserName, r.Name AS receta, a.Name AS alergeno
FROM dbo.MovieNights n
JOIN dbo.Users u               ON u.UserId = n.UserId
JOIN dbo.Recipes r             ON r.RecipeId = n.RecipeId
JOIN dbo.RecipeIngredients ri  ON ri.RecipeId = r.RecipeId
JOIN dbo.IngredientAllergens ia ON ia.IngredientId = ri.IngredientId
JOIN dbo.UserAllergies ua      ON ua.UserId = u.UserId AND ua.AllergenId = ia.AllergenId
JOIN dbo.Allergens a           ON a.AllergenId = ia.AllergenId
GROUP BY u.UserName, r.Name, a.Name;

-- 11. Embeddings pendientes (esperado ahora: todas las filas; tras la Fase 5: 0)
SELECT (SELECT COUNT(*) FROM dbo.Movies  WHERE Embedding IS NULL) AS peliculas_sin_embedding,
       (SELECT COUNT(*) FROM dbo.Recipes WHERE Embedding IS NULL) AS recetas_sin_embedding;
GO
