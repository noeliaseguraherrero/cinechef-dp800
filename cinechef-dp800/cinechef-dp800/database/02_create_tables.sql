/*==============================================================
  CineChef - Fase 2: creación de tablas (Bloque A)
  12 tablas con PK, FK, UNIQUE, CHECK y DEFAULT.
  Las columnas Embedding VECTOR(384) admiten NULL: se rellenan
  en la Fase 5 con AI_GENERATE_EMBEDDINGS.
  El script es repetible: borra y recrea las tablas.

  Cambios posteriores:
  - Fase 3 (revisión B-06): CK_Users_BirthDate rechaza fechas futuras.
  - Fase 4: tabla UserPrincipals (usuario de la aplicación -> usuario
    de base de datos) y limpieza previa de los objetos de seguridad
    que dependen de las tablas (se recrean en 09_security.sql).
==============================================================*/
USE CineChefDB;
GO

/*-------- Objetos de seguridad que dependen de las tablas --------
  Con SCHEMABINDING no se pueden borrar las tablas mientras existan la
  política RLS y sus funciones de predicado. 09_security.sql los recrea. */
IF EXISTS (SELECT 1 FROM sys.security_policies WHERE name = N'pol_UserData')
    DROP SECURITY POLICY Security.pol_UserData;
IF OBJECT_ID(N'Security.fn_OwnerOrAdmin', N'IF') IS NOT NULL
    DROP FUNCTION Security.fn_OwnerOrAdmin;
IF OBJECT_ID(N'Security.fn_OwnerNutritionistOrAdmin', N'IF') IS NOT NULL
    DROP FUNCTION Security.fn_OwnerNutritionistOrAdmin;
GO

/*-------- Borrado en orden inverso de dependencias --------*/
DROP TABLE IF EXISTS dbo.MovieNights;
DROP TABLE IF EXISTS dbo.UserAllergies;
DROP TABLE IF EXISTS dbo.IngredientAllergens;
DROP TABLE IF EXISTS dbo.RecipeIngredients;
DROP TABLE IF EXISTS dbo.MovieGenres;
DROP TABLE IF EXISTS dbo.UserPrincipals;
DROP TABLE IF EXISTS dbo.Users;
DROP TABLE IF EXISTS dbo.Allergens;
DROP TABLE IF EXISTS dbo.Ingredients;
DROP TABLE IF EXISTS dbo.Recipes;
DROP TABLE IF EXISTS dbo.Movies;
DROP TABLE IF EXISTS dbo.Genres;
GO

/*-------- Catálogo de películas --------*/
CREATE TABLE dbo.Genres (
    GenreId  INT IDENTITY(1,1) NOT NULL,
    Name     NVARCHAR(50)      NOT NULL,
    CONSTRAINT PK_Genres PRIMARY KEY (GenreId),
    CONSTRAINT UQ_Genres_Name UNIQUE (Name)
);

CREATE TABLE dbo.Movies (
    MovieId       INT IDENTITY(1,1) NOT NULL,
    Title         NVARCHAR(200)     NOT NULL,
    ReleaseYear   SMALLINT          NOT NULL,
    RuntimeMin    SMALLINT          NOT NULL,
    MinAge        TINYINT           NOT NULL,   -- edad mínima recomendada (control parental)
    Synopsis      NVARCHAR(1000)    NOT NULL,
    Embedding     VECTOR(384)       NULL,       -- se genera en la Fase 5
    CreatedAt     DATETIME2(0)      NOT NULL CONSTRAINT DF_Movies_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Movies PRIMARY KEY (MovieId),
    CONSTRAINT UQ_Movies_Title_Year UNIQUE (Title, ReleaseYear),
    CONSTRAINT CK_Movies_Year    CHECK (ReleaseYear BETWEEN 1888 AND 2100),
    CONSTRAINT CK_Movies_Runtime CHECK (RuntimeMin BETWEEN 1 AND 600),
    CONSTRAINT CK_Movies_MinAge  CHECK (MinAge IN (0, 7, 12, 16, 18))
);

CREATE TABLE dbo.MovieGenres (
    MovieId INT NOT NULL,
    GenreId INT NOT NULL,
    CONSTRAINT PK_MovieGenres PRIMARY KEY (MovieId, GenreId),
    CONSTRAINT FK_MovieGenres_Movies FOREIGN KEY (MovieId) REFERENCES dbo.Movies (MovieId) ON DELETE CASCADE,
    CONSTRAINT FK_MovieGenres_Genres FOREIGN KEY (GenreId) REFERENCES dbo.Genres (GenreId) ON DELETE CASCADE
);

/*-------- Catálogo de recetas --------*/
CREATE TABLE dbo.Recipes (
    RecipeId      INT IDENTITY(1,1) NOT NULL,
    Name          NVARCHAR(150)     NOT NULL,
    Description   NVARCHAR(1000)    NOT NULL,
    PrepMin       SMALLINT          NOT NULL,   -- tiempo total en minutos
    Difficulty    TINYINT           NOT NULL,   -- 1 fácil, 2 media, 3 difícil
    Servings      TINYINT           NOT NULL,
    Embedding     VECTOR(384)       NULL,       -- se genera en la Fase 5
    CreatedAt     DATETIME2(0)      NOT NULL CONSTRAINT DF_Recipes_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Recipes PRIMARY KEY (RecipeId),
    CONSTRAINT UQ_Recipes_Name UNIQUE (Name),
    CONSTRAINT CK_Recipes_PrepMin    CHECK (PrepMin BETWEEN 1 AND 1440),
    CONSTRAINT CK_Recipes_Difficulty CHECK (Difficulty BETWEEN 1 AND 3),
    CONSTRAINT CK_Recipes_Servings   CHECK (Servings BETWEEN 1 AND 20)
);

CREATE TABLE dbo.Ingredients (
    IngredientId INT IDENTITY(1,1) NOT NULL,
    Name         NVARCHAR(100)     NOT NULL,
    CONSTRAINT PK_Ingredients PRIMARY KEY (IngredientId),
    CONSTRAINT UQ_Ingredients_Name UNIQUE (Name)
);

CREATE TABLE dbo.RecipeIngredients (
    RecipeId     INT           NOT NULL,
    IngredientId INT           NOT NULL,
    Quantity     DECIMAL(9,2)  NULL,            -- NULL = "al gusto"
    Unit         NVARCHAR(20)  NULL,
    CONSTRAINT PK_RecipeIngredients PRIMARY KEY (RecipeId, IngredientId),
    CONSTRAINT FK_RecipeIngredients_Recipes     FOREIGN KEY (RecipeId)     REFERENCES dbo.Recipes (RecipeId) ON DELETE CASCADE,
    CONSTRAINT FK_RecipeIngredients_Ingredients FOREIGN KEY (IngredientId) REFERENCES dbo.Ingredients (IngredientId),
    CONSTRAINT CK_RecipeIngredients_Quantity CHECK (Quantity IS NULL OR Quantity > 0)
);

/*-------- Alérgenos --------*/
CREATE TABLE dbo.Allergens (
    AllergenId INT IDENTITY(1,1) NOT NULL,
    Name       NVARCHAR(50)      NOT NULL,
    CONSTRAINT PK_Allergens PRIMARY KEY (AllergenId),
    CONSTRAINT UQ_Allergens_Name UNIQUE (Name)
);

CREATE TABLE dbo.IngredientAllergens (
    IngredientId INT NOT NULL,
    AllergenId   INT NOT NULL,
    CONSTRAINT PK_IngredientAllergens PRIMARY KEY (IngredientId, AllergenId),
    CONSTRAINT FK_IngredientAllergens_Ingredients FOREIGN KEY (IngredientId) REFERENCES dbo.Ingredients (IngredientId) ON DELETE CASCADE,
    CONSTRAINT FK_IngredientAllergens_Allergens   FOREIGN KEY (AllergenId)   REFERENCES dbo.Allergens (AllergenId)   ON DELETE CASCADE
);

/*-------- Usuarios (datos ficticios; contienen campos sensibles) --------*/
CREATE TABLE dbo.Users (
    UserId     INT IDENTITY(1,1) NOT NULL,
    UserName   NVARCHAR(50)      NOT NULL,
    Email      NVARCHAR(256)     NOT NULL,      -- se enmascara (Dynamic Data Masking, 09_security.sql)
    BirthDate  DATE              NOT NULL,      -- se enmascara y sirve para el control parental
    CreatedAt  DATETIME2(0)      NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Users PRIMARY KEY (UserId),
    CONSTRAINT UQ_Users_UserName UNIQUE (UserName),
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT CK_Users_BirthDate CHECK (BirthDate >= '1900-01-01' AND BirthDate <= CAST(GETDATE() AS DATE)),
    CONSTRAINT CK_Users_Email CHECK (Email LIKE '%_@_%.__%')
);

/*-------- Correspondencia usuario de la aplicación -> usuario de base de datos --------
  Permite que Row-Level Security y los procedimientos sepan qué fila de Users
  corresponde a quien está ejecutando la consulta (USER_NAME()). Se rellena en
  09_security.sql. Ningún rol de usuario tiene acceso directo a esta tabla.   */
CREATE TABLE dbo.UserPrincipals (
    UserId        INT     NOT NULL,
    PrincipalName SYSNAME NOT NULL,
    CONSTRAINT PK_UserPrincipals PRIMARY KEY (UserId),
    CONSTRAINT UQ_UserPrincipals_PrincipalName UNIQUE (PrincipalName),
    CONSTRAINT FK_UserPrincipals_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId) ON DELETE CASCADE
);

CREATE TABLE dbo.UserAllergies (
    UserId     INT NOT NULL,
    AllergenId INT NOT NULL,
    CONSTRAINT PK_UserAllergies PRIMARY KEY (UserId, AllergenId),
    CONSTRAINT FK_UserAllergies_Users     FOREIGN KEY (UserId)     REFERENCES dbo.Users (UserId) ON DELETE CASCADE,
    CONSTRAINT FK_UserAllergies_Allergens FOREIGN KEY (AllergenId) REFERENCES dbo.Allergens (AllergenId)
);

/*-------- Historial de planes --------*/
CREATE TABLE dbo.MovieNights (
    NightId   INT IDENTITY(1,1) NOT NULL,
    UserId    INT               NOT NULL,
    MovieId   INT               NOT NULL,
    RecipeId  INT               NOT NULL,
    Vibe      NVARCHAR(300)     NULL,           -- la consulta original del usuario
    Rating    TINYINT           NULL,           -- valoración 1-5 (NULL = sin valorar)
    PlannedAt DATETIME2(0)      NOT NULL CONSTRAINT DF_MovieNights_PlannedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_MovieNights PRIMARY KEY (NightId),
    CONSTRAINT FK_MovieNights_Users   FOREIGN KEY (UserId)   REFERENCES dbo.Users (UserId),
    CONSTRAINT FK_MovieNights_Movies  FOREIGN KEY (MovieId)  REFERENCES dbo.Movies (MovieId),
    CONSTRAINT FK_MovieNights_Recipes FOREIGN KEY (RecipeId) REFERENCES dbo.Recipes (RecipeId),
    CONSTRAINT CK_MovieNights_Rating CHECK (Rating IS NULL OR Rating BETWEEN 1 AND 5)
);
GO

/*-------- Índices de apoyo a consultas frecuentes --------
  Se crean solo los básicos. Los índices de optimización (Bloque D)
  se añaden más adelante para poder comparar el antes y el después.   */
CREATE INDEX IX_MovieNights_UserId ON dbo.MovieNights (UserId) INCLUDE (MovieId, RecipeId, Rating);
CREATE INDEX IX_Movies_MinAge      ON dbo.Movies (MinAge);
GO

/*-------- Verificación --------*/
SELECT t.name AS tabla,
       (SELECT COUNT(*) FROM sys.columns c WHERE c.object_id = t.object_id)       AS columnas,
       (SELECT COUNT(*) FROM sys.foreign_keys f WHERE f.parent_object_id = t.object_id) AS claves_foraneas,
       (SELECT COUNT(*) FROM sys.check_constraints k WHERE k.parent_object_id = t.object_id) AS checks
FROM sys.tables t
ORDER BY t.name;
GO
