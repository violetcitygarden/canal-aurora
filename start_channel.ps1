$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
try {
    $null = Invoke-RestMethod 'http://127.0.0.1:11436/health' -TimeoutSec 2
} catch {
    $voicePython = Join-Path $PSScriptRoot '.venv-voice\Scripts\python.exe'
    $voiceScript = Join-Path $PSScriptRoot 'voice_samples\server.py'
    Start-Process -FilePath $voicePython -ArgumentList ('"' + $voiceScript + '"') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'voice_samples\server-output.log') -RedirectStandardError (Join-Path $PSScriptRoot 'voice_samples\server-error.log')
    $voiceReady = $false
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        Start-Sleep -Milliseconds 500
        try {
            $null = Invoke-RestMethod 'http://127.0.0.1:11436/health' -TimeoutSec 1
            $voiceReady = $true
            break
        } catch {}
    }
    if (-not $voiceReady) { throw 'Cadu nao iniciou. Veja voice_samples/server-error.log.' }
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
