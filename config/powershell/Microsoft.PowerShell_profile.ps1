$profileErrorCount = $Error.Count

# History suggestions
Import-Module PSReadLine -ErrorAction SilentlyContinue

$isInteractiveConsole = [Environment]::UserInteractive -and -not [Console]::IsOutputRedirected

if ($isInteractiveConsole -and $env:WT_SESSION) {
    $escape = [char]27
    Write-Host -NoNewline "$escape[?12l$escape[2 q"
}

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

if (Get-Command bat -ErrorAction SilentlyContinue) {
    Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue

    function global:cat {
        bat @args
    }
}

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    function global:n {
        if ($args.Count -eq 0) {
            nvim .
            return
        }

        nvim @args
    }
}

Remove-Item Alias:cp, Alias:mv, Alias:rm, Alias:mkdir -Force -ErrorAction SilentlyContinue

function global:cp {
    Copy-Item @args
}

function global:mv {
    Move-Item @args
}

function global:rm {
    Remove-Item @args
}

function global:mkdir {
    New-Item -ItemType Directory @args
}

function global:touch {
    foreach ($path in $args) {
        if (Test-Path -LiteralPath $path) {
            (Get-Item -LiteralPath $path).LastWriteTime = Get-Date
            continue
        }

        New-Item -ItemType File -Path $path | Out-Null
    }
}

Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })

Set-Alias -Name esp -Value C:\esp\v5.4\esp-idf\export.ps1
$env:IDF_PATH = 'C:\esp\v5.4\esp-idf'

if ($isInteractiveConsole -and $Error.Count -eq $profileErrorCount) {
    Clear-Host
}
