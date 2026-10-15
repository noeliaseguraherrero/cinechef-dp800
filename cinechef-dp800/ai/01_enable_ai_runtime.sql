/*==============================================================
  CineChef - Fase 1: habilitar el runtime de IA externo
  Requiere permiso a nivel de servidor (ALTER SETTINGS).
==============================================================*/
EXEC sp_configure 'external AI runtimes enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO
