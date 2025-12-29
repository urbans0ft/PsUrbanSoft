function Get-FileMetadata {
    <#
    .SYNOPSIS
    Retrieves detailed metadata properties for a file using the Shell.Application COM object.
    
    .DESCRIPTION
    Retrieves all available metadata properties for one or more files by querying the 
    Shell.Application COM object. This function can extract extended file properties 
    such as media information, document properties, and other metadata that may not 
    be available through standard PowerShell cmdlets.
    
    .PARAMETER Path
    The path to the file to retrieve metadata from. This parameter is mandatory and 
    accepts pipeline input.
    
    .OUTPUTS
    PSCustomObject[]
        Returns an array of custom objects, each containing:
        - Index: The property index number
        - Name: The property name
        - Value: The property value
        
        Only properties with values are returned, sorted by index.
    
    .EXAMPLE
    Get-FileMetadata -Path "C:\Music\song.mp3"
    
    Retrieves all metadata properties for the specified MP3 file, including ID3 tags 
    like artist, album, and duration.
    
    .EXAMPLE
    Get-ChildItem "C:\Videos" -Filter "*.mp4" | Get-FileMetadata
    
    Retrieves metadata for all MP4 files in the Videos folder using pipeline input.
    
    .EXAMPLE
    Get-FileMetadata "C:\Documents\report.docx" | Where-Object Name -eq "Author"
    
    Retrieves only the Author property from the specified document.
    
    .NOTES
    This function uses the Shell.Application COM object to access file properties.
    The number of available properties (indexed 0-400) may vary depending on the 
    file type and installed shell extensions.
    #>
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


