# Modelo de datos de CineChef

![Diagrama entidad-relación](modelo_datos.png)

## Diagrama (Mermaid, se renderiza en GitHub)

```mermaid
erDiagram
    Movies ||--o{ MovieGenres : tiene
    Genres ||--o{ MovieGenres : clasifica
    Recipes ||--o{ RecipeIngredients : contiene
    Ingredients ||--o{ RecipeIngredients : "se usa en"
    Ingredients ||--o{ IngredientAllergens : "puede contener"
    Allergens ||--o{ IngredientAllergens : "esta en"
    Users ||--o{ UserAllergies : declara
    Allergens ||--o{ UserAllergies : "afecta a"
    Users ||--o{ MovieNights : planifica
    Movies ||--o{ MovieNights : "se ve en"
    Recipes ||--o{ MovieNights : "se cocina en"

    Movies { int MovieId PK
            nvarchar Title
            smallint ReleaseYear
            tinyint MinAge
            vector384 Embedding }
    Recipes { int RecipeId PK
            nvarchar Name
            tinyint Difficulty
            vector384 Embedding }
    Users { int UserId PK
            nvarchar Email
            date BirthDate }
    MovieNights { int NightId PK
            int UserId FK
            int MovieId FK
            int RecipeId FK
            tinyint Rating }
```

## Resumen de tablas

| Tabla | Tipo | Notas |
|---|---|---|
| Movies, Recipes | Entidad | Incluyen `Embedding VECTOR(384)` (se rellena en la Fase 5) |
| Genres, Ingredients, Allergens | Catálogo | Nombre único |
| MovieGenres, RecipeIngredients, IngredientAllergens | Puente N:M | Clave primaria compuesta |
| Users, UserAllergies | Datos sensibles | Masking de email y fecha de nacimiento; RLS en alergias |
| MovieNights | Historial | Une usuario, película y receta |
