# Aria2 Speed-Up Protocol - PowerShell Wrapper
# Automatically uses optimized configuration regardless of workspace

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ARIA2_CONF = "$env:APPDATA\aria2\aria2.conf"

# Check if config exists, if not use default location
if (-not (Test-Path $ARIA2_CONF)) {
    $ARIA2_CONF = "E:\AI_Tools\Central_Repository\aria2.conf"
}

# Run aria2c with speed-up configuration
& aria2c --conf-path="$ARIA2_CONF" $Arguments

