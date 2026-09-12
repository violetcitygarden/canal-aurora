# Execute somente depois de encerrar o jogo. Nao fecha aplicativos automaticamente.
$ErrorActionPreference = 'Stop'
$model = 'llama3.2:1b-instruct-q4_K_M'
$base = 'http://127.0.0.1:11434'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$resultDir = Join-Path $PSScriptRoot "resultados-$stamp"
New-Item -ItemType Directory -Path $resultDir | Out-Null
Invoke-RestMethod "$base/api/version" | ConvertTo-Json | Set-Content "$resultDir/version.json"
nvidia-smi | Out-File "$resultDir/gpu-antes.txt"
Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory | ConvertTo-Json | Set-Content "$resultDir/ram-antes.json"
$results = @()
try {
    # Descarrega antes da primeira rodada para separar carregamento de inferencia.
    $unload = @{model=$model;keep_alive=0} | ConvertTo-Json
    Invoke-RestMethod "$base/api/generate" -Method Post -ContentType 'application/json' -Body $unload | Out-Null
    for ($i=0; $i -lt 4; $i++) {
        $body = @{
            model=$model
            stream=$false
            keep_alive='10m'
            prompt='Escreva um boletim de 180 palavras em portugues para uma emissora de uma cidade ficticia chamada Santa Irene. Noticie manutencao de uma ponte, horarios da biblioteca e previsao de tempo ameno. Use tom formal, cotidiano e sem introducoes sobre inteligencia artificial.'
            options=@{num_ctx=2048;num_predict=256;temperature=0;seed=42}
        } | ConvertTo-Json -Depth 5
        Write-Host "Rodada $i (0 = carregamento inicial; 1 a 3 = modelo carregado)..."
        $reply = Invoke-RestMethod "$base/api/generate" -Method Post -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 600
        $reply | ConvertTo-Json -Depth 12 | Set-Content -Encoding utf8 "$resultDir/rodada-$i.json"
        Invoke-RestMethod "$base/api/ps" | ConvertTo-Json -Depth 12 | Set-Content "$resultDir/alocacao-$i.json"
        $row = [pscustomobject]@{
            rodada=$i
            tokens=$reply.eval_count
            tokens_por_segundo=if($reply.eval_duration -gt 0){[math]::Round($reply.eval_count*1e9/$reply.eval_duration,2)}else{0}
            total_segundos=[math]::Round($reply.total_duration/1e9,3)
            carregamento_segundos=[math]::Round($reply.load_duration/1e9,3)
            processamento_prompt_segundos=[math]::Round($reply.prompt_eval_duration/1e9,3)
        }
        $results += $row
        $row | Format-List
    }
    $results | Export-Csv -NoTypeInformation -Encoding utf8 "$resultDir/resumo.csv"
    Write-Host "Media de geracao com modelo carregado: $(($results | Where-Object rodada -gt 0 | Measure-Object tokens_por_segundo -Average).Average) tokens/s"
    Write-Host "Resultados em $resultDir"
} finally {
    Invoke-RestMethod "$base/api/generate" -Method Post -ContentType 'application/json' -Body (@{model=$model;keep_alive=0} | ConvertTo-Json) | Out-Null
}
