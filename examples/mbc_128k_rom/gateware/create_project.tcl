prj_create \
  -name "mbc_128k_rom" \
  -impl "impl_1" \
  -dev iCE40UP5K-SG48I \
  -performance "High-Performance_1.2V" \
  -synthesis "lse"
prj_add_source \
  ./rtl/cartridge_top.sv \
  ../../common/gateware/rtl/bidir_pad.sv \
  ../../common/gateware/rtl/flash2spram.sv \
  ../../common/gateware/rtl/SP256K_4x.sv \
  ../../common/gateware/rtl/led_driver.sv \
  ../../common/gateware/rtl/pipe_buf.sv \
  ../../common/gateware/rtl/reset_gen.sv \
  ../../common/gateware/pin.ldc
prj_run Synthesis -impl impl_1
prj_run Map -impl impl_1
prj_run PAR -impl impl_1
prj_run Export -impl impl_1
prj_save
prj_close