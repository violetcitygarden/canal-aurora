$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
try {
    $pathFile = Join-Path $PSScriptRoot 'godot-path.txt'
    if (-not (Test-Path -LiteralPath $pathFile)) {
        throw 'Crie godot-path.txt nesta pasta com o caminho completo do executavel do Godot.'
    }
    $godotExe = (Get-Content -Raw -LiteralPath $pathFile).Trim().Trim('"')
    if (-not (Test-Path -LiteralPath $godotExe -PathType Leaf)) {
        throw 'Godot nao encontrado. Confira o caminho em godot-path.txt.'
    }
    $voicePython = Join-Path $PSScriptRoot '.venv-voice\Scripts\python.exe'
    if (-not (Test-Path -LiteralPath $voicePython -PathType Leaf)) {
        throw 'Ambiente de voz ausente: .venv-voice/Scripts/python.exe. Use o mesmo ambiente Piper do canal.'
    }
    Write-Host 'Preparando voz Jeff. Na primeira abertura, pode ser necessario baixar o modelo.'
    & $voicePython (Join-Path $PSScriptRoot 'voice_samples\prepare_reporter.py')
    if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel preparar Jeff. Veja o erro acima.' }
    Write-Host 'F3 troca cenario e fala. E repete a fala. V silencia a voz.'
    Write-Host 'Falas de teste com Piper Jeff local, sem precisar do Ollama.'
    & $godotExe --path $PSScriptRoot -- --preview-reporter
    exit $LASTEXITCODE
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
