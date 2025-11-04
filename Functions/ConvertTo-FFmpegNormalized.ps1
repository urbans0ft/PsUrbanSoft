function ConvertTo-FFmpegNormalized {
    #  Get-FFmpegLoudNorm -InputUrl 'input.wav' -IntegratedLoudness -16 -DualMono
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$InputFile,
        [Parameter()]
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
    }
    
    process {
        $loudNorm      = Get-FFmpegLoudNorm -InputUrl $InputFile -IntegratedLoudness $IntegratedLoudness -LoudnessRange $LoudnessRange -TruePeak $TruePeak -DualMono:$DualMono
        $input_i       = $loudNorm.input_i
        $input_tp      = $loudNorm.input_tp
        $input_lra     = $loudNorm.input_lra
        $input_thresh  = $loudNorm.input_thresh
        $target_offset = $loudNorm.target_offset
        Write-Host "& ffmpeg -i $InputFile -af ""loudnorm=I=${IntegratedLoudness}:LRA=${LoudnessRange}:TP=${TruePeak}:dual_mono=$($DualMono.ToString().ToLower()):measured_I=${input_i}:measured_LRA=${input_lra}:measured_TP=${input_tp}:measured_thresh=${input_thresh}:offset=${target_offset}"" output.m4a"
        & ffmpeg -i $InputFile -af "loudnorm=I=${IntegratedLoudness}:LRA=${LoudnessRange}:TP=${TruePeak}:dual_mono=$($DualMono.ToString().ToLower()):measured_I=${input_i}:measured_LRA=${input_lra}:measured_TP=${input_tp}:measured_thresh=${input_thresh}:offset=${target_offset}" output.m4a
    }
    
    end {
        
    }
}
