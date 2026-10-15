/*==============================================================
  CineChef - Fase 3a: géneros cinematográficos y alérgenos
  Catálogos base para las cargas posteriores.
  El script es repetible y no depende de valores IDENTITY.
==============================================================*/
USE CineChefDB;
GO

INSERT INTO dbo.Genres (Name)
SELECT source.Name
FROM (VALUES
    (N'Drama'),
    (N'Comedy'),
    (N'Animation'),
    (N'Sci-Fi'),
    (N'Fantasy'),
    (N'Romance'),
    (N'Thriller'),
    (N'Horror'),
    (N'Documentary'),
    (N'Adventure'),
    (N'Family'),
    (N'Mystery'),
    (N'Musical'),
    (N'Crime'),
    (N'War'),
    (N'Western'),
    (N'Biography'),
    (N'Action')
) AS source (Name)
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Genres AS target
    WHERE target.Name = source.Name
);
GO

INSERT INTO dbo.Allergens (Name)
SELECT source.Name
FROM (VALUES
    (N'Gluten'),
    (N'Crustaceans'),
    (N'Eggs'),
    (N'Fish'),
    (N'Peanuts'),
    (N'Soybeans'),
    (N'Milk'),
    (N'Tree nuts'),
    (N'Celery'),
    (N'Mustard'),
    (N'Sesame'),
    (N'Sulphites'),
    (N'Lupin'),
    (N'Molluscs')
) AS source (Name)
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Allergens AS target
    WHERE target.Name = source.Name
);
GO

SELECT N'Genres' AS Catalog, COUNT(*) AS ItemCount
FROM dbo.Genres
WHERE Name IN (
    N'Drama', N'Comedy', N'Animation', N'Sci-Fi', N'Fantasy', N'Romance',
    N'Thriller', N'Horror', N'Documentary', N'Adventure', N'Family', N'Mystery',
    N'Musical', N'Crime', N'War', N'Western', N'Biography', N'Action'
)
UNION ALL
SELECT N'Allergens', COUNT(*)
FROM dbo.Allergens
WHERE Name IN (
    N'Gluten', N'Crustaceans', N'Eggs', N'Fish', N'Peanuts', N'Soybeans', N'Milk',
    N'Tree nuts', N'Celery', N'Mustard', N'Sesame', N'Sulphites', N'Lupin', N'Molluscs'
);
GO
