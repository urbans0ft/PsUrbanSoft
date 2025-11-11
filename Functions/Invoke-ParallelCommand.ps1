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

    .EXAMPLE
        [PSCustomObject]@{Command = 'ffmpeg'; ArgumentList = @('-i', 'audio.m4a', '-vn', '-filter:a', 'loudnorm=I=-24:LRA=7:TP=-2:dual_mono=false:print_format=json', '-f', 'null', '-') },
        [PSCustomObject]@{Command = 'ffmpeg'; ArgumentList = @('-i', 'audio.m4a', '-vn', '-filter:a', 'loudnorm=I=-24:LRA=7:TP=-2:dual_mono=false:print_format=json', '-f', 'null', '-') } |
        Invoke-ParallelCommand

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

        Write-Debug "`nBeginning pipeline processing..."
        Write-Debug "`$PSCmdlet.ParameterSetName                          = '$($PSCmdlet.ParameterSetName)'"
        Write-Debug "`$PSBoundParameters.ContainsKey('Command')           = '$($PSBoundParameters.ContainsKey("Command"))'"
        Write-Debug "`$PSBoundParameters.ContainsKey('PipelineArguments') = '$($PSBoundParameters.ContainsKey("PipelineArguments"))'"
        Write-Debug "`$PSBoundParameters.ContainsKey('ArgumentList')      = '$($PSBoundParameters.ContainsKey("ArgumentList"))'"
        [Collections.ArrayList]$commandList = @()

    }
    
    process {

        Write-Debug "`nProcessing pipeline item..."
        Write-Debug "`$Command                                = '$Command'"
        Write-Debug "`$PipelineArguments                      = '$PipelineArguments'"
        Write-Debug "`$ArgumentList                           = '$ArgumentList'"
        Write-Debug "`$Command.GetType()                      = '$($Command.GetType())'"
        Write-Debug "`$PipelineArguments.GetType()            = '$($PipelineArguments ? $PipelineArguments.GetType() : 'undefined')'"
        Write-Debug "`$ArgumentList.GetType()                 = '$($ArgumentList ? $ArgumentList.GetType() : 'undefined')'"
        Write-Debug "`$Command           -is [PSCustomObject]   '$($Command -is [PSCustomObject])'"
        Write-Debug "`$PipelineArguments -is [PSCustomObject]   '$($PipelineArguments -is [PSCustomObject])'"
        Write-Debug "`$ArgumentList      -is [PSCustomObject]   '$($ArgumentList -is [PSCustomObject])'"

        [void]$commandList.Add(
            [PSCustomObject]@{
                Command        = $Command
                ArgumentList   = $ArgumentList + $PipelineArguments
            }
        )

    }

    end {

        $totalJobCount = $commandList.Count

        $writeProgressHashtable = @{}
        0..($commandList.Count - 1) | ForEach-Object {
            $writeProgressHashtable[$_] = @{
                Activity         = "Activity"
                Status           = "Status: $($_)"
                Id               = $_
                CurrentOperation = "NotStarted" # https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.jobstate?view=powershellsdk-7.4.0
                ParentId         = $totalJobCount
                PercentComplete  = 0
            }
        }

        $jobs = 0..($commandList.Count - 1) | ForEach-Object -Parallel {
            $Index                        = $_
            $local:VerbosePreference      = $using:VerbosePreference
            $local:writeProgressHashtable = $using:writeProgressHashtable
            $local:commandList            = $using:commandList
            $command                      = $commandList[$Index].Command
            $argumentList                 = $commandList[$Index].ArgumentList
            $writeProgressHashtable[$Index].Activity         = "Executing $command"
            $writeProgressHashtable[$Index].Status           = "Processing item $($Index)"
            $writeProgressHashtable[$Index].CurrentOperation = "Running"
            $writeProgressHashtable[$Index].PercentComplete  = 50
            
            Write-Verbose "& $command $argumentList"
            $stdouterr       = & $command $argumentList 2>&1
            $exitCode        = $LASTEXITCODE
            $successful      = $exitCode -eq 0
            $stdout, $stderr = $stdouterr.Where({$_ -isnot [System.Management.Automation.ErrorRecord]}, 'Split')
            $stdout | ForEach-Object { Write-Host $_ }
            $stderr | ForEach-Object { Write-Error $_ }
            
            if (-not $successful) {
                $writeProgressHashtable[$Index].CurrentOperation = "Failed"
            }
            else {
                $writeProgressHashtable[$Index].CurrentOperation = "Completed"
            }
            
            $writeProgressHashtable[$Index].PercentComplete  = 100
            $writeProgressHashtable[$Index].Completed        = $true

            if (-not $successful) {
                throw "'$command' command no. $Index failed with exit code $exitCode."
            }

        } -AsJob

        while ($false -eq $jobs.Finished.WaitOne(250)) {
            $totalCompletedJobCount = $jobs.ChildJobs | Where-Object { $_.State -eq 'Completed' } | Measure-Object | Select-Object -ExpandProperty Count
            $percentComplete = [int](($totalCompletedJobCount * 100 / $totalJobCount))
            Write-Progress -Activity "Parent Activity" -Status "${totalCompletedJobCount} / ${totalJobCount} (${percentComplete}%)" -Id $totalJobCount -CurrentOperation "CurrentOperation" -ParentId -1 -PercentComplete $percentComplete
            $writeProgressHashtable.Keys | ForEach-Object {
                $progressSplat = $writeProgressHashtable[$_]
                if ($progressSplat.CurrentOperation -ne 'NotStarted') {
                    Write-Progress @progressSplat
                }
            }
        }

        $jobs
    }

}
