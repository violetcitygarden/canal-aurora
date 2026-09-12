$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$voicePython = Join-Path $PSScriptRoot '.venv-voice\Scripts\python.exe'
$voiceScript = Join-Path $PSScriptRoot 'voice_samples\server.py'
Write-Host 'Conferindo o modelo Jeff...'
& $voicePython (Join-Path $PSScriptRoot 'voice_samples\prepare_reporter.py') --model-only
if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel preparar o modelo Jeff. Veja o erro acima.' }
$health = $null
try { $health = Invoke-RestMethod 'http://127.0.0.1:11436/health' -TimeoutSec 2 } catch {}
if ($health -and ($health.service -ne 'canal-aurora-voice' -or $health.version -ne 2)) {
    # Restart only this project's Python service, never an unrelated listener.
    $listeners = Get-NetTCPConnection -LocalPort 11436 -State Listen -ErrorAction Stop
    foreach ($listener in $listeners) {
        $voiceProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $($listener.OwningProcess)"
        if (-not $voiceProcess.CommandLine -or $voiceProcess.CommandLine.IndexOf($voiceScript, [StringComparison]::OrdinalIgnoreCase) -lt 0 -or $voiceProcess.Name -notmatch '^python(w)?\.exe$') {
            throw 'Existe outro servidor na porta 11436. Feche o servidor antigo do canal e tente novamente.'
        }
        Stop-Process -Id $voiceProcess.ProcessId -ErrorAction Stop
        Wait-Process -Id $voiceProcess.ProcessId -Timeout 10 -ErrorAction SilentlyContinue
    }
    $health = $null
}
if (-not $health) {
    Start-Process -FilePath $voicePython -ArgumentList ('"' + $voiceScript + '"') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'voice_samples\server-output.log') -RedirectStandardError (Join-Path $PSScriptRoot 'voice_samples\server-error.log')
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        Start-Sleep -Milliseconds 500
        try {
            $health = Invoke-RestMethod 'http://127.0.0.1:11436/health' -TimeoutSec 1
            if ($health.service -eq 'canal-aurora-voice' -and $health.version -eq 2) { break }
        } catch {}
    }
}
if (-not $health -or $health.version -ne 2 -or $health.voices -notcontains 'jeff') {
    throw 'Servidor de voz atualizado nao iniciou. Veja voice_samples/server-error.log.'
}
Write-Host 'Testando Jeff pelo servidor de voz...'
$probeBody = @{text='Teste de voz do reporter.'; voice='jeff'} | ConvertTo-Json
$probe = Invoke-RestMethod 'http://127.0.0.1:11436/synthesize' -Method Post -ContentType 'application/json' -Body $probeBody -TimeoutSec 90
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
