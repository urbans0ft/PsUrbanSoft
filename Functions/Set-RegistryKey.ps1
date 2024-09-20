<#
.SYNOPSIS
Adds a new subkey or entry to the registry.
.DESCRIPTION
Adds a new subkey or entry to the registry.
.PARAMETER KeyName
[\\Machine\]FullKey
Machine  Name of remote machine - omitting defaults to the
         current machine. Only HKLM and HKU are available on remote
         machines.
FullKey  ROOTKEY\SubKey
ROOTKEY  [ HKLM | HKCU | HKCR | HKU | HKCC ]
SubKey   The full name of a registry key under the selected ROOTKEY.
.PARAMETER Name
The value name, under the selected Key, to add. If not set an empty value name (Default) for the key is added.
.PARAMETER Type
RegKey data types. If omitted, REG_SZ is assumed.
.PARAMETER Data
The data to assign to the registry ValueName being added.
.PARAMETER Separator
Specify one character that you use as the separator in your data
string (only available for REG_MULTI_SZ). If omitted, use "\0" as the separator.
.PARAMETER Force
Force overwriting the existing registry entry without prompt.
.EXAMPLE
Set-RegistryKey "HKCU\KeyOnly"
Creates a new Key 'KeyOnly' without any data.
.EXAMPLE
Set-RegistryKey "HKCU\NewKey" -Data "Default Data"
Creates a new Key 'KeyOnly' with the default data set to "Default Data".
.EXAMPLE
Set-RegistryKey "HKCU\NewKey" -Name "MyValue" -Data "MyData"
Create a new Key 'KeyOnly' with a property 'MyValue' set to 'MyData'
.EXAMPLE
Set-RegistryKey "HKCU\NewKey" -Name "MyUsername" -Data "%username%" -Type REG_EXPAND_SZ
PS > (Get-ItemProperty -Path HKCU:\NewKey).MyUsername
WDAGUtilityAccount
.EXAMPLE
Set-RegistryKey "HKCU\NewKey" -Name "MyValues" -Data "1,2,3,4" -Type REG_MULTI_SZ  -Separator ','
Set a new Key with a REG_MULTI_SZ property 'MyValues' set to '1', '2', '3' and '4'.
.EXAMPLE
Set-RegistryKey "HKCU\NewKey" -Name "MyValues" -Data "1,2,3,4,5" -Type REG_MULTI_SZ  -Separator ',' -Force
Creates the key-value even if it already exists (see previous example).
.NOTES
Wrapper around the `reg add` command.
.LINK
PS > reg add /?
#>
function Set-RegistryKey {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'KeyOnly')]
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'WithData')]
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'WithName')]
        [string]$KeyName,
        [Parameter(Mandatory, ParameterSetName = 'WithName')]
        [string]$Name,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('REG_SZ', 'REG_MULTI_SZ', 'REG_EXPAND_SZ', 'REG_DWORD', 'REG_QWORD', 'REG_BINARY', 'REG_NONE' )]
        [string]$Type = 'REG_SZ',
        [Parameter(Mandatory, ParameterSetName = 'WithData', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'WithName', ValueFromPipelineByPropertyName)]
        [string]$Data,
        [switch]$Force
    )
    dynamicparam {
        # [Parameter(Mandatory)][Char]]$Separator = "`0" # if $Type -eq 'REG_MULTI_SZ'
        if ($Type -eq 'REG_MULTI_SZ') {
            $parameterAttribute = [System.Management.Automation.ParameterAttribute]@{
                Mandatory = $true
            }
            $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
            $attributeCollection.Add($parameterAttribute)
            $dynParam1 = [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Separator', [char], $attributeCollection
            )
            $dynParam1.Value = "`0"
            $dynParam1.IsSet = $true
            $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
            $paramDictionary.Add('Separator', $dynParam1)
            return $paramDictionary
        }
    }
    
    process {
        $regParam = @('add', $KeyName)
        if ($PSBoundParameters.ContainsKey('Name')) {
            $regParam += "/v", $Name
        }
        else {
            if ($PsCmdlet.ParameterSetName -ne 'KeyOnly') {
                $regParam += '/ve'
            }
        }
        if ($PsCmdlet.ParameterSetName -ne 'KeyOnly') {
            $regParam += "/t", $Type
        }
        if ($PsCmdlet.ParameterSetName -ne 'KeyOnly') {
            $regParam += "/d", $Data
        }
        if ($PSBoundParameters.ContainsKey('Separator')) {
            $regParam += "/s", $($PSCmdlet.MyInvocation.BoundParameters['Separator'])
        }
        if ($Force) {
            $regParam += "/f"
        }
        
        if ($PSCmdlet.ShouldProcess("registry", "reg $($regParam -join ' ')")) {
            reg $regParam
            if ($LASTEXITCODE -ne 0) {
                Write-Error "REG ADD failed."
            }
        }
    }
}

function Test-NameFromPipeline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'WithName')]
        [string]$KeyName,
        [Parameter(ValueFromPipelineByPropertyName)]
        $Type,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $Data
    )
    process {
        Write-Host "Huhu $_"
    }
}