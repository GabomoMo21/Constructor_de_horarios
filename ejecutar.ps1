param(
    [string]$Preferencias = "datos/entrada/preferencias.csv",
    [string]$Politica = "etapa3_prolog/politica.pl"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# Agrega las rutas habituales de Racket y Prolog
$carpetas = @("$env:ProgramFiles\Racket", "$env:ProgramFiles\swipl\bin")
foreach ($carpeta in $carpetas) {
    if ((Test-Path $carpeta) -and (($env:Path -split ';') -notcontains $carpeta)) {
        $env:Path += ";$carpeta"
    }
}

try {
    foreach ($programa in @("gcc", "racket", "swipl")) {
        if (-not (Get-Command $programa -ErrorAction SilentlyContinue)) {
            throw "No se encontro $programa"
        }
    }
    if (-not (Test-Path $Preferencias)) { throw "No se encontro $Preferencias" }
    if (-not (Test-Path $Politica)) { throw "No se encontro $Politica" }

    New-Item -ItemType Directory -Force -Path "datos/salida" | Out-Null

    $archivosC = @(
        "etapa1_c/main.c", "etapa1_c/catalogo.c",
        "etapa1_c/lector_horarios.c", "etapa1_c/historial.c",
        "etapa1_c/requisitos.c", "etapa1_c/choques.c",
        "etapa1_c/ciclos.c", "etapa1_c/exportador.c"
    )

    Write-Host "`nEtapa 1: C"
    & gcc -std=c11 -Wall -Wextra -Wpedantic @archivosC -o cemestre.exe
    if ($LASTEXITCODE -ne 0) { throw "Error al compilar C" }
    & .\cemestre.exe
    if ($LASTEXITCODE -ne 0) { throw "Error al ejecutar C" }

    Write-Host "`nEtapa 2: Racket"
    & racket "etapa2_racket/main.rkt" `
        "datos/salida/catalogo_procesado.csv" `
        $Preferencias `
        "datos/salida/combinaciones.json"
    if ($LASTEXITCODE -ne 0) { throw "Error al ejecutar Racket" }

    Write-Host "`nEtapa 3: Prolog"
    & swipl -q -s "etapa3_prolog/main.pl" -- `
        "datos/salida/combinaciones.json" `
        $Politica `
        "datos/salida/resultados.json"
    if ($LASTEXITCODE -ne 0) { throw "Error al ejecutar Prolog" }

    $datos = Get-Content "datos/salida/resultados.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    $resultados = @($datos.resultados)
    $aceptadas = @($resultados | Where-Object { $_.cumple -eq $true }).Count
    $rechazadas = @($resultados | Where-Object { $_.cumple -eq $false }).Count

    Write-Host "`nCombinaciones evaluadas: $($resultados.Count)"
    Write-Host "Aceptadas: $aceptadas  Rechazadas: $rechazadas"
    Write-Host "`nResultados:"
    $filas = foreach ($r in $resultados) {
        $regla = if ($null -eq $r.razon) { "-" } else { $r.razon.regla }
        $baja = if ($null -eq $r.curso_a_quitar) {
            "-"
        } else {
            "$($r.curso_a_quitar.codigo) G$($r.curso_a_quitar.grupo) ($($r.curso_a_quitar.carrera))"
        }
        [pscustomobject]@{
            Id = $r.id
            Creditos = $r.creditos_totales
            Cumple = $r.cumple
            Regla = $regla
            CursoAQuitar = $baja
        }
    }
    $filas | Format-Table -AutoSize -Wrap
    Write-Host "Archivo final: datos/salida/resultados.json"
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
