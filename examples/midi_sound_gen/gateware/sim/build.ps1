param(
    [ValidateSet("all", "prepare", "build", "clean")]
    [string]$target = "all"
)

$ErrorActionPreference = "Stop"

$OCSENV  = "..\..\..\downloads\oss-cad-suite\environment.ps1"
$IVERILOG = "iverilog.exe"
$VVP = "vvp.exe"

$PS = "powershell.exe"

function target_prepare {
    Push-Location "..\..\..\"
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

function target_build_ptcam_testbench {
    & $IVERILOG -g2012 -o ptcam_testbench.out ..\rtl\ptcam.sv ptcam_testbench.sv
    if ($LASTEXITCODE -ne 0) {
        throw "build failed while running iverilog"
    }

    & $VVP ptcam_testbench.out
    if ($LASTEXITCODE -ne 0) {
        throw "build failed while running vvp"
    }
}

function target_build_poly2mono_testbench {
    & $IVERILOG -g2012 -o poly2mono_testbench.out ..\rtl\ptcam.sv ..\rtl\poly2mono.sv poly2mono_testbench.sv
    if ($LASTEXITCODE -ne 0) {
        throw "build failed while running iverilog"
    }

    & $VVP poly2mono_testbench.out
    if ($LASTEXITCODE -ne 0) {
        throw "build failed while running vvp"
    }
}

function target_build_midi_parser_testbench {
    & $IVERILOG -g2012 -o midi_parser_testbench.out ..\rtl\midi_parser.sv midi_parser_testbench.sv
    if ($LASTEXITCODE -ne 0) {
        throw "build failed while running iverilog"
    }

    & $VVP midi_parser_testbench.out
    if ($LASTEXITCODE -ne 0) {
        throw "build failed while running vvp"
    }
}

function target_build_midi_rx_testbench {
    & $IVERILOG -g2012 -o midi_rx_testbench.out ..\rtl\uart_rx.sv ..\rtl\ptcam.sv ..\rtl\poly2mono.sv ..\rtl\midi_parser.sv ..\rtl\midi_rx.sv uart_tx.sv midi_rx_testbench.sv
    if ($LASTEXITCODE -ne 0) {
        throw "build failed while running iverilog"
    }

    & $VVP midi_rx_testbench.out
    if ($LASTEXITCODE -ne 0) {
        throw "build failed while running vvp"
    }
}

function target_build {
    . $OCSENV
    target_build_ptcam_testbench
    target_build_poly2mono_testbench
    target_build_midi_parser_testbench
    target_build_midi_rx_testbench
}

function target_clean {
    @("*.out", "*.vcd") | ForEach-Object {
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
