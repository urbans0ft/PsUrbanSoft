function Get-UserInput {
    <#
    .SYNOPSIS
    Get user input
    
    .DESCRIPTION
    Ask the user to provide input via a text box.
    
    .PARAMETER Title
    The title of the text box.
    
    .PARAMETER Description
    The description eplaining the user what information to provide.
    
    .PARAMETER Default
    The default text within the text box.
    
    .EXAMPLE
    Get-UserInput "Hallo" "Wie ist dein Name?" "Unbekannt"
    
    .NOTES
    The cmdlet is merely a wrapper around the [Microsoft.VisualBasic.Interaction]::InputBox.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory,Position=0)]
        [string]$Title,
        [Parameter(Mandatory,Position=1)]
        [string]$Description,
        [Parameter(Position=2)]
        [string]$Default = ""
    )
    Add-Type -AssemblyName Microsoft.VisualBasic
    [Microsoft.VisualBasic.Interaction]::InputBox($Description, $Title, $Default)
}