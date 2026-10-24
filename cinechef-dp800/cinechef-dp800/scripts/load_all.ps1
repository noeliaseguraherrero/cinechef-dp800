<#
  CineChef - Recrea la base de datos y carga todos los datos de prueba.
  Ejecuta los scripts en orden con sqlcmd y se detiene ante el primer error.

  Uso (desde la raíz del repositorio):
    .\scripts\load_all.ps1                              # autenticación de Windows, instancia local
    .\scripts\load_all.ps1 -Server "localhost\SQL2025"  # instancia con nombre
    .\scripts\load_all.ps1 -User sa                     # autenticación SQL (pide la contraseña)

  La contraseña NO se guarda en ningún archivo: se pide por pantalla y se pasa a sqlcmd
  mediante la variable de entorno SQLCMDPASSWORD solo durante la ejecución.

  Nota: este script NO crea el modelo de embeddings (carpeta ai/), que requiere la
  preparación manual de ONNX descrita en el README.
#>
param(
    [string]$Server = "localhost",
    [string]$User
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

$files = @(
    "database\01_create_database.sql",
    "database\02_create_tables.sql",
    "database\03a_lookups.sql",
    "database\03b_ingredients.sql",
    "database\03c_recipes.sql",
    "database\03c2_recipes.sql",
    "database\03c3_recipes.sql",
    "database\03c4_recipes.sql",
    "database\03d_movies.sql",
    "database\03d2_movies.sql",
    "database\03d3_movies.sql",
    "database\03d4_movies.sql",
    "database\03e_users_nights.sql",
    "tests\verify_counts.sql",
    "database\04_views.sql",
    "database\05_functions.sql",
    "tests\phase3_objects_tests.sql",
    "database\06_audit_trigger.sql",
    "database\07_procedures.sql",
    "tests\phase3b_tests.sql",
    "database\09_security.sql",
    "tests\phase4_security_tests.sql"
)

if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    throw "No se encuentra 'sqlcmd'. Instálalo (viene con SQL Server o como paquete independiente) y vuelve a intentarlo."
}

$auth = @("-E")
if ($User) {
    $secure = Read-Host "Contraseña de $User" -AsSecureString
    $bstr   = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $env:SQLCMDPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    $auth = @("-U", $User)
}

try {
    foreach ($f in $files) {
        Write-Host ">> $f" -ForegroundColor Cyan
        $path = Join-Path $root $f
        if (-not (Test-Path $path)) { throw "No existe el archivo: $f" }

        # El script 01 crea la base de datos; el resto se ejecuta dentro de CineChefDB
        $db = if ($f -like "*01_create_database*") { @() } else { @("-d", "CineChefDB") }

        & sqlcmd -S $Server @auth @db -C -b -f 65001 -i $path
        if ($LASTEXITCODE -ne 0) { throw "Error al ejecutar $f (código $LASTEXITCODE)" }
    }
    Write-Host "`nCarga completada y verificada." -ForegroundColor Green
}
finally {
    Remove-Item Env:\SQLCMDPASSWORD -ErrorAction SilentlyContinue
}
