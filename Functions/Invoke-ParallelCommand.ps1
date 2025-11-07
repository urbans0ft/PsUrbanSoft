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

    .EXAMPLE
        [PSCustomObject]@{Command = 'ffmpeg'; ArgumentList = @('-i', 'audio.m4a', '-vn', '-filter:a', 'loudnorm=I=-24:LRA=7:TP=-2:dual_mono=false:print_format=json', '-f', 'null', '-') } | Invoke-ParallelCommand

    #>
    [CmdletBinding(DefaultParameterSetName = 'CommandByParameter')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'CommandByParameter')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, ParameterSetName = 'CommandByPipeline')]
        [string]$Command,
        
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, DontShow = $true, ParameterSetName = 'CommandByParameter')]
        [string[]]$PipelineArguments,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'CommandByParameter')]
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'CommandByPipeline')]
        [string[]]$ArgumentList
    )

    begin {

        if ($PSBoundParameters.ContainsKey("PipelineArguments")) {
            throw "PipelineArguments can only be provided via pipeline input."
        }

        Write-Host "`nBeginning pipeline processing..." -ForegroundColor Cyan
        Write-Host "`$PSCmdlet.ParameterSetName                          = '$($PSCmdlet.ParameterSetName)'" -ForegroundColor Magenta
        Write-Host "`$PSBoundParameters.ContainsKey('Command')           = '$($PSBoundParameters.ContainsKey("Command"))'" -ForegroundColor Magenta
        Write-Host "`$PSBoundParameters.ContainsKey('PipelineArguments') = '$($PSBoundParameters.ContainsKey("PipelineArguments"))'" -ForegroundColor Magenta
        Write-Host "`$PSBoundParameters.ContainsKey('ArgumentList')      = '$($PSBoundParameters.ContainsKey("ArgumentList"))'" -ForegroundColor Magenta
        [Collections.ArrayList]$argumentLists = @()

    }
    
    process {

        Write-Host "`nProcessing pipeline item..." -ForegroundColor Cyan
        Write-Host "`$Command                                = '$Command'" -ForegroundColor Yellow
        Write-Host "`$PipelineArguments                      = '$PipelineArguments'" -ForegroundColor Yellow
        Write-Host "`$ArgumentList                           = '$ArgumentList'" -ForegroundColor Yellow
        Write-Host "`$Command.GetType()                      = '$($Command.GetType())'" -ForegroundColor Yellow
        Write-Host "`$PipelineArguments.GetType()            = '$($PipelineArguments.GetType())'" -ForegroundColor Yellow
        Write-Host "`$ArgumentList.GetType()                 = '$($ArgumentList.GetType())'" -ForegroundColor Yellow
        Write-Host "`$Command           -is [PSCustomObject]   '$($Command -is [PSCustomObject])'" -ForegroundColor Yellow
        Write-Host "`$PipelineArguments -is [PSCustomObject]   '$($PipelineArguments -is [PSCustomObject])'" -ForegroundColor Yellow
        Write-Host "`$ArgumentList      -is [PSCustomObject]   '$($ArgumentList -is [PSCustomObject])'" -ForegroundColor Yellow

        [void]$argumentLists.Add($PipelineArguments)

    }

    end {

        # Pipeline input: combine each pipeline item with ArgumentList
        $argumentLists | ForEach-Object {
            $pipelineArgs = $_
            $combinedArgs = $pipelineArgs + $ArgumentList
            Write-Host "& $Command $combinedArgs" -ForegroundColor Green

            # & $Command $combinedArgs
        }

    }

}
