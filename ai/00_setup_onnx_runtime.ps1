<#
  CineChef - Fase 1: preparación de carpetas y permisos para ONNX local.
  Ejecutar en PowerShell COMO ADMINISTRADOR.

  Los binarios y el modelo NO se incluyen en el repositorio (ver .gitignore).
  Antes de ejecutar este script, descárgalos manualmente (ver README, sección Instalación):
    - onnxruntime.dll  (ONNX Runtime >= 1.19)  -> C:\onnx_runtime\
    - tokenizers_cpp.dll  (nombre EXACTO; renombrar si se descarga como *-release.dll) -> C:\onnx_runtime\
    - modelo all-MiniLM-L6-v2-onnx             -> C:\onnx_runtime\model\
#>
$Base  = "C:\onnx_runtime"
$Model = Join-Path $Base "model"

New-Item -ItemType Directory -Force -Path $Base, $Model | Out-Null

# Permisos de la cuenta del servicio Launchpad sobre la carpeta
$Acl  = Get-Acl -Path $Base
$Rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            'MSSQLLaunchpad', 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
$Acl.AddAccessRule($Rule)
Set-Acl -Path $Base -AclObject $Acl

Write-Host "Carpeta preparada en $Base. Comprueba que contiene:"
Write-Host "  onnxruntime.dll, tokenizers_cpp.dll y model\all-MiniLM-L6-v2-onnx\ (model.onnx + tokenizer.json)"
