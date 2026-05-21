param(
    [ValidateSet("all", "prepare", "build", "clean", "flash")]
    [string]$target = "all"
)

$ErrorActionPreference = "Stop"

$PROJ = "midi_sound_gen"
$SUBDIRS = @("gateware", "software")

$PYTHON = "..\downloads\oss-cad-suite\lib\python3.exe"
$TGBFLASH = "..\tools\tgbflash.py"

$PS = "powershell.exe"

function target_prepare {
    Push-Location "..\"
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
    foreach ($d in $SUBDIRS) {
        Push-Location $d
        try {
            & $PS .\build.ps1 build
            if ($LASTEXITCODE -ne 0) {
                throw "build failed in $d"
            }
        }
        finally {
            Pop-Location
        }
    }
}

function target_clean {
    foreach ($d in $SUBDIRS) {
        Push-Location $d
        try {
            & $PS .\build.ps1 clean
            if ($LASTEXITCODE -ne 0) {
                throw "clean failed in $d"
            }
        }
        finally {
            Pop-Location
        }
    }
}

function target_flash {
    & $PYTHON $TGBFLASH `
	--file (Join-Path "gateware" "$PROJ.bin") (Join-Path "software" "$PROJ.gb") `
	--offset 0x000000 0x080000 `
	--erase --verify
    if ($LASTEXITCODE -ne 0) {
        throw "flash failed"
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
    "flash" {
        target_flash
    }
    "all" {
        target_prepare
        target_build
    }
}
