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
    Write-Host 'Teste visual do reporter: F3 troca rua, campo e cidade a noite.'
    Write-Host 'Este modo abre sem Ollama e sem voz.'
    & $godotExe --path $PSScriptRoot -- --preview-reporter
    exit $LASTEXITCODE
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
