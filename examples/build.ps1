param(
    [ValidateSet("all", "prepare", "build", "clean")]
    [string]$target = "all"
)

$ErrorActionPreference = "Stop"

$SUBDIRS = @(
    "rom_bank_demo",
    "midi_sound_gen",
    "multiplier_demo"
)

$OCS_REL = "2026-04-12"
$GBDK_VER = "4.5.0"

$OCS_FNAME = "oss-cad-suite-windows-x64-$($OCS_REL -replace '-','').exe"
$OCS_URL = "https://github.com/YosysHQ/oss-cad-suite-build/releases/download/$OCS_REL/$OCS_FNAME"
$GBDK_FNAME = "gbdk-win64.zip"
$GBDK_URL = "https://github.com/gbdk-2020/gbdk-2020/releases/download/$GBDK_VER/$GBDK_FNAME"
$PYFTDI_WHL = "pyftdi-0.57.1-py3-none-any.whl"
$PYFTDI_URL = "https://files.pythonhosted.org/packages/16/cd/0731490946e037e954ef83719f07c7672cf32bc90dd9c75201c40b827664/$PYFTDI_WHL"
$PYUSB_WHL = "pyusb-1.2.1-py3-none-any.whl"
$PYUSB_URL = "https://files.pythonhosted.org/packages/15/a8/4982498b2ab44d1fcd5c49f07ea3795eab01601dc143b009d333fcace3b9/$PYUSB_WHL"
$PYSERIAL_WHL = "pyserial-3.5-py2.py3-none-any.whl"
$PYSERIAL_URL = "https://files.pythonhosted.org/packages/07/bc/587a445451b253b285629263eb51c2d8e9bcea4fc97826266d186f96f558/$PYSERIAL_WHL"
$DL_PATH = "downloads"
$PY_SITEPKG = Join-Path $DL_PATH "oss-cad-suite\lib\python3.11\site-packages"

if (-not ([Environment]::Is64BitOperatingSystem)) {
    throw "Unsupported architecture"
}

function target_prepare {
    $ProgressPreference = 'SilentlyContinue'

    New-Item -ItemType Directory -Force -Path $DL_PATH | Out-Null

    if (-not (Test-Path (Join-Path $DL_PATH "oss-cad-suite"))) {
        Write-Host "--- OSS CAD Suite is not found. Downloading."
        $OCS_DLPATH = Join-Path $DL_PATH $OCS_FNAME
        Invoke-WebRequest -Uri $OCS_URL -OutFile $OCS_DLPATH
        & $OCS_DLPATH x -o"$DL_PATH"
        Remove-Item -Path $OCS_DLPATH -Force
    }

    if (-not (Test-Path (Join-Path $DL_PATH "gbdk"))) {
        Write-Host "--- GBDK is not found. Downloading."
        $GBDK_DLPATH = Join-Path $DL_PATH $GBDK_FNAME
        Invoke-WebRequest -Uri $GBDK_URL -OutFile $GBDK_DLPATH
        Expand-Archive -Path $GBDK_DLPATH -DestinationPath $DL_PATH -Force
        Remove-Item -Path $GBDK_DLPATH -Force
    }

    if (-not (Test-Path (Join-Path $PY_SITEPKG "pyftdi"))) {
        Write-Host "--- PyFTDI is not found. Downloading."
        $PYFTDI_DLPATH = (Join-Path $DL_PATH $PYFTDI_WHL) + ".zip"
        Invoke-WebRequest -Uri $PYFTDI_URL -OutFile $PYFTDI_DLPATH
        Expand-Archive -Path $PYFTDI_DLPATH -DestinationPath $PY_SITEPKG -Force
        Remove-Item -Path $PYFTDI_DLPATH -Force
    }

    if (-not (Test-Path (Join-Path $PY_SITEPKG "usb"))) {
        Write-Host "--- PyUSB is not found. Downloading."
        $PYUSB_DLPATH = (Join-Path $DL_PATH $PYUSB_WHL) + ".zip"
        Invoke-WebRequest -Uri $PYUSB_URL -OutFile $PYUSB_DLPATH
        Expand-Archive -Path $PYUSB_DLPATH -DestinationPath $PY_SITEPKG -Force
        Remove-Item -Path $PYUSB_DLPATH -Force
    }

    if (-not (Test-Path (Join-Path $PY_SITEPKG "serial"))) {
        Write-Host "--- PySerial is not found. Downloading."
        $PYSERIAL_DLPATH = (Join-Path $DL_PATH $PYSERIAL_WHL) + ".zip"
        Invoke-WebRequest -Uri $PYSERIAL_URL -OutFile $PYSERIAL_DLPATH
        Expand-Archive -Path $PYSERIAL_DLPATH -DestinationPath $PY_SITEPKG -Force
        Remove-Item -Path $PYSERIAL_DLPATH -Force
    }
}

function target_build {
    foreach ($d in $SUBDIRS) {
        Push-Location $d
        try {
            & .\build.ps1 build
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
            & .\build.ps1 clean
            if ($LASTEXITCODE -ne 0) {
                throw "clean failed in $d"
            }
        }
        finally {
            Pop-Location
        }
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
