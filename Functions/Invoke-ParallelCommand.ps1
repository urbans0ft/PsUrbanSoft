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

        Write-Verbose "`nBeginning pipeline processing..."
        Write-Verbose "`$PSCmdlet.ParameterSetName                          = '$($PSCmdlet.ParameterSetName)'"
        Write-Verbose "`$PSBoundParameters.ContainsKey('Command')           = '$($PSBoundParameters.ContainsKey("Command"))'"
        Write-Verbose "`$PSBoundParameters.ContainsKey('PipelineArguments') = '$($PSBoundParameters.ContainsKey("PipelineArguments"))'"
        Write-Verbose "`$PSBoundParameters.ContainsKey('ArgumentList')      = '$($PSBoundParameters.ContainsKey("ArgumentList"))'"
        [Collections.ArrayList]$commandList = @()

    }
    
    process {

        Write-Verbose "`nProcessing pipeline item..."
        Write-Verbose "`$Command                                = '$Command'"
        Write-Verbose "`$PipelineArguments                      = '$PipelineArguments'"
        Write-Verbose "`$ArgumentList                           = '$ArgumentList'"
        Write-Verbose "`$Command.GetType()                      = '$($Command.GetType())'"
        Write-Verbose "`$PipelineArguments.GetType()            = '$($PipelineArguments ? $PipelineArguments.GetType() : 'undefined')'"
        Write-Verbose "`$ArgumentList.GetType()                 = '$($ArgumentList ? $ArgumentList.GetType() : 'undefined')'"
        Write-Verbose "`$Command           -is [PSCustomObject]   '$($Command -is [PSCustomObject])'"
        Write-Verbose "`$PipelineArguments -is [PSCustomObject]   '$($PipelineArguments -is [PSCustomObject])'"
        Write-Verbose "`$ArgumentList      -is [PSCustomObject]   '$($ArgumentList -is [PSCustomObject])'"

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
            $local:writeProgressHashtable = $using:writeProgressHashtable
            $local:commandList            = $using:commandList
            $command                      = $commandList[$_].Command
            $argumentList                 = $commandList[$_].ArgumentList

            $writeProgressHashtable[$_].Activity         = "Executing $command"
            $writeProgressHashtable[$_].Status           = "Processing item $($_)"
            $writeProgressHashtable[$_].CurrentOperation = "Running"
            $writeProgressHashtable[$_].PercentComplete  = 50
            
            Write-Host "& $command $argumentList" -ForegroundColor Green
            $stdouterr       = & $command $argumentList 2>&1
            $successful      = $LASTEXITCODE -eq 0
            $stdout, $stderr = $stdouterr.Where({$_ -isnot [System.Management.Automation.ErrorRecord]}, 'Split')
            $stdout | ForEach-Object { $Host.UI.WriteLine($_) }
            #$stdout | Write-Information
            $thisJob.Error += $stderr
            #$stderr | Write-Error
            if (-not $successful) {
                $writeProgressHashtable[$_].CurrentOperation = "Failed"
            }
            else {
                $writeProgressHashtable[$_].CurrentOperation = "Completed"
            }
            
            $writeProgressHashtable[$_].PercentComplete  = 100
            $writeProgressHashtable[$_].Completed        = $true
            throw "test"

            "Hallo Welt!"
        } -AsJob

        # $jobs.ChildJobs | ForEach-Object {
        #    $job = $_
        #    Write-Host "Registering event for Job Id: $($job.Id)" -ForegroundColor Cyan
        #     Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        #         $totalCompletedJobCount = $jobs.ChildJobs | Where-Object { $_.State -eq 'Completed' } | Measure-Object | Select-Object -ExpandProperty Count
        #         $percentComplete = [int](($totalCompletedJobCount * 100 / $totalJobCount))
        #         Write-Progress -Activity "Parent Activity" -Status "${totalCompletedJobCount} / ${totalJobCount} (${percentComplete}%)" -Id 0 -CurrentOperation "CurrentOperation" -ParentId -1 -PercentComplete $percentComplete
        #         if ($Sender.State -eq 'Completed') {$EventSubscriber | Unregister-Event}
        #     }
        # }

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
