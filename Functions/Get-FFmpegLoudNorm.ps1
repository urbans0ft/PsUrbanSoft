function Get-FFmpegLoudNorm {
    <#
    .SYNOPSIS
        Get EBU R128 loudness normalization values.
        This algorithm can target IL, LRA, and maximum true peak. In dynamic mode, to accurately
        detect true peaks, the audio stream will be upsampled to 192 kHz.
    .DESCRIPTION
        The method uses ffmpeg command to geht the parsed loudnorm values of a given input file.
        Those values can be used in a second run to normalize the audio file.
    .PARAMETER InputUrl
        The input file.
    .PARAMETER IntegratedLoudness
        Set integrated loudness target. Range is -70.0 - -5.0. Default value is -24.0.
        -23 LUFS for broadcast; -16 LUFS for podcasts/music-consumption.
    .PARAMETER LoudnessRange
        Set loudness range target. Range is 1.0 - 50.0. Default value is 7.0.
        Increase if you want more dynamic range.
    .PARAMETER TruePeak
        Set maximum true peak. Range is -9.0 - +0.0. Default value is -2.0.
        Usually -2.0 dBTP for safe delivery.
    .PARAMETER DualMono
        Treat mono input files as "dual-mono". If a mono file is intended for playback on a
        stereo system, its EBU R128 measurement will be perceptually incorrect. If set to true,
        this option will compensate for this effect. Multi-channel input files are not affected
        by this option. Options are true or false. Default is false.
    .LINK
        https://www.ffmpeg.org/ffplay-all.html#loudnorm
    .EXAMPLE
        Get-FFmpegLoudNorm 'audio.mp3' -IntegratedLoudness -16
        & ffmpeg -i 'audio.mp3' -filter:a loudnorm=I=-16:LRA=7:TP=-2:dual_mono=false:print_format=json -f null -

        input_i            : -22.37
        input_tp           : -0.88
        input_lra          : 7.50
        input_thresh       : -33.61
        output_i           : -16.69
        output_tp          : -2.00
        output_lra         : 4.90
        output_thresh      : -27.87
        normalization_type : dynamic
        target_offset      : 0.69
    .EXAMPLE
        Get-ChildItem *.mp3 | Get-FFmpegLoudNorm -IntegratedLoudness -16
        Output all used ffmpeg calls and the corresponding json output.
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$InputUrl,
        [ValidateRange(-70.0, -5.0)]
        [double]$IntegratedLoudness = -24,
        [ValidateRange(1.0, 50.0)]
        [double]$LoudnessRange = 7,
        [ValidateRange(-9.0, 0.0)]
        [double]$TruePeak = -2.0,
        [switch]$DualMono
    )
        
    begin {
        # Check if ffmpeg command is installed.
        if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
            throw "Command 'ffmpeg' not found!"
        }

        $inputObjects  = @{}
        $progressTable = [System.Collections.Concurrent.ConcurrentDictionary[int, hashtable]]::new()
        
    }
        
    process {
        $inputObjects[($inputObjects.Keys.Count)] = @(
            '-i', $InputUrl,
            '-vn', # disable video processing
            '-filter:a', # filter audio (alias -af)
            "loudnorm=I=${IntegratedLoudness}:LRA=${LoudnessRange}:TP=${TruePeak}:dual_mono=$($DualMono.ToString().ToLower()):print_format=json",
            '-f', 'null', # force output format (see: https://www.ffmpeg.org/ffmpeg.html#Main-options)
            '-'
        )
    }
        
    end {
        $jobs = $inputObjects.GetEnumerator() | ForEach-Object -AsJob -Parallel {
            $id             = $_.Key
            $ffmpegParams   = $_.Value
            $file           = Get-Item $ffmpegParams[1]
            $fileName       = $file.Name
            $progressTable  = $using:progressTable
            $progressTable[$id] = @{
                Activity         = "ffmpeg"
                Status           = "$fileName"
                Id               = $id
                Completed        = $false
            }

            $commandLine = "& ffmpeg $($ffmpegParams | %{ ($_ -match '\s') ? ("'$_'") : ($_)})"
            Write-Host $commandLine -ForegroundColor Green
            $stdouterr = & ffmpeg $ffmpegParams 2>&1 | ForEach-Object { [string]$_ }
            $withinJson = $false
            $ret = $stdouterr | ForEach-Object {
                if ($withinJson) {
                    $_
                    if ($_ -eq '}') {
                        $withinJson = $false
                    }
                }
                if ($_ -like '`[Parsed_loudnorm_*') {
                    $withinJson = $true
                }
            } | ConvertFrom-Json

            # Add the input file to the return object
            $inputFile = $ffmpegParams[1]
            $ret | Add-Member -MemberType NoteProperty -Name 'input' -Value (Get-Item $inputFile)

            $progressTable[$id]['Status']          = "finished"
            $progressTable[$id]['Completed']       = $true

            Write-Output $ret -NoEnumerate
        }

        $totalCount     = $jobs.ChildJobs.Count
        while ($jobs.State -ne 'Completed') {
            $completedCount  = ($jobs.ChildJobs | Where-Object { $_.State -eq 'Completed' }).Count
            $percentComplete = [int](($completedCount / $totalCount) * 100)

            Write-Progress -Activity "ffmpeg loudnorm analysis" -Status "${percentComplete}% completed ($completedCount/$totalCount)" -PercentComplete $percentComplete -Id $totalCount

            Start-Sleep -Milliseconds 100

            $progressTable.Keys | %{
                $progressSplat = $progressTable[$_]
                Write-Progress @progressSplat -ParentId $totalCount
            }
        }

        # set all progresses to completed
        $progressTable.Keys | %{
            $id = $_
            Write-Progress -Id $id -ParentId $totalCount -Completed
        }
        Write-Progress -Id $totalCount -Completed

        # return the results from the jobs
        $jobs.ChildJobs.Output
    }
}
