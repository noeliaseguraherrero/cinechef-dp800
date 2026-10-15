/*==============================================================
  CineChef - Fase 3c: recetas, tanda 1 de 4
  25 recetas con descripciones atmosféricas y relaciones por nombre.
  Solo utiliza ingredientes cargados en 03b_ingredients.sql.
==============================================================*/
USE CineChefDB;
GO

INSERT INTO dbo.Recipes (Name, Description, PrepMin, Difficulty, Servings)
SELECT source.Name, source.Description, source.PrepMin, source.Difficulty, source.Servings
FROM (VALUES
    (N'Rainy Day Tomato Pasta', N'A warm bowl for gray afternoons, this tomato pasta tastes like a small kitchen glowing against the rain. Sweet tomatoes, garlic, basil, and Parmesan settle into a silky sauce, while the familiar noodles make every forkful feel generous, calm, and quietly nostalgic.', 35, 1, 4),
    (N'Golden Coconut Chickpea Curry', N'Bright spices and creamy coconut milk turn a simple pot of chickpeas into a gentle escape from an ordinary evening. The curry is fragrant without being harsh, with sweet potato and spinach adding color and a soft, comforting finish for sharing.', 45, 2, 4),
    (N'Garden Quinoa Salad', N'Light, crisp, and sunlit, this quinoa salad feels like lunch eaten beside an open window. Cucumber, cherry tomatoes, avocado, herbs, and lime bring a clean freshness, while olive oil and lemon keep the bowl lively enough to brighten a tired afternoon.', 30, 1, 4),
    (N'Smoky Beef and Bean Chili', N'Deep paprika, cumin, and chili warm the room before the first spoonful arrives. Ground beef, tomatoes, peppers, and beans simmer into a hearty chili with a smoky edge, made for movie nights, wool blankets, and conversations that continue long after dinner.', 70, 2, 6),
    (N'Lemon Herb Roast Chicken', N'Roast chicken becomes an easy Sunday ritual here, with lemon, garlic, rosemary, and thyme filling the kitchen with a patient, homely fragrance. Crisp skin gives way to tender meat and roasted vegetables, creating a reassuring meal that feels both simple and celebratory.', 90, 2, 4),
    (N'Spiced Pumpkin Soup', N'Velvet-smooth pumpkin soup carries the mellow warmth of autumn in every spoonful. Cinnamon, cumin, garlic, and cream create a softly spiced balance, while toasted bread makes the bowl feel complete. It is a quiet, amber-colored comfort for slow evenings indoors.', 50, 1, 4),
    (N'Sesame Ginger Noodles', N'These noodles are quick, glossy, and full of lively contrast: sesame and soy bring depth, lime brings sparkle, and chili leaves a pleasant glow. Crunchy cabbage, carrot, and bell pepper make the dish feel energetic, ideal for a bright weeknight when cooking should lift the mood.', 25, 1, 3),
    (N'Mediterranean Baked Cod', N'Cod bakes beneath tomatoes, olives, lemon, parsley, and oregano until the kitchen smells like a relaxed table near the sea. The fish stays tender and delicate, while the bright pan juices invite bread and conversation. It is fresh, graceful, and quietly festive.', 40, 1, 4),
    (N'Rustic Lentil Shepherds Pie', N'This cozy lentil pie has the generous spirit of a family supper, with vegetables and herbs tucked beneath a golden layer of mashed potato. It is earthy, filling, and gentle rather than heavy, the kind of dish that makes a cold night feel more manageable.', 75, 2, 6),
    (N'Summer Peach and Feta Couscous', N'Sweet peach, salty feta, herbs, and couscous create a plate that feels like late summer captured at its brightest. Lemon and olive oil keep it fresh, while the soft grains make it satisfying. Serve it when the evening is warm and nobody wants a hurried meal.', 25, 1, 4),
    (N'Creamy Mushroom Risotto', N'Slow stirring turns rice, mushrooms, onion, butter, cream, and Parmesan into a deeply soothing risotto. Its woodland flavor feels generous and intimate, perfect for a rainy date night or a quiet celebration where the pleasure comes from lingering over every warm bite.', 55, 2, 4),
    (N'Spicy Prawn Rice', N'Garlic, lime, chili, prawns, and rice meet in a colorful pan with the cheerful heat of a busy night market. The seafood stays sweet and tender, while paprika and parsley round out the flavor. It is playful, quick, and made to wake up a sleepy dinner table.', 35, 2, 4),
    (N'Apple Cinnamon Oat Breakfast', N'Soft oats, apple, cinnamon, honey, raisins, and walnuts make breakfast feel like an old wool sweater on a cool morning. The bowl is creamy, gently sweet, and warmly scented, offering an unhurried start that can make even a rushed day feel a little kinder.', 20, 1, 2),
    (N'Roasted Vegetable Frittata', N'Eggs hold together a colorful tangle of zucchini, bell pepper, spinach, mushrooms, and onion in this relaxed frittata. Cheddar adds a savory finish, while fresh herbs keep it light. It belongs at a lazy brunch, where slices can be shared without anyone watching the clock.', 40, 1, 4),
    (N'Peanut Tofu Lettuce Cups', N'Crisp lettuce cups carry golden tofu, cabbage, carrot, lime, sesame, and a bright peanut sauce. Each bite is crunchy, creamy, tangy, and a little surprising, making this a social meal for evenings when everyone wants to assemble dinner and choose their own balance of heat.', 35, 2, 4),
    (N'Vegetable Minestrone', N'A generous pot of minestrone fills the room with the homely scent of tomato, garlic, herbs, beans, vegetables, and pasta. It is colorful without fuss, substantial without heaviness, and especially welcome after a long day when comfort should come by the ladleful.', 60, 1, 6),
    (N'Herb Lamb Couscous', N'Fragrant lamb, couscous, apricots, cumin, cinnamon, and parsley create a plate with warm North African character. Sweet and savory notes meet softly, making each mouthful feel festive and welcoming. It is a dish for generous portions, bright stories, and an unhurried table.', 55, 2, 4),
    (N'Balsamic Chicken with Peaches', N'Juicy chicken meets caramelized peach, balsamic vinegar, basil, and black pepper in a sweet-savory supper that feels both familiar and new. The sauce is glossy and bright, turning ordinary ingredients into a graceful meal for a golden evening or a small celebration.', 45, 2, 4),
    (N'Creamy Spinach and Salmon Pasta', N'Salmon, spinach, cream, lemon, garlic, and pasta make a soothing bowl with a clean, buttery finish. It feels luxurious without becoming loud, suited to a reflective evening when good food, soft light, and a favorite film are enough company.', 40, 2, 4),
    (N'Black Bean Corn Tacos', N'Warm tortillas hold black beans, corn, avocado, tomato, lime, chili, and coriander-like parsley for a bright, casual feast. The textures keep changing from creamy to crisp, and the colors bring instant energy to a table built for friends and easy laughter.', 30, 1, 4),
    (N'Vegetable Eggplant Moussaka', N'Layers of eggplant, tomato, onion, lentils, herbs, and creamy sauce bake into a deeply comforting casserole. The top turns golden while the vegetables become tender and rich, creating a slow, generous meal that feels made for family kitchens and second helpings.', 85, 3, 6),
    (N'Mango Coconut Rice Pudding', N'Creamy rice, coconut milk, mango, vanilla, and cinnamon turn dessert into a soft tropical lullaby. It is fragrant but not overwhelming, with bright fruit cutting through the richness. Serve it chilled for a gentle ending that feels sunny even after dark.', 45, 1, 4),
    (N'Warm Brie Apple Toasts', N'Crunchy bread, melting cream cheese, apple, walnuts, honey, and thyme create little toasts that balance crisp, creamy, sweet, and woodsy flavors. They feel special enough for guests but easy enough for a quiet snack beside a comforting film.', 20, 1, 4),
    (N'Rosemary Pork with Apples', N'Pork loin roasts with apple, onion, rosemary, thyme, and a touch of balsamic vinegar, filling the kitchen with a familiar autumn fragrance. The meat stays tender while the fruit softens into a fragrant relish, making a calm, generous centerpiece for a cool evening.', 65, 2, 4),
    (N'Chickpea Spinach Shakshuka', N'Tomato, peppers, chickpeas, spinach, cumin, and eggs simmer into a richly colored skillet that is warm, spicy, and deeply inviting. Tearable bread makes it wonderfully communal. It is the kind of supper that turns simple pantry ingredients into a lively shared moment.', 45, 2, 4)
) AS source (Name, Description, PrepMin, Difficulty, Servings)
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Recipes AS target
    WHERE target.Name = source.Name
);
GO

INSERT INTO dbo.RecipeIngredients (RecipeId, IngredientId, Quantity, Unit)
SELECT recipe.RecipeId, ingredient.IngredientId, source.Quantity, source.Unit
FROM (VALUES
    (N'Rainy Day Tomato Pasta', N'Pasta', 350.00, N'g'),
    (N'Rainy Day Tomato Pasta', N'Tomato', 500.00, N'g'),
    (N'Rainy Day Tomato Pasta', N'Garlic', 2.00, N'cloves'),
    (N'Rainy Day Tomato Pasta', N'Basil', NULL, N'to taste'),
    (N'Rainy Day Tomato Pasta', N'Parmesan', 60.00, N'g'),
    (N'Golden Coconut Chickpea Curry', N'Chickpeas', 400.00, N'g'),
    (N'Golden Coconut Chickpea Curry', N'Coconut milk', 400.00, N'ml'),
    (N'Golden Coconut Chickpea Curry', N'Sweet potato', 300.00, N'g'),
    (N'Golden Coconut Chickpea Curry', N'Spinach', 150.00, N'g'),
    (N'Golden Coconut Chickpea Curry', N'Curry powder', 2.00, N'tbsp'),
    (N'Garden Quinoa Salad', N'Quinoa', 250.00, N'g'),
    (N'Garden Quinoa Salad', N'Cucumber', 1.00, N'unit'),
    (N'Garden Quinoa Salad', N'Cherry tomatoes', 250.00, N'g'),
    (N'Garden Quinoa Salad', N'Avocado', 1.00, N'unit'),
    (N'Garden Quinoa Salad', N'Lime', 1.00, N'unit'),
    (N'Smoky Beef and Bean Chili', N'Ground beef', 500.00, N'g'),
    (N'Smoky Beef and Bean Chili', N'Black beans', 400.00, N'g'),
    (N'Smoky Beef and Bean Chili', N'Tomato', 500.00, N'g'),
    (N'Smoky Beef and Bean Chili', N'Bell pepper', 1.00, N'unit'),
    (N'Smoky Beef and Bean Chili', N'Chili powder', 1.00, N'tbsp'),
    (N'Lemon Herb Roast Chicken', N'Chicken thighs', 800.00, N'g'),
    (N'Lemon Herb Roast Chicken', N'Lemon', 1.00, N'unit'),
    (N'Lemon Herb Roast Chicken', N'Garlic', 3.00, N'cloves'),
    (N'Lemon Herb Roast Chicken', N'Rosemary', NULL, N'to taste'),
    (N'Lemon Herb Roast Chicken', N'Potato', 500.00, N'g'),
    (N'Spiced Pumpkin Soup', N'Pumpkin', 700.00, N'g'),
    (N'Spiced Pumpkin Soup', N'Cream', 150.00, N'ml'),
    (N'Spiced Pumpkin Soup', N'Onion', 1.00, N'unit'),
    (N'Spiced Pumpkin Soup', N'Cumin', 1.00, N'tsp'),
    (N'Spiced Pumpkin Soup', N'Bread', 4.00, N'slices'),
    (N'Sesame Ginger Noodles', N'Noodles', 300.00, N'g'),
    (N'Sesame Ginger Noodles', N'Soy sauce', 3.00, N'tbsp'),
    (N'Sesame Ginger Noodles', N'Sesame seeds', 2.00, N'tbsp'),
    (N'Sesame Ginger Noodles', N'Cabbage', 200.00, N'g'),
    (N'Sesame Ginger Noodles', N'Carrot', 2.00, N'unit'),
    (N'Mediterranean Baked Cod', N'Cod', 600.00, N'g'),
    (N'Mediterranean Baked Cod', N'Tomato', 300.00, N'g'),
    (N'Mediterranean Baked Cod', N'Olives', 80.00, N'g'),
    (N'Mediterranean Baked Cod', N'Lemon', 1.00, N'unit'),
    (N'Mediterranean Baked Cod', N'Oregano', 1.00, N'tsp'),
    (N'Rustic Lentil Shepherds Pie', N'Lentils', 400.00, N'g'),
    (N'Rustic Lentil Shepherds Pie', N'Potato', 700.00, N'g'),
    (N'Rustic Lentil Shepherds Pie', N'Carrot', 2.00, N'unit'),
    (N'Rustic Lentil Shepherds Pie', N'Peas', 150.00, N'g'),
    (N'Rustic Lentil Shepherds Pie', N'Thyme', NULL, N'to taste'),
    (N'Summer Peach and Feta Couscous', N'Peach', 2.00, N'unit'),
    (N'Summer Peach and Feta Couscous', N'Feta', 120.00, N'g'),
    (N'Summer Peach and Feta Couscous', N'Couscous', 250.00, N'g'),
    (N'Summer Peach and Feta Couscous', N'Lemon', 1.00, N'unit'),
    (N'Summer Peach and Feta Couscous', N'Parsley', NULL, N'to taste'),
    (N'Creamy Mushroom Risotto', N'Rice', 300.00, N'g'),
    (N'Creamy Mushroom Risotto', N'Mushrooms', 350.00, N'g'),
    (N'Creamy Mushroom Risotto', N'Butter', 50.00, N'g'),
    (N'Creamy Mushroom Risotto', N'Cream', 150.00, N'ml'),
    (N'Creamy Mushroom Risotto', N'Parmesan', 70.00, N'g'),
    (N'Spicy Prawn Rice', N'Prawns', 500.00, N'g'),
    (N'Spicy Prawn Rice', N'Rice', 300.00, N'g'),
    (N'Spicy Prawn Rice', N'Red chili', 1.00, N'unit'),
    (N'Spicy Prawn Rice', N'Lime', 1.00, N'unit'),
    (N'Spicy Prawn Rice', N'Paprika', 1.00, N'tsp'),
    (N'Apple Cinnamon Oat Breakfast', N'Oats', 160.00, N'g'),
    (N'Apple Cinnamon Oat Breakfast', N'Apple', 1.00, N'unit'),
    (N'Apple Cinnamon Oat Breakfast', N'Cinnamon', 1.00, N'tsp'),
    (N'Apple Cinnamon Oat Breakfast', N'Honey', 2.00, N'tbsp'),
    (N'Apple Cinnamon Oat Breakfast', N'Walnuts', 40.00, N'g'),
    (N'Roasted Vegetable Frittata', N'Eggs', 6.00, N'unit'),
    (N'Roasted Vegetable Frittata', N'Zucchini', 1.00, N'unit'),
    (N'Roasted Vegetable Frittata', N'Bell pepper', 1.00, N'unit'),
    (N'Roasted Vegetable Frittata', N'Spinach', 100.00, N'g'),
    (N'Roasted Vegetable Frittata', N'Cheddar', 100.00, N'g'),
    (N'Peanut Tofu Lettuce Cups', N'Tofu', 400.00, N'g'),
    (N'Peanut Tofu Lettuce Cups', N'Lettuce', 1.00, N'head'),
    (N'Peanut Tofu Lettuce Cups', N'Peanut butter', 80.00, N'g'),
    (N'Peanut Tofu Lettuce Cups', N'Cabbage', 150.00, N'g'),
    (N'Peanut Tofu Lettuce Cups', N'Sesame seeds', 1.00, N'tbsp'),
    (N'Vegetable Minestrone', N'Pasta', 180.00, N'g'),
    (N'Vegetable Minestrone', N'Kidney beans', 300.00, N'g'),
    (N'Vegetable Minestrone', N'Tomato', 400.00, N'g'),
    (N'Vegetable Minestrone', N'Carrot', 2.00, N'unit'),
    (N'Vegetable Minestrone', N'Zucchini', 1.00, N'unit'),
    (N'Herb Lamb Couscous', N'Lamb mince', 500.00, N'g'),
    (N'Herb Lamb Couscous', N'Couscous', 300.00, N'g'),
    (N'Herb Lamb Couscous', N'Dried apricots', 80.00, N'g'),
    (N'Herb Lamb Couscous', N'Cumin', 1.00, N'tsp'),
    (N'Herb Lamb Couscous', N'Cinnamon', 0.50, N'tsp'),
    (N'Balsamic Chicken with Peaches', N'Chicken breast', 600.00, N'g'),
    (N'Balsamic Chicken with Peaches', N'Peach', 2.00, N'unit'),
    (N'Balsamic Chicken with Peaches', N'Balsamic vinegar', 3.00, N'tbsp'),
    (N'Balsamic Chicken with Peaches', N'Basil', NULL, N'to taste'),
    (N'Balsamic Chicken with Peaches', N'Black pepper', NULL, N'to taste'),
    (N'Creamy Spinach and Salmon Pasta', N'Salmon', 400.00, N'g'),
    (N'Creamy Spinach and Salmon Pasta', N'Spaghetti', 300.00, N'g'),
    (N'Creamy Spinach and Salmon Pasta', N'Spinach', 150.00, N'g'),
    (N'Creamy Spinach and Salmon Pasta', N'Cream', 150.00, N'ml'),
    (N'Creamy Spinach and Salmon Pasta', N'Lemon', 1.00, N'unit'),
    (N'Black Bean Corn Tacos', N'Tortillas', 8.00, N'unit'),
    (N'Black Bean Corn Tacos', N'Black beans', 400.00, N'g'),
    (N'Black Bean Corn Tacos', N'Corn', 180.00, N'g'),
    (N'Black Bean Corn Tacos', N'Avocado', 1.00, N'unit'),
    (N'Black Bean Corn Tacos', N'Lime', 1.00, N'unit'),
    (N'Vegetable Eggplant Moussaka', N'Eggplant', 2.00, N'unit'),
    (N'Vegetable Eggplant Moussaka', N'Lentils', 300.00, N'g'),
    (N'Vegetable Eggplant Moussaka', N'Tomato', 500.00, N'g'),
    (N'Vegetable Eggplant Moussaka', N'Wheat flour', 30.00, N'g'),
    (N'Vegetable Eggplant Moussaka', N'Milk', 400.00, N'ml'),
    (N'Mango Coconut Rice Pudding', N'Rice', 180.00, N'g'),
    (N'Mango Coconut Rice Pudding', N'Coconut milk', 400.00, N'ml'),
    (N'Mango Coconut Rice Pudding', N'Mango', 1.00, N'unit'),
    (N'Mango Coconut Rice Pudding', N'Vanilla', NULL, N'to taste'),
    (N'Mango Coconut Rice Pudding', N'Cinnamon', NULL, N'to taste'),
    (N'Warm Brie Apple Toasts', N'Bread', 4.00, N'slices'),
    (N'Warm Brie Apple Toasts', N'Cream cheese', 120.00, N'g'),
    (N'Warm Brie Apple Toasts', N'Apple', 1.00, N'unit'),
    (N'Warm Brie Apple Toasts', N'Walnuts', 40.00, N'g'),
    (N'Warm Brie Apple Toasts', N'Honey', 2.00, N'tbsp'),
    (N'Rosemary Pork with Apples', N'Pork loin', 700.00, N'g'),
    (N'Rosemary Pork with Apples', N'Apple', 2.00, N'unit'),
    (N'Rosemary Pork with Apples', N'Onion', 1.00, N'unit'),
    (N'Rosemary Pork with Apples', N'Rosemary', NULL, N'to taste'),
    (N'Rosemary Pork with Apples', N'Balsamic vinegar', 2.00, N'tbsp'),
    (N'Chickpea Spinach Shakshuka', N'Chickpeas', 300.00, N'g'),
    (N'Chickpea Spinach Shakshuka', N'Eggs', 6.00, N'unit'),
    (N'Chickpea Spinach Shakshuka', N'Tomato', 500.00, N'g'),
    (N'Chickpea Spinach Shakshuka', N'Bell pepper', 1.00, N'unit'),
    (N'Chickpea Spinach Shakshuka', N'Bread', 4.00, N'slices')
) AS source (RecipeName, IngredientName, Quantity, Unit)
JOIN dbo.Recipes AS recipe ON recipe.Name = source.RecipeName
JOIN dbo.Ingredients AS ingredient ON ingredient.Name = source.IngredientName
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.RecipeIngredients AS target
    WHERE target.RecipeId = recipe.RecipeId
      AND target.IngredientId = ingredient.IngredientId
);
GO

SELECT N'Recipes' AS Catalog, COUNT(*) AS ItemCount,
       MIN(LEN(Description)) AS MinDescriptionLength,
       MAX(LEN(Description)) AS MaxDescriptionLength
FROM dbo.Recipes
WHERE Name IN (
    N'Rainy Day Tomato Pasta', N'Golden Coconut Chickpea Curry', N'Garden Quinoa Salad',
    N'Smoky Beef and Bean Chili', N'Lemon Herb Roast Chicken', N'Spiced Pumpkin Soup',
    N'Sesame Ginger Noodles', N'Mediterranean Baked Cod', N'Rustic Lentil Shepherds Pie',
    N'Summer Peach and Feta Couscous', N'Creamy Mushroom Risotto', N'Spicy Prawn Rice',
    N'Apple Cinnamon Oat Breakfast', N'Roasted Vegetable Frittata', N'Peanut Tofu Lettuce Cups',
    N'Vegetable Minestrone', N'Herb Lamb Couscous', N'Balsamic Chicken with Peaches',
    N'Creamy Spinach and Salmon Pasta', N'Black Bean Corn Tacos', N'Vegetable Eggplant Moussaka',
    N'Mango Coconut Rice Pudding', N'Warm Brie Apple Toasts', N'Rosemary Pork with Apples',
    N'Chickpea Spinach Shakshuka'
);
SELECT N'RecipeIngredients' AS Catalog, COUNT(*) AS ItemCount
FROM dbo.RecipeIngredients AS ri
JOIN dbo.Recipes AS r ON r.RecipeId = ri.RecipeId
WHERE r.Name IN (
    N'Rainy Day Tomato Pasta', N'Golden Coconut Chickpea Curry', N'Garden Quinoa Salad',
    N'Smoky Beef and Bean Chili', N'Lemon Herb Roast Chicken', N'Spiced Pumpkin Soup',
    N'Sesame Ginger Noodles', N'Mediterranean Baked Cod', N'Rustic Lentil Shepherds Pie',
    N'Summer Peach and Feta Couscous', N'Creamy Mushroom Risotto', N'Spicy Prawn Rice',
    N'Apple Cinnamon Oat Breakfast', N'Roasted Vegetable Frittata', N'Peanut Tofu Lettuce Cups',
    N'Vegetable Minestrone', N'Herb Lamb Couscous', N'Balsamic Chicken with Peaches',
    N'Creamy Spinach and Salmon Pasta', N'Black Bean Corn Tacos', N'Vegetable Eggplant Moussaka',
    N'Mango Coconut Rice Pudding', N'Warm Brie Apple Toasts', N'Rosemary Pork with Apples',
    N'Chickpea Spinach Shakshuka'
);
GO
