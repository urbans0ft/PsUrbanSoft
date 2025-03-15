# Load all module function (ps1-scripts) from the 'Functions' folder.
Get-ChildItem -Path (Join-Path $PSScriptRoot 'Functions') -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}