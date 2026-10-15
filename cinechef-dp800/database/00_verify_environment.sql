/*==============================================================
  CineChef - Fase 1: verificación del entorno (nivel instancia)
  Ejecutar en SSMS 22 conectado a la instancia local.
  Solo lectura: no modifica nada.
==============================================================*/
SET NOCOUNT ON;

SELECT
    @@VERSION                                  AS version_completa,
    SERVERPROPERTY('ProductVersion')           AS product_version,   -- 17.x = SQL Server 2025
    SERVERPROPERTY('ProductMajorVersion')      AS major_version,     -- debe ser 17
    SERVERPROPERTY('Edition')                  AS edition,
    SERVERPROPERTY('IsFullTextInstalled')      AS full_text_instalado,        -- 1 = OK
    SERVERPROPERTY('IsAdvancedAnalyticsInstalled') AS machine_learning_services; -- 1 = OK (necesario para ONNX local)

-- Configuración de runtimes de IA externos (0 = deshabilitado, 1 = habilitado)
SELECT name, value, value_in_use
FROM sys.configurations
WHERE name = N'external AI runtimes enabled';
GO
