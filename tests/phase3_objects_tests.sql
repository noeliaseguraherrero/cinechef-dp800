/*==============================================================
  CineChef - Fase 3: pruebas de vistas y funciones
  Los valores esperados de fn_SafeRecipes y de las vistas de
  alérgenos proceden de consultas escritas de forma independiente
  (resultado de la Fase 2), no de los propios objetos probados.
  Falla (THROW) si alguna prueba da REVISAR.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

DROP TABLE IF EXISTS #c;   -- permite repetir el script en la misma sesión tras un fallo
CREATE TABLE #c (id INT IDENTITY, prueba NVARCHAR(120), resultado NVARCHAR(10), detalle NVARCHAR(200));

-- 1. vw_RecipeAllergens: una fila por receta
INSERT #c (prueba, resultado, detalle)
SELECT N'vw_RecipeAllergens: 100 filas', IIF(COUNT(*) = 100, N'OK', N'REVISAR'), CAST(COUNT(*) AS NVARCHAR(20))
FROM dbo.vw_RecipeAllergens;

-- 2. vw_RecipeAllergens: recetas afectadas por alérgeno (valores medidos en la Fase 2)
INSERT #c (prueba, resultado, detalle)
SELECT CONCAT(N'vw_RecipeAllergens: recetas con ', e.alergeno),
       IIF(x.n = e.esperado, N'OK', N'REVISAR'),
       CONCAT(N'esperado ', e.esperado, N', actual ', x.n)
FROM (VALUES (N'Gluten',40),(N'Milk',35),(N'Eggs',11),(N'Fish',10),(N'Tree nuts',6),(N'Soybeans',6),
             (N'Sesame',6),(N'Crustaceans',4),(N'Molluscs',3),(N'Mustard',3),(N'Peanuts',2),(N'Celery',1)
     ) AS e(alergeno, esperado)
CROSS APPLY (SELECT COUNT(*) AS n FROM dbo.vw_RecipeAllergens AS v
             WHERE v.Allergens LIKE N'%' + e.alergeno + N'%') AS x;

-- 3. fn_SafeRecipes: recetas seguras por usuario (valores medidos en la Fase 2)
INSERT #c (prueba, resultado, detalle)
SELECT CONCAT(N'fn_SafeRecipes: ', e.UserName),
       IIF(x.n = e.esperado, N'OK', N'REVISAR'),
       CONCAT(N'esperado ', e.esperado, N', actual ', x.n)
FROM dbo.Users AS u
JOIN (VALUES (N'Isaac Brown',42),(N'Elena Martin',60),(N'Diego Rossi',65),(N'Hana Petrov',89),
             (N'Gabriel Chen',90),(N'Julia Costa',91),(N'Fatima Khan',98),
             (N'Alice Carter',100),(N'Bruno Silva',100),(N'Clara Novak',100)
     ) AS e(UserName, esperado) ON e.UserName = u.UserName
CROSS APPLY (SELECT COUNT(*) AS n FROM dbo.fn_SafeRecipes(u.UserId)) AS x;

-- 4. fn_SafeRecipes con un usuario que no existe: debe fallar cerrado (0 filas)
INSERT #c (prueba, resultado, detalle)
SELECT N'fn_SafeRecipes: usuario inexistente devuelve 0 filas',
       IIF(COUNT(*) = 0, N'OK', N'REVISAR'), CAST(COUNT(*) AS NVARCHAR(20))
FROM dbo.fn_SafeRecipes(-1);

-- 5. vw_UserProfile: la edad solo puede diferir en 1 año de DATEDIFF(YEAR) y nunca ser mayor
INSERT #c (prueba, resultado, detalle)
SELECT N'vw_UserProfile: edad calculada correctamente',
       IIF(COUNT(*) = 0, N'OK', N'REVISAR'), CONCAT(COUNT(*), N' usuarios con edad incoherente')
FROM dbo.vw_UserProfile AS p
JOIN dbo.Users AS u ON u.UserId = p.UserId
WHERE p.Age NOT IN (DATEDIFF(YEAR, u.BirthDate, GETDATE()), DATEDIFF(YEAR, u.BirthDate, GETDATE()) - 1);

-- 6. fn_AllowedMovies: nunca devuelve una película con edad mínima superior a la del usuario
INSERT #c (prueba, resultado, detalle)
SELECT N'fn_AllowedMovies: ninguna película no apta',
       IIF(COUNT(*) = 0, N'OK', N'REVISAR'), CONCAT(COUNT(*), N' películas no aptas devueltas')
FROM dbo.vw_UserProfile AS p
CROSS APPLY dbo.fn_AllowedMovies(p.UserId) AS f
WHERE f.MinAge > p.Age;

-- 7. fn_AllowedMovies: los mayores de 18 ven todo el catálogo
INSERT #c (prueba, resultado, detalle)
SELECT N'fn_AllowedMovies: adultos ven las 100 películas',
       IIF(COUNT(*) = 0, N'OK', N'REVISAR'), CONCAT(COUNT(*), N' adultos con catálogo incompleto')
FROM dbo.vw_UserProfile AS p
WHERE p.Age >= 18
  AND (SELECT COUNT(*) FROM dbo.fn_AllowedMovies(p.UserId)) <> (SELECT COUNT(*) FROM dbo.Movies);

-- 8. Vistas de texto para embeddings: sin nulos y con longitud razonable (el modelo admite ~256 tokens)
INSERT #c (prueba, resultado, detalle)
SELECT N'vw_MovieSearchText: 100 filas sin texto vacío',
       IIF(COUNT(*) = 100 AND SUM(CASE WHEN SearchText IS NULL OR LEN(SearchText) = 0 THEN 1 ELSE 0 END) = 0, N'OK', N'REVISAR'),
       CONCAT(N'longitud máxima ', MAX(LEN(SearchText)))
FROM dbo.vw_MovieSearchText;

INSERT #c (prueba, resultado, detalle)
SELECT N'vw_RecipeSearchText: 100 filas sin texto vacío',
       IIF(COUNT(*) = 100 AND SUM(CASE WHEN SearchText IS NULL OR LEN(SearchText) = 0 THEN 1 ELSE 0 END) = 0, N'OK', N'REVISAR'),
       CONCAT(N'longitud máxima ', MAX(LEN(SearchText)))
FROM dbo.vw_RecipeSearchText;

INSERT #c (prueba, resultado, detalle)
SELECT N'Textos de embedding por debajo de ~1000 caracteres',
       IIF(x.n = 0, N'OK', N'REVISAR'), CONCAT(x.n, N' textos demasiado largos')
FROM (SELECT (SELECT COUNT(*) FROM dbo.vw_MovieSearchText  WHERE LEN(SearchText) > 1000)
            + (SELECT COUNT(*) FROM dbo.vw_RecipeSearchText WHERE LEN(SearchText) > 1000) AS n) AS x;

-- 9. Corrección B-06 (1): una receta sin ingredientes no se devuelve a nadie.
--    Se crea dentro de una transacción y se deshace.
DECLARE @alice INT = (SELECT UserId FROM dbo.Users WHERE UserName = N'Alice Carter');
DECLARE @vacia INT;
BEGIN TRAN;
    INSERT dbo.Recipes (Name, Description, PrepMin, Difficulty, Servings)
    VALUES (N'TEST empty recipe', N'Recipe without ingredients used only by the test.', 5, 1, 1);
    SELECT @vacia = COUNT(*) FROM dbo.fn_SafeRecipes(@alice) WHERE Name = N'TEST empty recipe';
ROLLBACK TRAN;
INSERT #c (prueba, resultado, detalle)
VALUES (N'fn_SafeRecipes: receta sin ingredientes no se devuelve',
        IIF(@vacia = 0, N'OK', N'REVISAR'), CONCAT(N'filas devueltas: ', @vacia));

-- 10. Corrección B-06 (2): no se admiten fechas de nacimiento futuras (la restricción debe rechazar la fila).
DECLARE @rechazada BIT = 0;
BEGIN TRAN;
    BEGIN TRY
        INSERT dbo.Users (UserName, Email, BirthDate)
        VALUES (N'test_future', N'future@example.com', DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
    END TRY
    BEGIN CATCH
        SET @rechazada = 1;
    END CATCH;
ROLLBACK TRAN;
INSERT #c (prueba, resultado, detalle)
VALUES (N'Users: fecha de nacimiento futura rechazada',
        IIF(@rechazada = 1, N'OK', N'REVISAR'), CONCAT(N'rechazada: ', @rechazada));

SELECT prueba, resultado, detalle FROM #c ORDER BY id;

IF EXISTS (SELECT 1 FROM #c WHERE resultado <> N'OK')
    THROW 50002, N'Alguna prueba de la Fase 3 ha dado REVISAR.', 1;

DROP TABLE #c;
GO
