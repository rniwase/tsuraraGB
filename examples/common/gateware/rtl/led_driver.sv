module led_driver (
  input  logic [2:0] din,
  output logic [2:0] pad
);

  SB_RGBA_DRV #(
    .CURRENT_MODE ("0b0"     ),
    .RGB0_CURRENT ("0b111111"),
    .RGB1_CURRENT ("0b111111"),
    .RGB2_CURRENT ("0b111111")
  ) SB_RGBA_DRV_inst (
    .CURREN   (1'b1  ),
    .RGBLEDEN (1'b1  ),
    .RGB0PWM  (din[0]),
    .RGB1PWM  (din[1]),
    .RGB2PWM  (din[2]),
    .RGB0     (pad[0]),
    .RGB1     (pad[1]),
    .RGB2     (pad[2])
  );

endmodule
