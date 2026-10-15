/*==============================================================
  CineChef - Fase 3e: usuarios ficticios, alergias y noches
  10 usuarios, sus alergias y 30 planes, relacionados por nombre.
  Todos los datos personales son ficticios y usan example.com.
==============================================================*/
USE CineChefDB;
GO

INSERT INTO dbo.Users (UserName, Email, BirthDate)
SELECT source.UserName, source.Email, source.BirthDate
FROM (VALUES
    (N'Alice Carter',N'alice.carter@example.com',CONVERT(date,'1981-04-12')),
    (N'Bruno Silva',N'bruno.silva@example.com',CONVERT(date,'1994-09-27')),
    (N'Clara Novak',N'clara.novak@example.com',CONVERT(date,'2016-02-18')),
    (N'Diego Rossi',N'diego.rossi@example.com',CONVERT(date,'2014-11-06')),
    (N'Elena Martin',N'elena.martin@example.com',CONVERT(date,'2008-07-21')),
    (N'Fatima Khan',N'fatima.khan@example.com',CONVERT(date,'1990-01-30')),
    (N'Gabriel Chen',N'gabriel.chen@example.com',CONVERT(date,'2012-05-15')),
    (N'Hana Petrov',N'hana.petrov@example.com',CONVERT(date,'2001-12-03')),
    (N'Isaac Brown',N'isaac.brown@example.com',CONVERT(date,'1968-08-25')),
    (N'Julia Costa',N'julia.costa@example.com',CONVERT(date,'1999-06-11'))
) AS source (UserName,Email,BirthDate)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Users AS target WHERE target.UserName=source.UserName);
GO

INSERT INTO dbo.UserAllergies (UserId,AllergenId)
SELECT users.UserId, allergens.AllergenId
FROM (VALUES
    (N'Diego Rossi',N'Milk'),
    (N'Elena Martin',N'Gluten'),
    (N'Fatima Khan',N'Peanuts'),
    (N'Gabriel Chen',N'Fish'),
    (N'Hana Petrov',N'Eggs'),
    (N'Isaac Brown',N'Milk'),
    (N'Isaac Brown',N'Gluten'),
    (N'Julia Costa',N'Soybeans'),
    (N'Julia Costa',N'Sesame')
) AS source (UserName,AllergenName)
JOIN dbo.Users AS users ON users.UserName=source.UserName
JOIN dbo.Allergens AS allergens ON allergens.Name=source.AllergenName
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.UserAllergies AS target
    WHERE target.UserId=users.UserId AND target.AllergenId=allergens.AllergenId
);
GO

INSERT INTO dbo.MovieNights (UserId,MovieId,RecipeId,Vibe,Rating)
SELECT users.UserId,movies.MovieId,recipes.RecipeId,source.Vibe,source.Rating
FROM (VALUES
    (N'Alice Carter',N'Casablanca',1942,N'nostalgic and romantic',5,N'Rainy Day Tomato Pasta'),
    (N'Alice Carter',N'The Godfather',1972,N'grand and intense',4,N'Creamy Mushroom Risotto'),
    (N'Alice Carter',N'Cinema Paradiso',1988,N'warm and nostalgic',5,N'Herb Lamb Couscous'),
    (N'Bruno Silva',N'Back to the Future',1985,N'playful and energetic',5,N'Black Bean Corn Tacos'),
    (N'Bruno Silva',N'Parasite',2019,N'tense and darkly funny',4,N'Smoky Beef and Bean Chili'),
    (N'Bruno Silva',N'The Grand Budapest Hotel',2014,N'whimsical and bittersweet',5,N'Vegetable Minestrone'),
    (N'Clara Novak',N'Toy Story',1995,N'playful and comforting',5,N'Garden Quinoa Salad'),
    (N'Clara Novak',N'My Neighbor Totoro',1988,N'gentle and magical',5,N'Golden Coconut Chickpea Curry'),
    (N'Clara Novak',N'The Lion King',1994,N'bright and heartfelt',5,N'Mango Coconut Rice Pudding'),
    (N'Diego Rossi',N'Spirited Away',2001,N'magical and adventurous',5,N'Garden Quinoa Salad'),
    (N'Diego Rossi',N'Toy Story',1995,N'playful and nostalgic',4,N'Golden Coconut Chickpea Curry'),
    (N'Diego Rossi',N'The Iron Giant',1999,N'tender and hopeful',5,N'Smoky Beef and Bean Chili'),
    (N'Elena Martin',N'The Truman Show',1998,N'curious and thoughtful',4,N'Garden Quinoa Salad'),
    (N'Elena Martin',N'WALL-E',2008,N'gentle and hopeful',5,N'Golden Coconut Chickpea Curry'),
    (N'Elena Martin',N'Amelie',2001,N'whimsical and warm',5,N'Garden Quinoa Salad'),
    (N'Fatima Khan',N'The Apartment',1960,N'funny and tender',5,N'Creamy Spinach and Salmon Pasta'),
    (N'Fatima Khan',N'Rocky',1976,N'hopeful and motivating',4,N'Lemon Herb Roast Chicken'),
    (N'Fatima Khan',N'Before Sunrise',1995,N'romantic and reflective',5,N'Mediterranean Baked Cod'),
    (N'Gabriel Chen',N'Jurassic Park',1993,N'thrilling and adventurous',5,N'Golden Coconut Chickpea Curry'),
    (N'Gabriel Chen',N'The Princess Bride',1987,N'funny and romantic',5,N'Rustic Lentil Shepherds Pie'),
    (N'Gabriel Chen',N'Back to the Future',1985,N'fast and joyful',4,N'Garden Quinoa Salad'),
    (N'Hana Petrov',N'12 Angry Men',1957,N'tense and thoughtful',5,N'Mediterranean Baked Cod'),
    (N'Hana Petrov',N'The Lives of Others',2006,N'quiet and morally tense',5,N'Smoky Beef and Bean Chili'),
    (N'Hana Petrov',N'Lost in Translation',2003,N'quiet and melancholy',4,N'Garden Quinoa Salad'),
    (N'Isaac Brown',N'The Shawshank Redemption',1994,N'patient and hopeful',5,N'Golden Coconut Chickpea Curry'),
    (N'Isaac Brown',N'The Godfather',1972,N'operatic and serious',5,N'Smoky Beef and Bean Chili'),
    (N'Isaac Brown',N'Lawrence of Arabia',1962,N'epic and contemplative',4,N'Garden Quinoa Salad'),
    (N'Julia Costa',N'Eternal Sunshine of the Spotless Mind',2004,N'tender and bittersweet',5,N'Rainy Day Tomato Pasta'),
    (N'Julia Costa',N'Moonlight',2016,N'intimate and luminous',5,N'Mediterranean Baked Cod'),
    (N'Julia Costa',N'Cinema Paradiso',1988,N'nostalgic and heartfelt',5,N'Vegetable Minestrone')
) AS source (UserName,Title,ReleaseYear,Vibe,Rating,RecipeName)
JOIN dbo.Users AS users ON users.UserName=source.UserName
JOIN dbo.Movies AS movies ON movies.Title=source.Title AND movies.ReleaseYear=source.ReleaseYear
JOIN dbo.Recipes AS recipes ON recipes.Name=source.RecipeName
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.MovieNights AS target
    WHERE target.UserId=users.UserId AND target.MovieId=movies.MovieId AND target.RecipeId=recipes.RecipeId AND target.Vibe=source.Vibe
);
GO

SELECT N'Users' AS Catalog,COUNT(*) AS ItemCount FROM dbo.Users WHERE Email LIKE N'%@example.com'
UNION ALL SELECT N'UserAllergies',COUNT(*) FROM dbo.UserAllergies
UNION ALL SELECT N'MovieNights',COUNT(*) FROM dbo.MovieNights;
GO

SELECT u.UserName, m.Title, m.MinAge
FROM dbo.MovieNights AS nights
JOIN dbo.Users AS u ON u.UserId=nights.UserId
JOIN dbo.Movies AS m ON m.MovieId=nights.MovieId
WHERE DATEDIFF(YEAR,u.BirthDate,GETDATE()) < m.MinAge;

SELECT u.UserName, r.Name AS RecipeName, allergens.Name AS AllergenName
FROM dbo.MovieNights AS nights
JOIN dbo.Users AS u ON u.UserId=nights.UserId
JOIN dbo.Recipes AS r ON r.RecipeId=nights.RecipeId
JOIN dbo.RecipeIngredients AS recipeIngredients ON recipeIngredients.RecipeId=r.RecipeId
JOIN dbo.IngredientAllergens AS ingredientAllergens ON ingredientAllergens.IngredientId=recipeIngredients.IngredientId
JOIN dbo.UserAllergies AS userAllergies ON userAllergies.UserId=u.UserId AND userAllergies.AllergenId=ingredientAllergens.AllergenId
JOIN dbo.Allergens AS allergens ON allergens.AllergenId=ingredientAllergens.AllergenId
GROUP BY u.UserName,r.Name,allergens.Name;
GO
