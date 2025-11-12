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

# Hooks

## pre-commit

```shell
git ls-files -z |
xargs -0 -n1 git check-attr eol |
grep -E 'eol: (cr)?lf' |
sort -t: -k3 |
awk -F': ' -v q="'" '{
    arr[$3] = arr[$3] ? arr[$3] " " q $1 q : $1
} END {
    if ("crlf" in arr) print "unix2dos " arr["crlf"]
    if ("lf"   in arr) print "dos2unix " arr["lf"]
}' |
while IFS= read -r line; do
    eval "$line"
done
```