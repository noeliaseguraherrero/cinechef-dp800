# Seguridad de CineChef (Bloque C)

Mecanismos implementados en `database/09_security.sql` y verificados en `tests/phase4_security_tests.sql`:

1. **Roles y mínimo privilegio** (`GRANT`, `DENY`, `REVOKE`).
2. **Row-Level Security** sobre `Users`, `UserAllergies` y `MovieNights`.
3. **Dynamic Data Masking** sobre `Users.Email` y `Users.BirthDate`.
4. **Escalada controlada** con `EXECUTE AS OWNER` (`usp_GenreRatingStats`).
5. Complementos: control de identidad en los procedimientos y auditoría de valoraciones (trigger).

## Principales de demostración
Se crean `WITHOUT LOGIN`: no hay contraseñas ni secretos en el repositorio. En un sistema real se asociarían
a inicios de sesión de la aplicación o de Active Directory.

| Usuario | Rol | Representa |
|---|---|---|
| `cc_isaac` | role_customer | Isaac Brown (alergia al gluten y a la leche) |
| `cc_alice` | role_customer | Alice Carter (sin alergias) |
| `cc_kid` | role_customer | El usuario más joven (control parental) |
| `cc_nutri` | role_nutritionist | Consulta alergias de todos |
| `cc_analyst` | role_analyst | Estadísticas y catálogo |
| `dbo` | administrador | Acceso completo |

La tabla `dbo.UserPrincipals` asocia cada usuario de base de datos con su fila en `Users`.

## Matriz de acceso

| Objeto | Cliente | Nutricionista | Analista | Administrador |
|---|---|---|---|---|
| Catálogo (películas, recetas, ingredientes, alérgenos) | Lectura | Lectura | Lectura | Todo |
| `Users` | Solo su fila, sin máscara | Todas las filas, **enmascarado** | Denegado | Todo |
| `UserAllergies` | Solo las suyas | Todas | Denegado | Todo |
| `MovieNights` | Solo los suyos (lectura) | Denegado | Denegado | Todo |
| Registrar / valorar planes | Solo mediante procedimientos, y solo los suyos | No | No | Sí |
| Estadísticas por género | No | No | `usp_GenreRatingStats` | Sí |
| `UserPrincipals`, `MovieNightRatingAudit` | Denegado | Denegado | Denegado | Todo |

## Decisiones de diseño
- **RLS con `SCHEMABINDING`:** las funciones de predicado están enlazadas al esquema, de modo que los usuarios no
  necesitan permisos sobre `UserPrincipals` (Microsoft Learn: solo se exigen si la política se crea con `SCHEMABINDING = OFF`).
- **Bloqueo, no solo filtro:** en `MovieNights` hay predicados `BLOCK` tras `INSERT` y `UPDATE`, para que nadie escriba filas de otra persona.
- **Encadenamiento de propiedad:** los clientes tienen `DENY INSERT/UPDATE/DELETE` sobre las tablas, pero los procedimientos
  (mismo propietario, `dbo`) pueden escribir. RLS sigue aplicándose dentro de los procedimientos porque no se salta con el encadenamiento.
- **Identidad:** los procedimientos aceptan `@UserId`, pero lo rechazan (error 50030) si no coincide con `USER_NAME()` mapeado en
  `UserPrincipals`. Resuelve el hallazgo 4 de la revisión B-06.
- **Fallo cerrado de las funciones:** `fn_SafeRecipes` comprueba que el usuario exista en `Users`. Como RLS oculta a un cliente las filas
  de otras personas, pedir las recetas seguras de otra persona devuelve 0 filas. Resuelve el hallazgo 5 (RLS y `UserAllergies`).
- **Escalada controlada:** el analista no puede leer `MovieNights`, pero `usp_GenreRatingStats` se ejecuta como propietario y devuelve solo agregados, y solo de géneros con al menos 3 valoraciones (revisión B-08: con una sola, la media sería la valoración de una persona).

## Limitaciones asumidas
- **El enmascarado no es control de acceso.** Un rol con `SELECT` sobre la columna puede *filtrar* por el valor real
  (`WHERE BirthDate < '1990-01-01'`) y deducirlo. La prueba lo demuestra con `cc_nutri`. Mitigación posible: no conceder `SELECT` sobre esas columnas a quien no las necesite.
- **Estadísticas agregadas:** el umbral mínimo de grupo reduce la reidentificación, pero comparar géneros que comparten películas todavía permite inferencias por diferencia. La defensa completa (ruido, privacidad diferencial) queda fuera de alcance.
- **Usuarios sin inicio de sesión:** válidos para la demostración; en producción cada persona usaría un inicio de sesión propio o la aplicación establecería la identidad con `SESSION_CONTEXT`.
- **Auditoría con doble atribución:** `MovieNightRatingAudit` guarda `ChangedBy` (`USER_NAME()`, quien actúa) y `ConnectedAs` (`ORIGINAL_LOGIN()`). Con solo el segundo, la demo atribuía los cambios de `cc_alice` a `sa`. Si la aplicación usara un único usuario compartido, haría falta `SESSION_CONTEXT`.
- **Sin SQL Server Audit:** solo se audita el cambio de valoraciones (trigger). Una auditoría completa requeriría un objeto de auditoría a nivel de servidor.
- **Edad con la fecha enmascarada:** `security_demo.sql` (sección E) muestra qué edad ve el nutricionista en `vw_UserProfile`; documentar lo observado.
- El mapeo depende del nombre del principal (`USER_NAME()`); si se renombra un usuario de base de datos, hay que actualizar `UserPrincipals`.
