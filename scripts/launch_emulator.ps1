param (
   [string]$AvdName = "Medium_Phone",
   [string]$RunningDeviceId = "emulator-5554"
)

Write-Host "Checking for running devices..."
$devices = flutter devices

# 1. Check if already running
if ($devices -match $RunningDeviceId) {
   Write-Host "✅ Device ($RunningDeviceId) is already running. Checking boot status..."
}
else {
   Write-Host "🚀 Device not found. Launching AVD: $AvdName..."
   flutter emulators --launch $AvdName
}

# 2. Phase One: Wait for the emulator process to register
Write-Host "⏳ Phase 1: Waiting for device connection..."
$deviceConnected = $false
for ($i = 0; $i -lt 60; $i++) {
   # We use 'adb devices' here because it's much faster than 'flutter devices'
   # If adb isn't in your path, this will fail (see note below)
   $adbOutput = adb devices
   if ($adbOutput -match $RunningDeviceId) {
      $deviceConnected = $true
      break
   }
   Start-Sleep 1
}

if (-not $deviceConnected) {
   Write-Error "❌ Timeout: Emulator process never appeared."
   exit 1
}

# 3. Phase Two: Wait for Android OS to actually finish booting
Write-Host "⏳ Phase 2: Waiting for Android OS to finish booting..."

for ($i = 0; $i -lt 120; $i++) {
   # Ask the device: "Are you done loading?"
   # 2>$null hides errors if the shell isn't ready yet
   $bootStatus = adb -s $RunningDeviceId shell getprop sys.boot_completed 2>$null
    
   if ($bootStatus -and $bootStatus.Trim() -eq "1") {
      Write-Host "✅ Device is fully booted and ready."
      exit 0
   }
    
   # Optional: Print a dot to show life
   Write-Host -NoNewline "."
   Start-Sleep 2
}

Write-Error "`n❌ Timeout: Device connected, but Android OS didn't boot in time."
exit 1