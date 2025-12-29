function Get-FileMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Path
    )
    begin {
        $inputObjects = @()
        $shell  = New-Object -ComObject Shell.Application
    }
    process {
        if (-not (Test-Path -Path $Path)) {
            Write-Error "The specified path '$Path' does not exist."
            return
        }
        $inputObjects += Get-Item $Path
    }
    end {
        $inputObjects | ForEach-Object {
            $file = $_

            # Get folder and file via Shell COM
            $folder = $shell.NameSpace($file.Directory.FullName)
            $item   = $folder.ParseName($file.Name)
    
            # Build a list of "Details" columns (index + name + value)
            $props = 0..400 | ForEach-Object {
                $name = $folder.GetDetailsOf($null, $_)
                if ($name) {
                    [PSCustomObject]@{
                        Index = $_
                        Name  = $name
                        Value = $folder.GetDetailsOf($item, $_)
                    }
                }
            }
    
            $props | Where-Object Value | Sort-Object Index
        }
    }
}


