<#
.SYNOPSIS
Returns a hashtable of the next tier of subkeys and entries that are located under a specified
subkey in the registry.
.DESCRIPTION
Returns a hashtable of the next tier of subkeys and entries that are located under a specified
subkey in the registry and does not expand REG_EXPAND_SZ values.
.PARAMETER KeyName
[\\Machine\]FullKey
Machine - Name of remote machine, omitting defaults to the
          current machine. Only HKLM and HKU are available on
          remote machines
FullKey - in the form of ROOTKEY\SubKey name
    ROOTKEY - [ HKLM | HKCU | HKCR | HKU | HKCC ]
    SubKey  - The full name of a registry key under the
              selected ROOTKEY
.PARAMETER ValueName
Queries for a specific registry key values (case-insensitive).
If omitted, all values for the key are queried.
.PARAMETER Type
Specifies registry value data type.
Valid types are:
    REG_SZ, REG_MULTI_SZ, REG_EXPAND_SZ,
    REG_DWORD, REG_QWORD, REG_BINARY, REG_NONE
Defaults to all types.
.PARAMETER Data
Specifies the case-insensitive data or pattern to search for. Default is "*".
.OUTPUTS
    Hashtable
        A hashtable where the keys are the ValueNames and the value is a PSCustomObject
        with the attributes 'Type' and 'Data' (see examples).
.EXAMPLE
Get-RegistryKey "HKCU\Environment"
Name  Value
----  -----
TEMP  @{Type=REG_EXPAND_SZ; Data=%USERPROFILE%\AppData\Local\Temp}
Path  @{Type=REG_EXPAND_SZ; Data=%USERPROFILE%\AppData\Local\Microsoft\WindowsApps}
TMP   @{Type=REG_EXPAND_SZ; Data=%USERPROFILE%\AppData\Local\Temp}
.EXAMPLE
Get-RegistryKey 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -ValueName Path
Name  Value
----  -----
Path  @{Type=REG_EXPAND_SZ; Data=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\;%SYSTEMROOT%\System32\OpenSSH\;C:\Program Files\PowerShell… 
.EXAMPLE
Get-RegistryKey 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Type REG_SZ -Data '*window*'
Name                           Value
----                           -----
POWERSHELL_DISTRIBUTION_CHANN… @{Type=REG_SZ; Data=MSI:Windows 10 Enterprise}
OS                             @{Type=REG_SZ; Data=Windows_NT}
DriverData                     @{Type=REG_SZ; Data=C:\Windows\System32\Drivers\DriverData}
.EXAMPLE
Get-RegistryKey 'HKEY_LOCAL_MACHINE\DOES\NOT\EXIST' -Type REG_SZ -Data '*window*'                                              
ERROR: The system was unable to find the specified registry key or value.
.NOTES
Wrapper around the req query command.
.LINK
reg query /?
.LINK
https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/reg-query
#>
function Get-RegistryKey
{
    [OutputType([Hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$KeyName,
        [string]$ValueName,
        [ValidateSet('REG_SZ', 'REG_MULTI_SZ', 'REG_EXPAND_SZ',
        'REG_DWORD', 'REG_QWORD', 'REG_BINARY', 'REG_NONE')]
        [string]$Type,
        [string]$Data
    )
    reg query $KeyName | # split the reg result up in name, type and data
    Select-String '^(?<Name>.*)(?<Type>REG_((NONE|BINARY|DWORD|QWORD)|((((MULTI|EXPAND)_)?SZ)))) +(?<Data>.*)$' |
    Select-Object -ExpandProperty Matches |
    ForEach-Object {
        [PSCustomObject]@{
            'Name' = $_.Groups['Name'].Value.Trim()
            'Type' = $_.Groups['Type'].Value
            'Data' = $_.Groups['Data'].Value
        }
    } |
    Where-Object {
        # filter the results if ValueName was set
        if ($PSBoundParameters.ContainsKey('ValueName')) {$_.Name -ilike $ValueName} else {$true}
    } |
    Where-Object {
        # filter the results if Type was set
        if ($PSBoundParameters.ContainsKey('Type')) {$_.Type -ieq $Type} else {$true}
    } |
    Where-Object {
        # filter the results if Data was set
        if ($PSBoundParameters.ContainsKey('Data')) {$_.Data -ilike $Data} else {$true}
    } |
    ForEach-Object {
        # create a hashtable instead of an array of objects
        $registryKey[$_.Name] = [PSCustomObject]@{
            'Type' = $($_.Type)
            'Data' = $($_.Data)
        }
    } -Begin {[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope = "Variable", Target = "registryKey")]$registryKey = @{}} -End {$registryKey}
}


