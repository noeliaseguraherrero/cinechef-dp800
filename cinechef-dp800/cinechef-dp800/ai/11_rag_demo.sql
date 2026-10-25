/*==============================================================
  CineChef - Fase 7: demostración paso a paso del RAG
  Haz UNA pregunta cada vez. Sustituye @uid por el usuario que quieras
  (p. ej. el que tiene más alergias) y escribe la pregunta EN INGLÉS.
==============================================================*/
USE CineChefDB;
GO

-- 0. Elegir usuario y ver su perfil
SELECT TOP 3 UserId, UserName, Age, Allergens FROM dbo.vw_UserProfile ORDER BY AllergenCount DESC, UserId;
GO

-- 1. Construir el prompt CON contexto (RAG). Se muestra el RagId y el prompt línea a línea.
DECLARE @rag INT;
EXEC dbo.usp_BuildRagPrompt
     @Question = N'a comforting dinner for a rainy night to watch with friends',
     @UserId   = 9,
     @WithContext = 0,
     @RagId    = @rag OUTPUT;
GO

DECLARE @rag INT;
EXEC dbo.usp_BuildRagPrompt
     @Question = N'a scary movie night with a spooky dinner',
     @UserId   = 3,
     @WithContext = 0,
     @RagId    = @rag OUTPUT;
GO

DECLARE @rag INT;
EXEC dbo.usp_BuildRagPrompt
     @Question = N'authentic japanese ramen with pork belly and a samurai film',
     @UserId   = 9,
     @WithContext = 0,
     @RagId    = @rag OUTPUT;
GO
/* 2. Selecciona TODA la columna PromptLine, cópiala y pégala en GitHub Copilot Chat.
      Anota qué modelo muestra Copilot. Copia su respuesta completa.

   3. (Línea base) Repite el paso 1 con @WithContext = 0 y la MISMA pregunta,
      y pega ese prompt en una conversación NUEVA de Copilot.                    */

-- 4. Registrar la respuesta (cambia el RagId; duplica los apóstrofos ' dentro del texto)
EXEC dbo.usp_RecordRagAnswer
    @RagId = 9,
    @Answer = N'Para una noche lluviosa con amigos, prepara la sopa de gambas, coco y lima: su caldo sedoso y su calor suave resultan reconfortantes y algo aventureros [R80]. Acompáñala con El apartamento, una comedia dramática romántica cálida y esperanzadora, perfecta para compartir mientras la lluvia cae afuera [M5].',
    @Answersource = N'GitHub Copilot Chat';

EXEC dbo.usp_RecordRagAnswer
    @RagId = 13,
    @Answer = N'Película: El apartamento (1960), una comedia romántica cálida y entrañable, ideal para compartir con amigos en una noche lluviosa.
Receta: sopa cremosa de calabaza y coco, preparada con calabaza, leche de coco, cebolla, zanahoria, caldo sin gluten y especias. Es reconfortante, naturalmente sin gluten y sin leche.',
    @Answersource = N'GitHub Copilot Chat';

EXEC dbo.usp_RecordRagAnswer
    @RagId = 14, -- Reemplaza este 11 por el RagId real que te haya devuelto la ejecución sin contexto de la pregunta 2
    @Answer = N'Película: Coraline y la puerta secreta, una aventura de fantasía oscura, inquietante y apropiada para una noche de miedo moderado a los 10 años.
Receta: pizzas momia, usando bases de pizza, salsa de tomate, queso, aceitunas negras y tiras de pimiento. Coloca el queso en tiras cruzadas para formar vendas y añade aceitunas como ojos antes de hornear. Es una cena divertida, espeluznante y fácil de preparar juntos.',
    @Answersource = N'GitHub Copilot Chat';

EXEC dbo.usp_RecordRagAnswer
    @RagId = 15, -- Reemplaza este 4 por el RagId real que te haya devuelto la ejecución con contexto de la pregunta 2
    @Answer = N'Para una noche misteriosa, elige Spirited Away, con espíritus extraños, peligro y una atmósfera de miedo suave, apropiada desde los 7 años [M8].
Prepara risotto cremoso de champiñones, cuyo sabor boscoso y aspecto reconfortante pueden dar un toque de "caldero encantado" a la cena [R11].',
    @Answersource = N'GitHub Copilot Chat';

EXEC dbo.usp_RecordRagAnswer
    @RagId = 16, -- Reemplaza este 5 por el RagId real que te haya devuelto la ejecución con contexto de la pregunta 3
    @Answer = N'No hay una combinación que cumpla exactamente lo pedido: Seven Samurai sí es una película japonesa de samuráis [M17], pero ninguna receta del contexto es ramen auténtico ni utiliza panceta de cerdo. La opción más cercana sería cerdo al romero con manzanas [R24], aunque no es ramen.',
    @Answersource = N'GitHub Copilot Chat';

EXEC dbo.usp_RecordRagAnswer
    @RagId = 17, -- Reemplaza este 12 por el RagId real que te haya devuelto la ejecución sin contexto de la pregunta 3
    @Answer = N'Película: Los siete samuráis (1954), una obra maestra épica y humana sobre guerreros que defienden una aldea [M17].
Receta: ramen japonés con panceta de cerdo, caldo de cerdo y pollo, huevo marinado, cebolleta, setas y fideos de arroz sin gluten. Usa tamari en lugar de salsa de soja para evitar el gluten y no añadas leche. Es una adaptación apta para tu perfil, aunque el ramen tradicional suele llevar fideos de trigo.',
    @Answersource = N'GitHub Copilot Chat';

-- 5. Verificar la respuesta en SQL (¿solo cita lo recuperado? ¿sin alérgenos? ¿película apta?)
EXEC dbo.usp_VerifyRagAnswer @RagId = 9;
GO

EXEC dbo.usp_VerifyRagAnswer @RagId = 13;
GO

EXEC dbo.usp_VerifyRagAnswer @RagId = 14;
GO

EXEC dbo.usp_VerifyRagAnswer @RagId = 15;
GO

EXEC dbo.usp_VerifyRagAnswer @RagId = 16;
GO

EXEC dbo.usp_VerifyRagAnswer @RagId = 17;
GO
-- 6. Historial de sesiones
SELECT RagId, UserId, LEFT(Question, 60) AS Question, WithContext, RecipeIds, MovieIds, CreatedAt, AnswerSource
FROM dbo.RagSession ORDER BY RagId;
GO
