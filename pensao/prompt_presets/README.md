# Versões do diálogo

Cada JSON é uma cópia completa da configuração, incluindo nome do modelo e parâmetros. Os pesos do Qwen continuam no Ollama; não houve alteração nem treinamento do modelo.

- `01_coeso_original.json`: configuração preservada antes do experimento, com conversas cotidianas sem obrigação de fazer piadas.
- `02_humor_maximo.json`: experimento com punchline em toda fala, respostas ariscas e passivo-agressividade extrema. Apenas o campo `system` mudou.

Para trocar, feche a Pensão, copie o arquivo escolhido para `pensao/config.json`, substituindo o conteúdo, e abra `INICIAR-PENSAO.bat` novamente. O servidor lê a configuração ao iniciar; reiniciá-lo também descarta as conversas antigas que estavam na fila.

Para restaurar a versão original pelo PowerShell, a partir da pasta do repositório:

```powershell
Copy-Item pensao/prompt_presets/01_coeso_original.json pensao/config.json
```

Para retomar o exagero:

```powershell
Copy-Item pensao/prompt_presets/02_humor_maximo.json pensao/config.json
```
