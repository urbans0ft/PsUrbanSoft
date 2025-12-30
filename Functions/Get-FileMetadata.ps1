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
        [string]$Path,
        [Parameter()]
        [object[]]$Property
    )
    begin {
        $inputObjects = @()
        $shell = New-Object -ComObject Shell.Application
    }
    process {
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-Error "The specified path '$Path' does not exist or is not a file."
            return
        }
        $inputObjects += Get-Item $Path
    }
    end {
        # create a distinct list of folders to optimize Shell COM calls
        $folderList = 
        $inputObjects |
        ForEach-Object { $_.Directory.FullName } |
        Group-Object -NoElement |
        Select-Object -ExpandProperty Name |
        Sort-Object Name
        
        # build a folder detail dictionary
        $folderDetailDict = @{}
        $folderList |
        ForEach-Object {
            $dirPath = $_
            $folder = $shell.NameSpace($dirPath)
            $propTable = @{}
            0..400 | ForEach-Object {
                $idx = $_
                $name = $folder.GetDetailsOf($null, $idx)
                if ($name) { $propTable[$idx] = $name }
            }
            $folderDetailDict[$dirPath] = [PSCustomObject]@{
                folder     = $folder
                properties = $propTable
            }
        }

        # iterate over input files and get metadata
        $inputObjects | Select-Object -First 2 |
        ForEach-Object {
            $file         = $_
            $folderPath   = $file.Directory.FullName
            $detailHelper = $folderDetailDict[$folderPath]
            $folder       = $detailHelper.folder          # get folder com object
            $item         = $folder.ParseName($file.Name) # get folder item com object
            $propTable    = $detailHelper.properties

            # for each property, get the value
            $propertyList = 
            $propTable.GetEnumerator() |
            ForEach-Object {
                $idx  = $_.Key
                $name = $_.Value

                $value = $folder.GetDetailsOf($item, $idx)
                if (-not [string]::IsNullOrWhiteSpace($value))
                {
                    [PSCustomObject]@{
                        Index = $idx
                        Name  = $name
                        Value = $value
                    }
                }
            }
            Write-Output $propertyList -NoEnumerate
        }
    
    }
}


