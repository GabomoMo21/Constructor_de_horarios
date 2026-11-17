$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# Agrega las rutas habituales de Racket y Prolog
foreach ($carpeta in @("$env:ProgramFiles\Racket", "$env:ProgramFiles\swipl\bin")) {
    if ((Test-Path $carpeta) -and (($env:Path -split ';') -notcontains $carpeta)) {
        $env:Path += ";$carpeta"
    }
}

try {
    foreach ($programa in @("gcc", "racket", "raco", "swipl")) {
        if (-not (Get-Command $programa -ErrorAction SilentlyContinue)) {
            throw "No se encontro $programa"
        }
    }
    New-Item -ItemType Directory -Force -Path "datos/salida" | Out-Null

    Write-Host "`nPruebas de Prolog"
    & swipl -q `
        -s "etapa3_prolog/tests/test_reglas.pl" `
        -s "etapa3_prolog/tests/test_evaluador.pl" `
        -s "etapa3_prolog/tests/test_exportador.pl" `
        -s "etapa3_prolog/tests/test_integracion.pl" `
        -g run_tests -t halt
    if ($LASTEXITCODE -ne 0) { throw "Fallaron las pruebas de Prolog" }

    Write-Host "`nPruebas de Racket"
    Push-Location "etapa2_racket/tests"
    try {
        $archivos = @(Get-ChildItem -File -Filter "test_*.rkt" | Sort-Object Name)
        if ($archivos.Count -eq 0) { throw "No se encontraron pruebas de Racket" }
        foreach ($archivo in $archivos) {
            & raco test $archivo.Name
            if ($LASTEXITCODE -ne 0) { throw "Fallo $($archivo.Name)" }
        }
    }
    finally { Pop-Location }

    Write-Host "`nCasos de ejemplo de Prolog"
    & swipl -q -s "etapa3_prolog/main.pl" -- `
        "etapa3_prolog/tests/fixtures/combinaciones_ejemplo.json" `
        "etapa3_prolog/tests/fixtures/politica_ejemplo.pl" `
        "datos/salida/resultados_prueba.json"
    if ($LASTEXITCODE -ne 0) { throw "Fallo el ejemplo de Prolog" }

    $ejemplos = (Get-Content "datos/salida/resultados_prueba.json" -Raw -Encoding UTF8 | ConvertFrom-Json).resultados
    if (@($ejemplos).Count -ne 4) { throw "El ejemplo debe tener cuatro resultados" }
    if ($ejemplos[0].cumple -ne $true -or $ejemplos[0].creditos_totales -ne 7) {
        throw "Fallo el ejemplo 1"
    }
    if ($ejemplos[1].cumple -ne $false -or
        $ejemplos[1].razon.regla -ne "incompatibilidad" -or
        $ejemplos[1].curso_a_quitar.codigo -ne "MA0101") {
        throw "Fallo el ejemplo 2"
    }
    if ($ejemplos[2].cumple -ne $true -or $ejemplos[2].creditos_totales -ne 0) {
        throw "Fallo el ejemplo 3"
    }
    if ($ejemplos[3].cumple -ne $false -or
        $ejemplos[3].razon.regla -ne "incompatibilidad" -or
        $null -ne $ejemplos[3].curso_a_quitar) {
        throw "Fallo el ejemplo 4"
    }

    Write-Host "`nPruebas de rechazo y curso a quitar"
    & swipl -q -s "etapa3_prolog/main.pl" -- `
        "etapa3_prolog/tests/fixtures/combinaciones_politicas.json" `
        "etapa3_prolog/tests/fixtures/politica_ejemplo.pl" `
        "datos/salida/resultados_politicas.json"
    if ($LASTEXITCODE -ne 0) { throw "Fallo la prueba de politicas" }

    $casos = @((Get-Content "datos/salida/resultados_politicas.json" -Raw -Encoding UTF8 | ConvertFrom-Json).resultados)
    if ($casos.Count -ne 6) { throw "Se esperaban 6 combinaciones" }
    if ($casos[0].cumple -ne $true -or $null -ne $casos[0].razon) { throw "Fallo el caso aceptado" }
    if ($casos[1].razon.regla -ne "incompatibilidad") { throw "Fallo incompatibilidad" }
    if ($casos[2].razon.regla -ne "limite_area" -or $casos[2].razon.cantidad -ne 4) { throw "Fallo limite por area" }
    if ($casos[3].razon.regla -ne "balance") { throw "Fallo balance" }
    if ($null -ne $casos[4].curso_a_quitar) { throw "Se propuso una baja que no resuelve el rechazo" }

    $bajas = @($casos[1], $casos[2], $casos[3], $casos[5])
    foreach ($caso in $bajas) {
        if ($null -eq $caso.curso_a_quitar) { throw "Falta el curso a quitar del caso $($caso.id)" }
    }
    if ($casos[1].curso_a_quitar.codigo -ne "MA0101" -or
        $casos[1].curso_a_quitar.carrera -ne "Ingeniería en Computadores" -or
        $casos[2].curso_a_quitar.codigo -ne "MA1102" -or
        $casos[2].curso_a_quitar.carrera -ne "Ingeniería Ambiental" -or
        $casos[3].curso_a_quitar.codigo -ne "CE1101" -or
        $casos[5].curso_a_quitar.codigo -ne "CE1101") {
        throw "El curso a quitar no coincide con los casos esperados"
    }

    $filas = foreach ($caso in $casos) {
        $regla = if ($null -eq $caso.razon) { "-" } else { $caso.razon.regla }
        $baja = if ($null -eq $caso.curso_a_quitar) {
            "-"
        } else {
            "$($caso.curso_a_quitar.codigo) G$($caso.curso_a_quitar.grupo) ($($caso.curso_a_quitar.carrera))"
        }
        [pscustomobject]@{
            Id = $caso.id
            Cumple = $caso.cumple
            Regla = $regla
            CursoAQuitar = $baja
        }
    }
    $filas | Format-Table -AutoSize -Wrap

    Write-Host "`nPrueba de las tres etapas"
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\ejecutar.ps1" `
        -Preferencias "datos/entrada/preferencias_mixtas_ejemplo.csv"
    if ($LASTEXITCODE -ne 0) { throw "Fallo la ejecucion completa" }

    $entrada = Get-Content "datos/salida/combinaciones.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    $salida = Get-Content "datos/salida/resultados.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    $combinaciones = @($entrada.combinaciones)
    $resultados = @($salida.resultados)
    if ($combinaciones.Count -eq 0 -or $combinaciones.Count -ne $resultados.Count) {
        throw "No coincide la cantidad de combinaciones y resultados"
    }
    for ($i = 0; $i -lt $resultados.Count; $i++) {
        $r = $resultados[$i]
        if ($r.id -ne ($i + 1)) { throw "ID incorrecto" }
        if (@($r.selecciones).Count -ne @($combinaciones[$i].selecciones).Count) {
            throw "La combinacion $($r.id) cambio de cantidad de cursos"
        }
        $total = 0
        foreach ($curso in @($r.selecciones)) {
            $total += [int]$curso.creditos
        }
        if ($total -ne [int]$r.creditos_totales) {
            throw "Creditos incorrectos en la combinacion $($r.id)"
        }
        if ($r.cumple -eq $true -and
            ($null -ne $r.razon -or $null -ne $r.curso_a_quitar)) {
            throw "La combinacion $($r.id) aceptada tiene razon o curso a quitar"
        }
        if ($r.cumple -eq $false -and $null -eq $r.razon) {
            throw "La combinacion $($r.id) rechazada no tiene razon"
        }
    }

    Write-Host "`nPRUEBAS CORRECTAS" -ForegroundColor Green
    Write-Host "Ejemplos: datos/salida/resultados_politicas.json"
    Write-Host "Salida final: datos/salida/resultados.json"
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
