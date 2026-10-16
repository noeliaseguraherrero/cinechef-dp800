/*==============================================================
  CineChef - Fase 3: auditoría de valoraciones (tabla + trigger)
  Registra cada cambio en MovieNights.Rating: valor anterior,
  valor nuevo, cuándo y quién.

  - La tabla de auditoría NO tiene clave foránea hacia MovieNights
    a propósito: el historial debe sobrevivir aunque se borre el plan.
  - Aquí se borra y recrea solo para que la carga completa del proyecto
    sea repetible. En un sistema real una tabla de auditoría no se borra.
  - Solo audita cambios posteriores a la creación del trigger: las
    valoraciones cargadas por los scripts 03* no generan filas.
==============================================================*/
USE CineChefDB;
GO

DROP TABLE IF EXISTS dbo.MovieNightRatingAudit;
GO

CREATE TABLE dbo.MovieNightRatingAudit (
    AuditId    INT IDENTITY(1,1) NOT NULL,
    NightId    INT               NOT NULL,
    OldRating  TINYINT           NULL,      -- NULL = no tenía valoración
    NewRating  TINYINT           NULL,      -- NULL = se ha borrado la valoración
    ChangedAt  DATETIME2(0)      NOT NULL CONSTRAINT DF_RatingAudit_ChangedAt DEFAULT SYSUTCDATETIME(),
    ChangedBy  SYSNAME           NOT NULL CONSTRAINT DF_RatingAudit_ChangedBy  DEFAULT ORIGINAL_LOGIN(),
    CONSTRAINT PK_MovieNightRatingAudit PRIMARY KEY (AuditId)
);
CREATE INDEX IX_RatingAudit_NightId ON dbo.MovieNightRatingAudit (NightId);
GO

/*--------------------------------------------------------------
  El trigger trabaja por conjuntos (puede haber varias filas en
  inserted/deleted) y solo registra si la valoración cambia de verdad.
--------------------------------------------------------------*/
CREATE OR ALTER TRIGGER dbo.trg_MovieNights_RatingAudit
ON dbo.MovieNights
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT dbo.MovieNightRatingAudit (NightId, OldRating, NewRating)
    SELECT i.NightId, d.Rating, i.Rating
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.NightId = i.NightId
    WHERE (d.NightId IS NULL AND i.Rating IS NOT NULL)                       -- plan nuevo ya valorado
       OR (d.NightId IS NOT NULL AND ISNULL(d.Rating, 0) <> ISNULL(i.Rating, 0));  -- cambio de valoración (0 no es un valor válido: 1-5)
END;
GO
