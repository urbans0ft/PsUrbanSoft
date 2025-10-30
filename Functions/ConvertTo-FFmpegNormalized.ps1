function ConvertTo-FFmpegNormalized {
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
        [Collections.ArrayList]$inputObjects = @()
    }
    
    process {
        [void]$inputObjects.Add($InputFile)
    }
    
    end {
        $parallelBlock = [scriptblock] {
            
        }
        $inputObjects | ForEach-Object -Parallel $parallelBlock
    }
}
