/*==============================================================
  CineChef - Fase 1: creación de la base de datos vacía
  - Nivel de compatibilidad 170 (SQL Server 2025)
  - Activa las funciones de vista previa en esta base de datos
==============================================================*/
USE master;
GO
IF DB_ID(N'CineChefDB') IS NULL
    CREATE DATABASE CineChefDB;
GO
ALTER DATABASE CineChefDB SET COMPATIBILITY_LEVEL = 170;
GO
USE CineChefDB;
GO
-- Necesario para ONNX local y, según versión, para el índice vectorial
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO
