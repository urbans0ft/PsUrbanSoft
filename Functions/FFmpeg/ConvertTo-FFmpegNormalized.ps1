function ConvertTo-FFmpegNormalized {
    #  Get-FFmpegLoudNorm -InputUrl 'input.wav' -IntegratedLoudness -16 -DualMono
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$InputFile,
        [Parameter(Mandatory)]
        [string]$OutputFile,
        [ValidateRange(-70.0, -5.0)]
        [double]$IntegratedLoudness = -24,
        [ValidateRange(1.0, 50.0)]
        [double]$LoudnessRange = 7,
        [ValidateRange(-9.0, 0.0)]
        [double]$TruePeak = -2.0,
        [switch]$DualMono
    )
    
    begin {
        [Collections.ArrayList]$inputObjects = @()
    }
    
    process {
        [void]$inputObjects.Add($InputFile)
    }
    
    end {
        $loudNorms     = $inputObjects | Get-FFmpegLoudNorm -IntegratedLoudness $IntegratedLoudness -LoudnessRange $LoudnessRange -TruePeak $TruePeak -DualMono:$DualMono
        $commandArgs   = $loudNorms | ForEach-Object {
            $filePath      = $_.input
            $input_i       = $_.input_i
            $input_tp      = $_.input_tp
            $input_lra     = $_.input_lra
            $input_thresh  = $_.input_thresh
            $target_offset = $_.target_offset
            Write-Output @(
                '-i',
                $filePath,
                '-af',
                "loudnorm=I=${IntegratedLoudness}:LRA=${LoudnessRange}:TP=${TruePeak}:dual_mono=$($DualMono.ToString().ToLower()):measured_I=${input_i}:measured_LRA=${input_lra}:measured_TP=${input_tp}:measured_thresh=${input_thresh}:offset=${target_offset}",
                $OutputFile
            ) -NoEnumerate
        }
        $commandArgs | Invoke-ParallelCommand -Command 'ffmpeg'
        
    }
}
