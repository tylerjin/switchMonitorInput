param([switch]$DryRun, [switch]$CheckOnly)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$config = Get-Content (Join-Path $root "DualMonitor.local.json") -Raw | ConvertFrom-Json
$macHdmi = [int]$config.LgMacHdmi
$winHdmi = [int]$config.LgWindowsHdmi
if ($macHdmi -notin 1..4 -or $winHdmi -notin 1..4 -or $macHdmi -eq $winHdmi) {
    throw "Invalid LG input map; Dell KVM unchanged."
}
$lg = "C:\Program Files\LGTV Companion\LGTVcli.exe"
$ddc = Join-Path $root "ControlMyMonitor.exe"
$log = Join-Path $root "SwitchBothToMac.log"
if (!(Test-Path $lg) -or !(Test-Path $ddc)) { throw "Missing LGTVcli or ControlMyMonitor" }
if ($DryRun) { "READY: LG -> HDMI_$macHdmi; Dell -> USB-C 27"; exit 0 }

function LogLine([string]$line) {
    Add-Content -LiteralPath $log -Value ("{0:yyyy-MM-dd HH:mm:ss.fff} {1}" -f (Get-Date), $line)
}
function TvRequest([string[]]$arguments) {
    $response = (& $lg @arguments 2>&1 | Out-String).Trim()
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) { throw "LGTVcli exit=$exitCode response=$response" }
    try { $json = $response | ConvertFrom-Json -ErrorAction Stop }
    catch { throw "LGTVcli invalid JSON response=$response" }
    if ($null -ne $json.Device1.error) { throw "LG error: $($json.Device1.error)" }
    if ($json.Device1.payload.returnValue -eq $false) {
        throw "LG rejected command: $response"
    }
    return $json
}
function CurrentInput() {
    $r = TvRequest @("-request", "com.webos.applicationManager/getForegroundAppInfo", "Device1")
    $id = [string]$r.Device1.payload.appId
    if (!$id) { throw "LG did not return foreground input" }
    return $id
}
$target = "com.webos.app.hdmi$macHdmi"
try {
    $before = CurrentInput
    LogLine "BEGIN current=$before target=$target"
    if ($CheckOnly) { "TV_CURRENT=$before"; exit 0 }
    if ($before -ne $target) {
        $null = TvRequest @("-sethdmi", "$macHdmi", "Device1")
    }
    $matched = 0
    for ($i=0; $i -lt 10; $i++) {
        Start-Sleep -Milliseconds 500
        $current = CurrentInput
        LogLine "READBACK[$i]=$current"
        if ($current -eq $target) { $matched++ } else { $matched = 0 }
        if ($matched -ge 2) { break }
    }
    if ($matched -lt 2) {
        LogLine "LG_NOT_CONFIRMED; restoring HDMI$winHdmi"
        $null = TvRequest @("-sethdmi", "$winHdmi", "Device1")
        throw "LG did not stay on HDMI$macHdmi; Dell KVM was not switched."
    }
    & $ddc /SetValue "DEL4278" 60 27
    if ($LASTEXITCODE -ne 0) {
        LogLine "DELL_SET_FAILED; restoring LG HDMI$winHdmi"
        $null = TvRequest @("-sethdmi", "$winHdmi", "Device1")
        throw "Dell switch failed"
    }
    LogLine "OK LG=HDMI$macHdmi Dell=USB-C27"
    "OK LG=HDMI$macHdmi Dell=USB-C27"
} catch {
    LogLine "ERROR $($_.Exception.Message)"
    throw
}
