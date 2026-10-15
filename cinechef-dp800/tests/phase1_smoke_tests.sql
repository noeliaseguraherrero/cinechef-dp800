/*==============================================================
  CineChef - Fase 1: pruebas de humo dentro de CineChefDB
  Cada prueba devuelve OK / FALLO con un detalle.
  Las pruebas de funciones nuevas usan SQL dinámico para que un
  fallo no impida ejecutar el resto.
==============================================================*/
USE CineChefDB;
GO
SET NOCOUNT ON;

CREATE TABLE #checks (id INT IDENTITY, prueba NVARCHAR(80), resultado NVARCHAR(10), detalle NVARCHAR(400));

-- 1. Versión de SQL Server
INSERT #checks (prueba, resultado, detalle)
SELECT N'SQL Server 2025 (versión mayor 17)',
       CASE WHEN CAST(SERVERPROPERTY('ProductMajorVersion') AS INT) = 17 THEN N'OK' ELSE N'FALLO' END,
       CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(50));

-- 2. Nivel de compatibilidad
INSERT #checks (prueba, resultado, detalle)
SELECT N'Compatibility level 170',
       CASE WHEN compatibility_level = 170 THEN N'OK' ELSE N'FALLO' END,
       CAST(compatibility_level AS NVARCHAR(10))
FROM sys.databases WHERE name = DB_NAME();

-- 3. Full-Text Search instalado
INSERT #checks (prueba, resultado, detalle)
SELECT N'Full-Text Search instalado',
       CASE WHEN CAST(SERVERPROPERTY('IsFullTextInstalled') AS INT) = 1 THEN N'OK' ELSE N'FALLO' END, NULL;

-- 4. Machine Learning Services (requisito de ONNX local)
INSERT #checks (prueba, resultado, detalle)
SELECT N'Machine Learning Services instalado',
       CASE WHEN CAST(SERVERPROPERTY('IsAdvancedAnalyticsInstalled') AS INT) = 1 THEN N'OK' ELSE N'FALLO' END, NULL;

-- 5. Funciones de vista previa activadas en la base de datos
INSERT #checks (prueba, resultado, detalle)
SELECT N'PREVIEW_FEATURES = ON',
       CASE WHEN CAST(value AS NVARCHAR(20)) IN (N'1', N'ON') THEN N'OK' ELSE N'FALLO' END,
       CAST(value AS NVARCHAR(20))
FROM sys.database_scoped_configurations WHERE name = N'PREVIEW_FEATURES';

-- 6. Tipo VECTOR y VECTOR_DISTANCE
DECLARE @r NVARCHAR(400);
BEGIN TRY
    EXEC sp_executesql
        N'DECLARE @a VECTOR(3) = ''[1,0,0]'', @b VECTOR(3) = ''[0,1,0]'';
          SELECT @out = CONCAT(N''distancia coseno = '', VECTOR_DISTANCE(''cosine'', @a, @b));',
        N'@out NVARCHAR(400) OUTPUT', @out = @r OUTPUT;
    INSERT #checks (prueba, resultado, detalle) VALUES (N'Tipo VECTOR y VECTOR_DISTANCE', N'OK', @r);
END TRY
BEGIN CATCH
    INSERT #checks (prueba, resultado, detalle) VALUES (N'Tipo VECTOR y VECTOR_DISTANCE', N'FALLO', ERROR_MESSAGE());
END CATCH;

-- 7. Expresiones regulares
BEGIN TRY
    EXEC sp_executesql
        N'SELECT @out = CASE WHEN REGEXP_LIKE(N''Error 18456'', N''[0-9]{5}'') THEN N''coincide'' ELSE N''no coincide'' END;',
        N'@out NVARCHAR(400) OUTPUT', @out = @r OUTPUT;
    INSERT #checks (prueba, resultado, detalle) VALUES (N'REGEXP_LIKE', N'OK', @r);
END TRY
BEGIN CATCH
    INSERT #checks (prueba, resultado, detalle) VALUES (N'REGEXP_LIKE', N'FALLO', ERROR_MESSAGE());
END CATCH;

-- 8. Fuzzy string matching
BEGIN TRY
    EXEC sp_executesql
        N'SELECT @out = CONCAT(N''EDIT_DISTANCE='', EDIT_DISTANCE(N''Totoro'', N''Totorro''),
                               N'', JARO_WINKLER_DISTANCE='', JARO_WINKLER_DISTANCE(N''Totoro'', N''Totorro''));',
        N'@out NVARCHAR(400) OUTPUT', @out = @r OUTPUT;
    INSERT #checks (prueba, resultado, detalle) VALUES (N'Fuzzy string matching', N'OK', @r);
END TRY
BEGIN CATCH
    INSERT #checks (prueba, resultado, detalle) VALUES (N'Fuzzy string matching', N'FALLO', ERROR_MESSAGE());
END CATCH;

SELECT prueba, resultado, detalle FROM #checks ORDER BY id;
DROP TABLE #checks;
GO
