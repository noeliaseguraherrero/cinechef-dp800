/*==============================================================
  CineChef - Fase 6 (Bloque F): índices Full-Text
  Catálogo CineChefFT con índices sobre:
    dbo.Movies       (Title, Synopsis)
    dbo.Recipes      (Name, Description)
    dbo.Ingredients  (Name)
  Son la parte "léxica" de la búsqueda híbrida: encuentran palabras
  concretas (incluidas formas flexionadas: chickpea/chickpeas) que el
  embedding puede diluir. Repetible: no vuelve a crear lo que existe.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = N'CineChefFT')
    CREATE FULLTEXT CATALOG CineChefFT;
GO

DECLARE @t TABLE (tbl SYSNAME, cols NVARCHAR(200));
INSERT @t VALUES (N'Movies', N'[Title], [Synopsis]'),
                 (N'Recipes', N'[Name], [Description]'),
                 (N'Ingredients', N'[Name]');

DECLARE @tbl SYSNAME, @cols NVARCHAR(200), @pk SYSNAME, @sql NVARCHAR(MAX);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT tbl, cols FROM @t;
OPEN c; FETCH NEXT FROM c INTO @tbl, @cols;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.' + @tbl))
    BEGIN
        SELECT @pk = i.name FROM sys.indexes AS i
        WHERE i.object_id = OBJECT_ID(N'dbo.' + @tbl) AND i.is_primary_key = 1;

        SET @sql = N'CREATE FULLTEXT INDEX ON dbo.' + QUOTENAME(@tbl) + N' (' + @cols + N') KEY INDEX '
                 + QUOTENAME(@pk) + N' ON CineChefFT WITH CHANGE_TRACKING AUTO;';
        EXEC (@sql);
    END;
    FETCH NEXT FROM c INTO @tbl, @cols;
END;
CLOSE c; DEALLOCATE c;

-- Espera a que termine la población inicial (máx. 60 s)
DECLARE @i INT = 0;
WHILE FULLTEXTCATALOGPROPERTY(N'CineChefFT', N'PopulateStatus') <> 0 AND @i < 60
BEGIN
    WAITFOR DELAY '00:00:01';
    SET @i += 1;
END;

SELECT OBJECT_NAME(fi.object_id) AS tabla, fi.is_enabled, fi.change_tracking_state_desc,
       FULLTEXTCATALOGPROPERTY(N'CineChefFT', N'ItemCount') AS items_catalogo
FROM sys.fulltext_indexes AS fi
WHERE fi.object_id IN (OBJECT_ID(N'dbo.Movies'), OBJECT_ID(N'dbo.Recipes'), OBJECT_ID(N'dbo.Ingredients'));
GO
