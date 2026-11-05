param([switch]$DryRun)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $root "DualMonitor.local.json"
if (!(Test-Path $configPath)) { throw "Missing DualMonitor.local.json" }
$config = Get-Content $configPath -Raw | ConvertFrom-Json
$lgMacHdmi = [int]$config.LgMacHdmi
if ($lgMacHdmi -lt 1 -or $lgMacHdmi -gt 4) {
    throw "Mac HDMI port on LG not configured (LgMacHdmi must be 1-4). Dell KVM was not switched."
}
$lgClient = "C:\Program Files\LGTV Companion\LGTVcli.exe"
$ddcClient = Join-Path $root "ControlMyMonitor.exe"
if (!(Test-Path $lgClient) -or !(Test-Path $ddcClient)) { throw "Required LGTVcli or ControlMyMonitor missing" }
if ($DryRun) {
    Write-Output "READY: LG -> HDMI_$lgMacHdmi; Dell -> USB-C 27"
    exit 0
}
$output = (& $lgClient -sethdmi $lgMacHdmi Device1 2>&1 | Out-String)
$code = $LASTEXITCODE
if ($code -ne 0 -or $output -match '"error"\s*:' -or $output -match '"returnValue"\s*:\s*false') {
    throw "LG switch failed (check LGTV Companion pairing); Dell keyboard KVM was not switched. Response: $output"
}
& $ddcClient /SetValue "DEL4278" 60 27
if ($LASTEXITCODE -ne 0) {
    throw "LG switched, but Dell DDC command failed; use the Dell OSD if necessary"
}
Write-Output "Sent LG HDMI_$lgMacHdmi and Dell USB-C 27"
