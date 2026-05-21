param(
    [ValidateSet("all", "prepare", "build", "clean")]
    [string]$target = "all"
)

$ErrorActionPreference = "Stop"

$PROJ = "multiplier_demo"

$SRC = "$PROJ.c"
$GB = "$PROJ.gb"

$CC = "..\..\downloads\gbdk\bin\lcc"
$CFLAGS = "-Wa-l -Wl-m -Wl-j"

$PS = "powershell.exe"

function target_prepare {
    Push-Location "..\..\"
    try {
        & $PS .\build.ps1 prepare
        if ($LASTEXITCODE -ne 0) {
            throw "prepare failed"
        }
    }
    finally {
        Pop-Location
    }
}

function target_build {
    & $CC $CFLAGS -o $GB $SRC
    if ($LASTEXITCODE -ne 0) {
        throw "build failed while running lcc"
    }
}

function target_clean {
    @("*.map", "*.gb", "*.noi") | ForEach-Object {
        Remove-Item $_ -Force -ErrorAction SilentlyContinue
    }
}

switch ($target) {
    "prepare" {
        target_prepare
    }
    "build" {
        target_build
    }
    "clean" {
        target_clean
    }
    "all" {
        target_prepare
        target_build
    }
}
