$ErrorActionPreference = "Stop"

$Name = "com.web.platform"
$Src = $PSScriptRoot
$Dest = Join-Path $env:LOCALAPPDATA "WebPlatform"

if (-not (Test-Path "$Src\host.exe")) { throw "host.exe not found" }
if (-not (Test-Path "$Src\start.bat")) { throw "start.bat not found" }
if (-not (Test-Path "$Src\$Name.json")) { throw "$Name.json not found" }

$running = Get-Process | Where-Object { $_.Path -eq "$Dest\host.exe" }
if ($running) { $running | Stop-Process -Force }

New-Item -ItemType Directory -Force -Path "$Dest" | Out-Null
Copy-Item "$Src\host.exe" "$Dest\host.exe" -Force
if (Test-Path "$Dest\extension") { Remove-Item "$Dest\extension" -Recurse -Force }
Copy-Item "$Src\extension" "$Dest\extension" -Recurse -Force

$bat = (Get-Content "$Src\start.bat" -Raw).Replace("__DIR__", $Dest)
[System.IO.File]::WriteAllText("$Dest\start.bat", $bat)

$manifest = (Get-Content "$Src\$Name.json" -Raw).Replace("__DIR__", $Dest.Replace("\", "\\"))
[System.IO.File]::WriteAllText("$Dest\$Name.json", $manifest)

$roots = @("Google\Chrome", "Chromium", "Microsoft\Edge", "Mozilla")
foreach ($root in $roots) {
    $key = "HKCU:\Software\$root\NativeMessagingHosts\$Name"
    New-Item -Path $key -Force | Out-Null
    Set-ItemProperty -Path $key -Name "(default)" -Value "$Dest\$Name.json"
}

Write-Host "host installed to $Dest"
Write-Host "load the unpacked extension from $Dest\extension"
