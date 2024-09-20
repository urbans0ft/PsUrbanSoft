# Examples

Get the machine `%PATH%` environment variable, sort and make the values distinct.

```powershell
Get-EnvironmentVariable Machine | select -ExpandProperty Path | %{$_.Data -split ';'} | %{$_.TrimEnd('/\')} | sort -Unique | %{$out+=$_} -Begin{$out=@()} -End{$out -join ';'}
```

Alternative notation:

```powershell
((Get-EnvironmentVariable Machine).Path.Data -split ';' | %{$_.TrimEnd('/\')} | sort -Unique) -join ';'
```