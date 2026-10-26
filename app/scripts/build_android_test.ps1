param([string]$Flutter = 'D:/flutter/bin/flutter.bat')
$ErrorActionPreference = 'Stop'
$appRoot = Split-Path -Parent $PSScriptRoot
$javaTmp = Join-Path $appRoot 'build/java-tmp'
New-Item -ItemType Directory -Path $javaTmp -Force | Out-Null
$previousJavaOptions = $env:JAVA_TOOL_OPTIONS
try {
    # Short Unix-domain socket path avoids Windows JDK loopback connection error.
    $env:JAVA_TOOL_OPTIONS = ($previousJavaOptions + ' -Djdk.net.unixdomain.tmpdir="' + $javaTmp + '"').Trim()
    Push-Location $appRoot
    try {
        & $Flutter build apk --release --dart-define-from-file=config/firebase-android.json
        if ($LASTEXITCODE -ne 0) { throw "Flutter build failed ($LASTEXITCODE)" }
    } finally { Pop-Location }
} finally { $env:JAVA_TOOL_OPTIONS = $previousJavaOptions }
