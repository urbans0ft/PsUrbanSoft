function Show-MessageBox {
    <#
    .SYNOPSIS
    Show a dialog message box
    
    .DESCRIPTION
    Show a dialog message box with caption, title and buttons.
    
    .PARAMETER Message
    The main dialog message presented to the user.
    
    .PARAMETER Title
    The caption of the popup dialog.
    
    .PARAMETER Button
    The button(s) to use for the dialog box.
    
    .PARAMETER Icon
    The icon to use for the dialog box.
    
    .PARAMETER Modality
    The dialog box' modality.
    
    .PARAMETER Options
    Arbitrary options (see link).

    .OUTPUTS
    An integer for details please see link.
    
    .EXAMPLE
    Show-MessageBox "Do you like me?" "Hello" Questiong YesNo
    
    .NOTES
    This function uses P/Invoke and Add-Type to invoke the WinApi `MessageBox`
    function.

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-messagebox
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Message,
        [Parameter(Mandatory,Position=1)]
        [string]$Title,
        [Parameter(Position=2)]
        [ValidateSet("AbortRetryIgnore", "CancelTryContinue", "Help", "Ok", "OkCancel", "RetryCancel", "YesNo", "YesNoCancel")]
        $Button,
        [Parameter(Position=3)]
        [ValidateSet("Warning", "Information", "Question", "Error")]
        $Icon,
        [Parameter(Position=4)]
        [ValidateSet("System", "Task")]
        $Modality,
        [Parameter(Position=5)]
        [ValidateSet("DefaultDesktopOnly", "Right", "RtlReading", "SetForeground", "TopMost", "ServiceNotification")]
        [string[]]$Options
    )
    $signature = @"
[DllImport("user32.dll", SetLastError = true, CharSet= CharSet.Unicode)]
public static extern int MessageBox(IntPtr hWnd, String text, String caption, uint type);
"@
    $MessageBox = Add-Type -MemberDefinition $signature -Name "Win32MessageBox" -Namespace Win32Functions -PassThru
    [int]$type = 0
    switch ($Button) {
        AbortRetryIgnore  { $type = $type -bor 0x00000002L; Write-Verbose "AbotRetryIgnore" }
        CancelTryContinue { $type = $type -bor 0x00000006L; Write-Verbose "CancelTryContinue" }
        Help              { $type = $type -bor 0x00004000L; Write-Verbose "Help" }
        Ok                { $type = $type -bor 0x00000000L; Write-Verbose "Ok" }
        OkCancel          { $type = $type -bor 0x00000001L; Write-Verbose "OkCanel" }
        RetryCancel       { $type = $type -bor 0x00000005L; Write-Verbose "RetryCancel" }
        YesNo             { $type = $type -bor 0x00000004L; Write-Verbose "YesNo" }
        YesNoCancel       { $type = $type -bor 0x00000003L; Write-Verbose "YesNoCancel" }
    }
    switch ($Icon) {
        Warning     { $type = $type -bor 0x00000030L; Write-Verbose "Warning" }
        Information { $type = $type -bor 0x00000040L; Write-Verbose "Information" }
        Question    { $type = $type -bor 0x00000020L; Write-Verbose "Questiong" }
        Error       { $type = $type -bor 0x00000010L; Write-Verbose "Error" }
    }
    switch ($Modality) {
        System { $type = $type -bor 0x00001000L; Write-Verbose "System modality" }
        Task   { $type = $type -bor 0x00002000L; Write-Verbose "Task modality" }
    }

    foreach ($opt in $Options) {
        switch ($opt) {
            DefaultDesktopOnly  { $type = $type -bor 0x00020000L; Write-Verbose "DefaultDesktopOnly" }
            Right               { $type = $type -bor 0x00080000L; Write-Verbose "Right" }
            RtlReading          { $type = $type -bor 0x00100000L; Write-Verbose "RtlReading" }
            SetForeground       { $type = $type -bor 0x00010000L; Write-Verbose "SetForeground" }
            TopMost             { $type = $type -bor 0x00040000L; Write-Verbose "TopMost" }
            ServiceNotification { $type = $type -bor 0x00200000L; Write-Verbose "ServiceNotification" }

        }
    }

    Write-Verbose ("MessageBox type: '0x{0:X}'" -f $type)
    $MessageBox::MessageBox(0, $Message, $Title, $type)
}