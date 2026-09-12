param([string]$TextPath, [string]$WavePath)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
$speaker = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
    $speaker.SelectVoice('Microsoft Maria Desktop')
    $speaker.Rate = -1
    $speaker.SetOutputToWaveFile($WavePath)
    $speaker.Speak([System.IO.File]::ReadAllText($TextPath, [System.Text.Encoding]::UTF8))
} finally { $speaker.Dispose() }
