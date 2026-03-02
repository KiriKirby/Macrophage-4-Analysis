param(
    [Parameter(Mandatory = $true)]
    [string]$MacroPath
)

$i = 0
$calls = New-Object System.Collections.Generic.List[string]

Get-Content -Encoding UTF8 $MacroPath | ForEach-Object {
    $i++
    if ($_ -match 'run\("([^"]+)"') {
        $calls.Add($matches[1])
    }
}

"run_call_count=$($calls.Count)"
"unique_commands="
$calls | Sort-Object | Get-Unique | ForEach-Object { "  - $_" }

