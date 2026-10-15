/*==============================================================
  CineChef - Fase 3b: ingredientes y alérgenos
  120 ingredientes en inglés y relaciones por nombre.
  El script es repetible y no depende de valores IDENTITY.
==============================================================*/
USE CineChefDB;
GO

INSERT INTO dbo.Ingredients (Name)
SELECT source.Name
FROM (VALUES
    (N'Onion'), (N'Garlic'), (N'Carrot'), (N'Celery stalk'), (N'Potato'),
    (N'Sweet potato'), (N'Bell pepper'), (N'Red chili'), (N'Zucchini'),
    (N'Eggplant'), (N'Spinach'), (N'Kale'), (N'Broccoli'), (N'Cauliflower'),
    (N'Green beans'), (N'Peas'), (N'Corn'), (N'Tomato'), (N'Cherry tomatoes'),
    (N'Cucumber'), (N'Lettuce'), (N'Mushrooms'), (N'Pumpkin'), (N'Asparagus'),
    (N'Leek'), (N'Cabbage'), (N'Avocado'), (N'Olives'), (N'Apple'), (N'Banana'),
    (N'Lemon'), (N'Lime'), (N'Orange'),
    (N'Pear'), (N'Peach'), (N'Pineapple'), (N'Mango'), (N'Strawberries'),
    (N'Blueberries'), (N'Raspberries'), (N'Grapes'), (N'Raisins'),
    (N'Dried apricots'), (N'Coconut'), (N'Chicken breast'),
    (N'Chicken thighs'), (N'Ground beef'), (N'Beef steak'), (N'Pork loin'),
    (N'Bacon'), (N'Ham'), (N'Turkey breast'), (N'Lamb mince'), (N'Sausage'),
    (N'Salmon'), (N'Tuna'), (N'Cod'), (N'Prawns'), (N'Shrimp'), (N'Mussels'),
    (N'Squid'), (N'Anchovies'), (N'Milk'), (N'Butter'), (N'Cream'),
    (N'Cream cheese'), (N'Cheddar'), (N'Parmesan'), (N'Mozzarella'), (N'Feta'),
    (N'Yogurt'), (N'Eggs'), (N'Wheat flour'), (N'Bread'), (N'Breadcrumbs'),
    (N'Pasta'), (N'Spaghetti'), (N'Noodles'), (N'Oats'), (N'Couscous'),
    (N'Rice'), (N'Quinoa'), (N'Cornmeal'), (N'Tortillas'), (N'Chickpeas'),
    (N'Lentils'), (N'Kidney beans'), (N'Black beans'), (N'Tofu'),
    (N'Soy sauce'), (N'Peanuts'), (N'Peanut butter'), (N'Almonds'),
    (N'Walnuts'), (N'Cashews'), (N'Sesame seeds'), (N'Tahini'), (N'Salt'),
    (N'Black pepper'), (N'Paprika'), (N'Cumin'), (N'Cinnamon'), (N'Oregano'),
    (N'Basil'), (N'Thyme'), (N'Rosemary'), (N'Parsley'), (N'Chili powder'),
    (N'Curry powder'), (N'Bay leaves'), (N'Vanilla'), (N'Honey'),
    (N'Olive oil'), (N'Vegetable oil'), (N'Vinegar'), (N'Balsamic vinegar'),
    (N'Mustard'), (N'Mayonnaise'), (N'Tomato paste'), (N'Coconut milk')
) AS source (Name)
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Ingredients AS target
    WHERE target.Name = source.Name
);
GO

INSERT INTO dbo.IngredientAllergens (IngredientId, AllergenId)
SELECT ingredient.IngredientId, allergen.AllergenId
FROM (VALUES
    (N'Celery stalk', N'Celery'),
    (N'Milk', N'Milk'),
    (N'Butter', N'Milk'),
    (N'Cream', N'Milk'),
    (N'Cream cheese', N'Milk'),
    (N'Cheddar', N'Milk'),
    (N'Parmesan', N'Milk'),
    (N'Mozzarella', N'Milk'),
    (N'Feta', N'Milk'),
    (N'Yogurt', N'Milk'),
    (N'Eggs', N'Eggs'),
    (N'Wheat flour', N'Gluten'),
    (N'Bread', N'Gluten'),
    (N'Breadcrumbs', N'Gluten'),
    (N'Pasta', N'Gluten'),
    (N'Spaghetti', N'Gluten'),
    (N'Noodles', N'Gluten'),
    (N'Oats', N'Gluten'),
    (N'Couscous', N'Gluten'),
    (N'Tortillas', N'Gluten'),
    (N'Soy sauce', N'Soybeans'),
    (N'Soy sauce', N'Gluten'),
    (N'Tofu', N'Soybeans'),
    (N'Peanuts', N'Peanuts'),
    (N'Peanut butter', N'Peanuts'),
    (N'Almonds', N'Tree nuts'),
    (N'Walnuts', N'Tree nuts'),
    (N'Cashews', N'Tree nuts'),
    (N'Sesame seeds', N'Sesame'),
    (N'Tahini', N'Sesame'),
    (N'Mustard', N'Mustard'),
    (N'Salmon', N'Fish'),
    (N'Tuna', N'Fish'),
    (N'Cod', N'Fish'),
    (N'Anchovies', N'Fish'),
    (N'Prawns', N'Crustaceans'),
    (N'Shrimp', N'Crustaceans'),
    (N'Mussels', N'Molluscs'),
    (N'Squid', N'Molluscs')
) AS source (IngredientName, AllergenName)
JOIN dbo.Ingredients AS ingredient ON ingredient.Name = source.IngredientName
JOIN dbo.Allergens AS allergen ON allergen.Name = source.AllergenName
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.IngredientAllergens AS target
    WHERE target.IngredientId = ingredient.IngredientId
      AND target.AllergenId = allergen.AllergenId
);
GO

SELECT N'Ingredients' AS Catalog, COUNT(*) AS ItemCount
FROM dbo.Ingredients
WHERE Name IN (
    N'Onion', N'Garlic', N'Carrot', N'Celery stalk', N'Potato', N'Sweet potato',
    N'Bell pepper', N'Red chili', N'Zucchini', N'Eggplant', N'Spinach', N'Kale',
    N'Broccoli', N'Cauliflower', N'Green beans', N'Peas', N'Corn', N'Tomato',
    N'Cherry tomatoes', N'Cucumber', N'Lettuce', N'Mushrooms', N'Pumpkin',
    N'Asparagus', N'Leek', N'Cabbage', N'Avocado', N'Olives', N'Apple',
    N'Banana', N'Lemon', N'Lime', N'Orange', N'Pear',
    N'Peach', N'Pineapple', N'Mango', N'Strawberries', N'Blueberries',
    N'Raspberries', N'Grapes', N'Raisins', N'Dried apricots', N'Coconut',
    N'Chicken breast', N'Chicken thighs', N'Ground beef', N'Beef steak', N'Pork loin',
    N'Bacon', N'Ham', N'Turkey breast', N'Lamb mince', N'Sausage', N'Salmon',
    N'Tuna', N'Cod', N'Prawns', N'Shrimp', N'Mussels', N'Squid', N'Anchovies',
    N'Milk', N'Butter', N'Cream', N'Cream cheese', N'Cheddar', N'Parmesan',
    N'Mozzarella', N'Feta', N'Yogurt', N'Eggs', N'Wheat flour', N'Bread',
    N'Breadcrumbs', N'Pasta', N'Spaghetti', N'Noodles', N'Oats', N'Couscous',
    N'Rice', N'Quinoa', N'Cornmeal', N'Tortillas', N'Chickpeas', N'Lentils',
    N'Kidney beans', N'Black beans', N'Tofu', N'Soy sauce', N'Peanuts',
    N'Peanut butter', N'Almonds', N'Walnuts', N'Cashews', N'Sesame seeds', N'Tahini',
    N'Salt', N'Black pepper', N'Paprika', N'Cumin', N'Cinnamon', N'Oregano',
    N'Basil', N'Thyme', N'Rosemary', N'Parsley', N'Chili powder', N'Curry powder',
    N'Bay leaves', N'Vanilla', N'Honey', N'Olive oil', N'Vegetable oil', N'Vinegar',
    N'Balsamic vinegar', N'Mustard', N'Mayonnaise', N'Tomato paste', N'Coconut milk'
);
SELECT N'IngredientAllergens' AS Catalog, COUNT(*) AS ItemCount
FROM dbo.IngredientAllergens;
GO
