/*==============================================================
  CineChef - Fase 8 (Bloque D): consultas antes / después de los índices
  Requiere 12_perf_setup.sql. Mide 3 consultas representativas de la app:
    Q1  recetas que contienen un ingrediente (TOP 20)
    Q2  recetas con algún ingrediente que lleva un alérgeno (COUNT)
    Q3  primeras 20 recetas seguras para un usuario (patrón de fn_SafeRecipes)
  Fase "before": solo existen las claves primarias.
  Fase "after":  se crean los índices candidatos.
  Métrica: lecturas lógicas (deterministas) y tiempo; el resultado de cada
  consulta debe ser idéntico antes y después (si no, THROW).
  Para los planes de ejecución: ver el bloque final.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

DROP TABLE IF EXISTS #q, #perf, #missing;
CREATE TABLE #q    (QId INT, Label NVARCHAR(100), Sql NVARCHAR(MAX));
CREATE TABLE #perf (Phase VARCHAR(6), QId INT, Result BIGINT, LogicalReads BIGINT, Ms DECIMAL(10,2));
CREATE TABLE #missing (QueryHint NVARCHAR(400), Impact FLOAT);

INSERT #q VALUES
 (1, N'Q1 Recetas con un ingrediente (TOP 20)',
  N'SELECT @n = COUNT(*) FROM (SELECT TOP (20) r.RecipeId
                               FROM perf.RecipeIngredients AS ri JOIN perf.Recipes AS r ON r.RecipeId = ri.RecipeId
                               WHERE ri.IngredientId = @i ORDER BY r.RecipeId) AS t;'),
 (2, N'Q2 Recetas con algún ingrediente de un alérgeno (COUNT DISTINCT)',
  N'SELECT @n = COUNT(DISTINCT ri.RecipeId)
    FROM perf.RecipeIngredients AS ri
    WHERE ri.IngredientId IN (SELECT ia.IngredientId FROM perf.IngredientAllergens AS ia WHERE ia.AllergenId = @a);'),
 (3, N'Q3 Primeras 20 recetas seguras para un usuario (NOT EXISTS)',
  N'SELECT @n = COUNT(*) FROM (SELECT TOP (20) r.RecipeId FROM perf.Recipes AS r
                               WHERE NOT EXISTS (SELECT 1
                                                 FROM perf.RecipeIngredients AS ri
                                                 JOIN perf.IngredientAllergens AS ia ON ia.IngredientId = ri.IngredientId
                                                 JOIN perf.UserAllergies AS ua ON ua.AllergenId = ia.AllergenId AND ua.UserId = @u
                                                 WHERE ri.RecipeId = r.RecipeId)
                               ORDER BY r.RecipeId) AS t;');

DECLARE @i INT = (SELECT IngredientId FROM dbo.Ingredients ORDER BY IngredientId OFFSET 50 ROWS FETCH NEXT 1 ROWS ONLY);
DECLARE @a INT = (SELECT AllergenId FROM dbo.Allergens WHERE Name = N'Gluten');
DECLARE @u INT = (SELECT TOP 1 UserId FROM dbo.vw_UserProfile ORDER BY AllergenCount DESC, UserId);

DECLARE @phase INT = 1, @ph VARCHAR(6), @qid INT, @sql NVARCHAR(MAX), @n BIGINT, @r0 BIGINT, @r1 BIGINT, @t0 DATETIME2(7), @pass INT;

WHILE @phase <= 2
BEGIN
    IF @phase = 1
    BEGIN
        SET @ph = 'before';
        DROP INDEX IF EXISTS IX_perf_RecipeIngredients_IngredientId ON perf.RecipeIngredients;
        DROP INDEX IF EXISTS IX_perf_IngredientAllergens_AllergenId ON perf.IngredientAllergens;
    END
    ELSE
    BEGIN
        -- Recogemos las sugerencias del optimizador tras la fase "before"
        INSERT #missing
        SELECT TOP (5) CONCAT(d.statement, N' | igualdad: ', COALESCE(d.equality_columns, N'-'),
                              N' | desigualdad: ', COALESCE(d.inequality_columns, N'-'),
                              N' | include: ', COALESCE(d.included_columns, N'-')),
               gs.avg_total_user_cost * gs.avg_user_impact * (gs.user_seeks + gs.user_scans)
        FROM sys.dm_db_missing_index_details AS d
        JOIN sys.dm_db_missing_index_groups AS g ON g.index_handle = d.index_handle
        JOIN sys.dm_db_missing_index_group_stats AS gs ON gs.group_handle = g.index_group_handle
        WHERE d.database_id = DB_ID() AND d.statement LIKE N'%[[]perf]%'
        ORDER BY gs.avg_total_user_cost * gs.avg_user_impact * (gs.user_seeks + gs.user_scans) DESC;

        SET @ph = 'after';
        CREATE INDEX IX_perf_RecipeIngredients_IngredientId ON perf.RecipeIngredients (IngredientId);
        CREATE INDEX IX_perf_IngredientAllergens_AllergenId ON perf.IngredientAllergens (AllergenId);
    END;

    DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT QId, Sql FROM #q ORDER BY QId;
    OPEN c; FETCH NEXT FROM c INTO @qid, @sql;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @pass = 1;
        WHILE @pass <= 2          -- 1.ª pasada: calienta caché y plan; 2.ª: se registra
        BEGIN
            SELECT @r0 = logical_reads FROM sys.dm_exec_requests WHERE session_id = @@SPID;
            SET @t0 = SYSDATETIME();
            EXEC sp_executesql @sql, N'@i INT, @a INT, @u INT, @n BIGINT OUTPUT', @i = @i, @a = @a, @u = @u, @n = @n OUTPUT;
            SELECT @r1 = logical_reads FROM sys.dm_exec_requests WHERE session_id = @@SPID;
            IF @pass = 2
                INSERT #perf VALUES (@ph, @qid, @n, @r1 - @r0, DATEDIFF_BIG(MICROSECOND, @t0, SYSDATETIME()) / 1000.0);
            SET @pass += 1;
        END;
        FETCH NEXT FROM c INTO @qid, @sql;
    END;
    CLOSE c; DEALLOCATE c;

    SET @phase += 1;
END;

-- Resultado comparativo
SELECT q.Label,
       b.Result                                        AS Resultado,
       b.LogicalReads                                  AS LecturasAntes,
       a.LogicalReads                                  AS LecturasDespues,
       CAST(1.0 * b.LogicalReads / NULLIF(a.LogicalReads, 0) AS DECIMAL(9,1)) AS VecesMenosLecturas,
       b.Ms                                            AS MsAntes,
       a.Ms                                            AS MsDespues
FROM #q AS q
JOIN #perf AS b ON b.QId = q.QId AND b.Phase = 'before'
JOIN #perf AS a ON a.QId = q.QId AND a.Phase = 'after'
ORDER BY q.QId;

-- Sugerencias del optimizador (índices que faltaban en la fase "before")
SELECT QueryHint AS SugerenciaDelOptimizador, Impact FROM #missing ORDER BY Impact DESC;

IF EXISTS (SELECT 1 FROM #perf AS b JOIN #perf AS a ON a.QId = b.QId AND a.Phase = 'after'
           WHERE b.Phase = 'before' AND b.Result <> a.Result)
    THROW 50008, N'El resultado de alguna consulta cambia tras crear los índices: revisar.', 1;
GO

/*==============================================================
  PLANES DE EJECUCIÓN (para las capturas del informe)
  1. Menú Consulta > Incluir plan de ejecución real (Ctrl+M).
  2. "Antes": ejecuta primero estas dos líneas para quitar los índices:
       DROP INDEX IF EXISTS IX_perf_RecipeIngredients_IngredientId ON perf.RecipeIngredients;
       DROP INDEX IF EXISTS IX_perf_IngredientAllergens_AllergenId ON perf.IngredientAllergens;
     y después ejecuta la consulta de abajo (SET STATISTICS IO muestra las lecturas en Mensajes).
  3. "Después": crea los índices y repite:
       CREATE INDEX IX_perf_RecipeIngredients_IngredientId ON perf.RecipeIngredients (IngredientId);
       CREATE INDEX IX_perf_IngredientAllergens_AllergenId ON perf.IngredientAllergens (AllergenId);
==============================================================*/
/*
SET STATISTICS IO, TIME ON;
DECLARE @i INT = (SELECT IngredientId FROM dbo.Ingredients ORDER BY IngredientId OFFSET 50 ROWS FETCH NEXT 1 ROWS ONLY);
SELECT TOP (20) r.RecipeId, r.Name
FROM perf.RecipeIngredients AS ri JOIN perf.Recipes AS r ON r.RecipeId = ri.RecipeId
WHERE ri.IngredientId = @i ORDER BY r.RecipeId;
SET STATISTICS IO, TIME OFF;
*/
