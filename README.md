# Examples

Get the machine `%PATH%` environment variable, sort and make the values distinct.

```powershell
Get-EnvironmentVariable Machine | select -ExpandProperty Path | %{$_.Data -split ';'} | %{$_.TrimEnd('/\')} | sort -Unique | %{$out+=$_} -Begin{$out=@()} -End{$out -join ';'}
```

Alternative notation:

```powershell
((Get-EnvironmentVariable Machine).Path.Data -split ';' | %{$_.TrimEnd('/\')} | sort -Unique) -join ';'
```

## Test `%Path%` existence

```
(Get-EnvironmentVariable Machine)['Path'].Data -split ';' | % -pv path {$_} | % -pv pwshPath { $_ -replace '%(.+?)%', '$env:$1'} | % -pv resolvedPath { $ExecutionContext.InvokeCommand.ExpandString($pwshPath) } | %{[PSCustomObject]@{path = $path; pwsh = $pwshPath; resolved = $resolvedPath; exists = (Test-Path $resolvedPath -Type Container)}}
```