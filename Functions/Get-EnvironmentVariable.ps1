<#
.SYNOPSIS
Returns a hashtable of the environment variables.
.DESCRIPTION
Returns a hashtable of the environment variables by querying the registry.
.PARAMETER KeyName
[\\Machine\]FullKey
Machine - Name of remote machine, omitting defaults to the
        current machine. Only HKLM and HKU are available on
        remote machines
FullKey - in the form of ROOTKEY\SubKey name
    ROOTKEY - [ HKLM | HKCU | HKCR | HKU | HKCC ]
    SubKey  - The full name of a registry key under the
            selected ROOTKEY
.PARAMETER Target
One of [System.EnvironmentVariableTarget] enumeration.
.OUTPUTS
    Hashtable
        A hashtable where the keys are the ValueNames and the value is a PSCustomObject
        with the attributes 'Type' and 'Data' (see examples). For 'Target' Process the
        Type is always REG_NONE since no registry is polled.
.EXAMPLE
Get-EnvironmentVariable User

Name  Value
----  -----
TEMP  @{Type=REG_EXPAND_SZ; Data=%USERPROFILE%\AppData\Local\Temp}
Path  @{Type=REG_EXPAND_SZ; Data=%USERPROFILE%\AppData\Local\Mic…}
TMP   @{Type=REG_EXPAND_SZ; Data=%USERPROFILE%\AppData\Local\Temp}
.NOTES
Targets 'Machine' and 'User' do query the registry and ignore the current process environment.
.LINK
Get-RegistryKey
#>
function Get-EnvironmentVariable {
    [OutputType([Hashtable])]
    param(
        [Parameter(Mandatory)]
        [System.EnvironmentVariableTarget]$Target 
    )
    switch ($Target) {
        ([System.EnvironmentVariableTarget]::Process) {
            [System.Environment]::GetEnvironmentVariables($_).GetEnumerator() |
            ForEach-Object {
                # create a hashtable instead of an array of objects
                $registryKey[$_.Name] = [PSCustomObject]@{
                    'Type' = 'REG_NONE'
                    'Data' = $($_.Value)
                }
            } -Begin {
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope = "Variable", Target = "registryKey")]
                $registryKey = @{}
            } -End { $registryKey }
        }
        ([System.EnvironmentVariableTarget]::User) {
            Get-RegistryKey 'HKCU\Environment'
        }
        ([System.EnvironmentVariableTarget]::Machine) {
            Get-RegistryKey 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
        }
        default { throw "Target '$_' is not supported. " }
    }
    
}