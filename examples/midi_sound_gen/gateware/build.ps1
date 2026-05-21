param(
    [ValidateSet("all", "prepare", "build", "clean")]
    [string]$target = "all"
)

$ErrorActionPreference = "Stop"

$PROJ = "midi_sound_gen"
$TOP = "cartridge_top"

$SRCS = @(
    "..\..\common\gateware\rtl\led_driver.sv",
    "..\..\common\gateware\rtl\bidir_pad.sv",
    "..\..\common\gateware\rtl\spi_master.sv",
    "..\..\common\gateware\rtl\flash2spram.sv",
    "..\..\common\gateware\rtl\SP256K_4x.sv",
    "..\..\common\gateware\rtl\pipe_buf.sv",
    "..\..\common\gateware\rtl\reset_gen.sv",
    "..\..\common\gateware\rtl\mac.sv",
    ".\rtl\midi_rx.sv",
    ".\rtl\uart_rx.sv",
    ".\rtl\midi_parser.sv",
    ".\rtl\poly2mono.sv",
    ".\rtl\ptcam.sv",
    ".\rtl\nrfreq_table.sv",
    ".\rtl\nrfreq_interpolator.sv",
    ".\rtl\cartridge_top.sv"
)

$PCF = "..\..\common\gateware\pin.pcf"

$OCSENV  = "..\..\downloads\oss-cad-suite\environment.ps1"
$YOSYS = "yosys.exe"
$NEXTPNR = "nextpnr-ice40.exe"
$ICEPACK = "icepack.exe"
$ICETIME = "icetime.exe"
$PYTHON = "python3.exe"

$JSON = "$PROJ.json"
$ASC = "$PROJ.asc"
$BIN = "$PROJ.bin"
$RPT = "$PROJ.rpt"

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
    . $OCSENV

    Start-Process -NoNewWindow -Wait -FilePath $PYTHON -ArgumentList "scripts\create_nrfreq_table.py" -RedirectStandardOutput "meminit_nrfreq_table.svh"

    & $YOSYS -p "synth_ice40 -top $TOP -json $JSON" $SRCS
    if ($LASTEXITCODE -ne 0) {
        throw "build failed while running yosys"
    }

    & $NEXTPNR --up5k --package sg48 --asc $ASC --pcf $PCF --json $JSON
    if ($LASTEXITCODE -ne 0) {
        throw "build failed while running nextpnr"
    }

    & $ICEPACK $ASC $BIN
    if ($LASTEXITCODE -ne 0) {
        throw "build failed while running icepack"
    }

    & $ICETIME -d up5k -mtr $RPT $ASC
    if ($LASTEXITCODE -ne 0) {
        throw "build failed while running icetime"
    }
}

function target_clean {
    @("meminit_nrfreq_table.svh", "*.bin", "*.json", "*.asc", "*.rpt") | ForEach-Object {
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
