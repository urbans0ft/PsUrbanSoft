#Requires -Version 7.4

function Invoke-ParallelCommand {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .NOTES

    .LINK

    .EXAMPLE
        Invoke-ParallelCommand -Command 'ffmpeg' -ArgumentList @('-i', 'audio.m4a', '-vn', '-filter:a', 'loudnorm=I=-24:LRA=7:TP=-2:dual_mono=false:print_format=json', '-f', 'null', '-')
        
    .EXAMPLE
        , @('-i', 'audio.m4a', '-vn', '-filter:a', 'loudnorm=I=-24:LRA=7:TP=-2:dual_mono=false:print_format=json', '-f', 'null', '-') | Invoke-ParallelCommand -Command 'ffmpeg'
    
    .EXAMPLE
        @('-i', 'audio.m4a', '-vn', '-filter:a', 'loudnorm=I=-24:LRA=7:TP=-2:dual_mono=false:print_format=json', '-f', 'null', '-'), @('-i', 'audio.m4a', '-vn', '-filter:a', 'loudnorm=I=-24:LRA=7:TP=-2:dual_mono=false:print_format=json', '-f', 'null', '-') | Invoke-ParallelCommand -Command 'ffmpeg'

    .EXAMPLE
        @('-i', 'audio.m4a'), @('-i', 'audio.m4a') | Invoke-ParallelCommand -Command 'ffmpeg' -ArgumentList  '-vn', '-filter:a', 'loudnorm=I=-24:LRA=7:TP=-2:dual_mono=false:print_format=json', '-f', 'null', '-'

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Command,
        
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string[]]$PipelineArguments,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ArgumentList
    )

    begin {

        [Collections.ArrayList]$argumentLists = @()

    }
    
    process {

        [void]$argumentLists.Add($PipelineArguments)

    }

    end {

        # Pipeline input: combine each pipeline item with ArgumentList
        $argumentLists | ForEach-Object {
            $pipelineArgs = $_
            $combinedArgs = $pipelineArgs + $ArgumentList
            Write-Host "& $Command $combinedArgs" -ForegroundColor Green
            & $Command $combinedArgs
        }

    }

}
