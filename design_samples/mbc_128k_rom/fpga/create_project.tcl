prj_create -name "mbc_128k_rom" -impl "impl_1" -dev iCE40UP5K-SG48I -performance "High-Performance_1.2V" -synthesis "lse"
prj_add_source ./rtl/cartridge_top.sv ./rtl/bidir_pad.sv ./rtl/flash2spram.sv ./rtl/SP256K_4x.sv ./rtl/led_driver.sv ./rtl/pipe_buf.sv ./rtl/reset_gen.sv ./pin.ldc
prj_run Synthesis -impl impl_1
prj_run Map -impl impl_1
prj_run PAR -impl impl_1
prj_run Export -impl impl_1
prj_save
prj_close
