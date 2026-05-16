# Starship prompt
Invoke-Expression (&starship init powershell)

# History suggestions
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History

$Env:KOMOREBI_CONFIG_HOME = 'C:\Users\malth\.config\komorebi'

Set-Alias -Name esp -Value C:\esp\v5.4\esp-idf\export.ps1
$env:IDF_PATH = 'C:\esp\v5.4\esp-idf'