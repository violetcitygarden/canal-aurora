$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$voicePython = Join-Path $PSScriptRoot '.venv-voice\Scripts\python.exe'
$voiceScript = Join-Path $PSScriptRoot 'voice_samples\server.py'
Write-Host 'Conferindo o modelo Jeff...'
& $voicePython (Join-Path $PSScriptRoot 'voice_samples\prepare_reporter.py') --model-only
if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel preparar o modelo Jeff. Veja o erro acima.' }
$health = $null
$voicePort = 0
foreach ($candidate in 11436..11446) {
    $candidateHealth = $null
    try { $candidateHealth = Invoke-RestMethod "http://127.0.0.1:$candidate/health" -TimeoutSec 1 } catch {}
    if ($candidateHealth.service -eq 'canal-aurora-voice' -and $candidateHealth.version -eq 2 -and $candidateHealth.voices -contains 'jeff') {
        $voicePort = $candidate
        $health = $candidateHealth
        break
    }
    # Reserve a loopback port briefly to check availability without inspecting or killing processes.
    $portCheck = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $candidate)
    try {
        $portCheck.Server.ExclusiveAddressUse = $true
        $portCheck.Start()
        $voicePort = $candidate
    } catch {
        Write-Host "Porta $candidate ocupada; tentando a proxima."
    } finally { $portCheck.Stop() }
    if ($voicePort -ne 0) { break }
}
if ($voicePort -eq 0) { throw 'Nenhuma porta livre para voz entre 11436 e 11446.' }
$voiceBase = "http://127.0.0.1:$voicePort"
if (-not $health) {
    $voiceArgs = '"' + $voiceScript + '" --port ' + $voicePort
    Start-Process -FilePath $voicePython -ArgumentList $voiceArgs -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot "voice_samples\server-$voicePort-output.log") -RedirectStandardError (Join-Path $PSScriptRoot "voice_samples\server-$voicePort-error.log")
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        Start-Sleep -Milliseconds 500
        try {
            $health = Invoke-RestMethod "$voiceBase/health" -TimeoutSec 1
            if ($health.service -eq 'canal-aurora-voice' -and $health.version -eq 2) { break }
        } catch {}
    }
}
if (-not $health -or $health.service -ne 'canal-aurora-voice' -or $health.version -ne 2 -or $health.voices -notcontains 'jeff') {
    throw "Servidor de voz nao iniciou. Veja voice_samples/server-$voicePort-error.log."
}
$env:AURORA_VOICE_PORT = [string]$voicePort
Write-Host "Servidor de voz: $voiceBase"
Write-Host 'Testando Jeff pelo servidor de voz...'
$probeBody = @{text='Teste de voz do reporter.'; voice='jeff'} | ConvertTo-Json
$probe = Invoke-RestMethod "$voiceBase/synthesize" -Method Post -ContentType 'application/json' -Body $probeBody -TimeoutSec 90
if ($probe.voice -ne 'jeff' -or -not $probe.wav -or $probe.duration -le 0) {
    throw 'Servidor nao devolveu audio valido do Jeff.'
}
try {
    $null = Invoke-RestMethod 'http://127.0.0.1:11434/api/tags' -TimeoutSec 2
} catch {
    $ollamaExe = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'
    Start-Process -FilePath $ollamaExe -ArgumentList 'serve' -WindowStyle Hidden
    Start-Sleep -Seconds 2
}
$godotExe = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'godot-path.txt')).Trim()
& $godotExe --path $PSScriptRoot
