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

        Write-Host "`nBeginning pipeline processing..." -ForegroundColor Cyan
        Write-Host "`$PSCmdlet.ParameterSetName                          = '$($PSCmdlet.ParameterSetName)'" -ForegroundColor Magenta
        Write-Host "`$PSBoundParameters.ContainsKey('Command')           = '$($PSBoundParameters.ContainsKey("Command"))'" -ForegroundColor Magenta
        Write-Host "`$PSBoundParameters.ContainsKey('PipelineArguments') = '$($PSBoundParameters.ContainsKey("PipelineArguments"))'" -ForegroundColor Magenta
        Write-Host "`$PSBoundParameters.ContainsKey('ArgumentList')      = '$($PSBoundParameters.ContainsKey("ArgumentList"))'" -ForegroundColor Magenta
        [Collections.ArrayList]$commandList = @()

    }
    
    process {

        Write-Host "`nProcessing pipeline item..." -ForegroundColor Cyan
        Write-Host "`$Command                                = '$Command'" -ForegroundColor Yellow
        Write-Host "`$PipelineArguments                      = '$PipelineArguments'" -ForegroundColor Yellow
        Write-Host "`$ArgumentList                           = '$ArgumentList'" -ForegroundColor Yellow
        Write-Host "`$Command.GetType()                      = '$($Command.GetType())'" -ForegroundColor Yellow
        Write-Host "`$PipelineArguments.GetType()            = '$($PipelineArguments ? $PipelineArguments.GetType() : 'undefined')'" -ForegroundColor Yellow
        Write-Host "`$ArgumentList.GetType()                 = '$($ArgumentList ? $ArgumentList.GetType() : 'undefined')'" -ForegroundColor Yellow
        Write-Host "`$Command           -is [PSCustomObject]   '$($Command -is [PSCustomObject])'" -ForegroundColor Yellow
        Write-Host "`$PipelineArguments -is [PSCustomObject]   '$($PipelineArguments -is [PSCustomObject])'" -ForegroundColor Yellow
        Write-Host "`$ArgumentList      -is [PSCustomObject]   '$($ArgumentList -is [PSCustomObject])'" -ForegroundColor Yellow

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
            
            & $command $argumentList
            
            $writeProgressHashtable[$_].CurrentOperation = "Completed"
            $writeProgressHashtable[$_].PercentComplete  = 100
            $writeProgressHashtable[$_].Completed        = $true
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

        while ($jobs.State -ne 'Completed') {
            $totalCompletedJobCount = $jobs.ChildJobs | Where-Object { $_.State -eq 'Completed' } | Measure-Object | Select-Object -ExpandProperty Count
            $percentComplete = [int](($totalCompletedJobCount * 100 / $totalJobCount))
            Write-Progress -Activity "Parent Activity" -Status "${totalCompletedJobCount} / ${totalJobCount} (${percentComplete}%)" -Id $totalJobCount -CurrentOperation "CurrentOperation" -ParentId -1 -PercentComplete $percentComplete
            Start-Sleep -Milliseconds 250
            $writeProgressHashtable.Keys | %{
                $progressSplat = $writeProgressHashtable[$_]
                if ($progressSplat.CurrentOperation -ne 'NotStarted') {
                    Write-Progress @progressSplat
                }
            }
        }

    }

}
