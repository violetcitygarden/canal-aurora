param([switch]$Demo)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$godotPathFile = Join-Path $PSScriptRoot 'godot-path.txt'
if (-not (Test-Path -LiteralPath $godotPathFile)) { $godotPathFile = Join-Path (Split-Path $PSScriptRoot) 'godot-path.txt' }
if (-not (Test-Path -LiteralPath $godotPathFile)) { throw 'Crie godot-path.txt com o caminho completo do executavel Godot 4.4 ou superior.' }
$godotExe = (Get-Content -Raw -LiteralPath $godotPathFile).Trim().Trim('"')
if (-not (Test-Path -LiteralPath $godotExe)) { throw 'Caminho do Godot invalido.' }
Write-Host 'Importando recursos da pensao...'
& $godotExe --headless --path $PSScriptRoot --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Falha ao importar recursos do Godot.' }
$voicePython = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $voicePython)) {
    Write-Host 'Criando ambiente separado da pensao...'
    if (Get-Command py -ErrorAction SilentlyContinue) { & py -3 -m venv (Join-Path $PSScriptRoot '.venv') }
    elseif (Get-Command python -ErrorAction SilentlyContinue) { & python -m venv (Join-Path $PSScriptRoot '.venv') }
    else { throw 'Instale Python 3.10 ou superior antes de continuar.' }
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar o ambiente Python.' }
}
$requirements = Join-Path $PSScriptRoot 'requirements.txt'
$hash = (Get-FileHash -LiteralPath $requirements).Hash
$marker = Join-Path $PSScriptRoot '.venv\requirements-hash.txt'
if (-not (Test-Path -LiteralPath $marker) -or (Get-Content -Raw -LiteralPath $marker).Trim() -ne $hash) {
    & $voicePython -m pip install -r $requirements
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao instalar dependencias.' }
    Set-Content -LiteralPath $marker -Value $hash
}
if (-not $Demo) {
    try { $null = Invoke-RestMethod 'http://127.0.0.1:11434/api/tags' -TimeoutSec 2 }
    catch {
        $ollamaExe = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'
        if (Test-Path -LiteralPath $ollamaExe) { Start-Process -FilePath $ollamaExe -ArgumentList 'serve' -WindowStyle Hidden }
        else { Write-Host 'Ollama nao encontrado no caminho padrao. A abertura precisa do modelo configurado no config.json.' }
    }
}
$port = 0
foreach ($candidate in 11450..11460) {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $candidate)
    try { $listener.Server.ExclusiveAddressUse = $true; $listener.Start(); $port = $candidate }
    catch {} finally { $listener.Stop() }
    if ($port -ne 0) { break }
}
if ($port -eq 0) { throw 'Sem porta livre para a pensao.' }
$env:PENSAO_PORT = [string]$port
$cache = Join-Path $PSScriptRoot 'cache'
New-Item -ItemType Directory -Force -Path $cache | Out-Null
$arguments = '"' + (Join-Path $PSScriptRoot 'server.py') + '" --port ' + $port
if ($Demo) { $arguments += ' --demo' }
$service = Start-Process -FilePath $voicePython -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $cache "server-$port-output.log") -RedirectStandardError (Join-Path $cache "server-$port-error.log")
try {
    Write-Host 'Preparando servidor e vozes da pensao. Pode levar alguns minutos.'
    $ready = $false
    $lastProgress = ''
    for ($i=0; $i -lt 1200; $i++) {
        $service.Refresh()
        if ($service.HasExited) { throw "Servidor encerrou. Veja cache/server-$port-error.log." }
        try {
            $health = Invoke-RestMethod "http://127.0.0.1:$port/health" -TimeoutSec 1
            $progress = [string]$health.status
            if ($health.error) { $progress += ' - ' + $health.error }
            if ($progress -ne $lastProgress) { Write-Host $progress; $lastProgress = $progress }
            if ($health.ready -and $health.queued -gt 0) { $ready=$true; break }
        } catch {}
        Start-Sleep -Milliseconds 500
    }
    if (-not $ready) { throw "Primeira conversa nao ficou pronta em 10 minutos. Veja cache/server-$port-error.log." }
    & $godotExe --path $PSScriptRoot
} finally {
    $service.Refresh()
    if (-not $service.HasExited) { Stop-Process -Id $service.Id }
}
