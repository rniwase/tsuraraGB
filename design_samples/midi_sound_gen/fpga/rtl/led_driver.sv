module led_driver (
  input  logic [2:0] din,
  output logic [2:0] pad
);

  RGB RGB_inst (
    .CURREN   (1'b1),
    .RGBLEDEN (1'b1),
    .RGB0PWM  (din[0]),
    .RGB1PWM  (din[1]),
    .RGB2PWM  (din[2]),
    .RGB0     (pad[0]),
    .RGB1     (pad[1]),
    .RGB2     (pad[2])
  );
  defparam RGB_inst.CURRENT_MODE = 0;
  defparam RGB_inst.RGB0_CURRENT = "0b111111";
  defparam RGB_inst.RGB1_CURRENT = "0b111111";
  defparam RGB_inst.RGB2_CURRENT = "0b111111";

endmodule
