$profileErrorCount = $Error.Count

# History suggestions
Import-Module PSReadLine -ErrorAction SilentlyContinue

$isInteractiveConsole = [Environment]::UserInteractive -and -not [Console]::IsOutputRedirected

if ($isInteractiveConsole -and (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue)) {
    $psReadLineOptions = (Get-Command Set-PSReadLineOption).Parameters

    if ($psReadLineOptions.ContainsKey('PredictionSource')) {
        Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
    }

    if ($psReadLineOptions.ContainsKey('PredictionViewStyle')) {
        Set-PSReadLineOption -PredictionViewStyle InlineView -ErrorAction SilentlyContinue
    }
}

if ($isInteractiveConsole -and (Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue)) {
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    try {
        Set-PSReadLineKeyHandler -Key RightArrow -Function AcceptNextSuggestionWord
        Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function AcceptSuggestion
    }
    catch {
        $Error.RemoveAt(0)
    }
}

# Starship prompt
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

$Env:KOMOREBI_CONFIG_HOME = 'C:\Users\malth\.config\komorebi'

if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue

    function global:ls {
        eza --group-directories-first --icons=auto @args
    }
}

Set-Alias -Name esp -Value C:\esp\v5.4\esp-idf\export.ps1
$env:IDF_PATH = 'C:\esp\v5.4\esp-idf'

if ($isInteractiveConsole -and $Error.Count -eq $profileErrorCount) {
    Clear-Host
}
