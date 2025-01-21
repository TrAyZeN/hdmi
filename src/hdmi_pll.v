`default_nettype none

/**
 * PLL configuration
 *
 * This file was initially generated automatically using gowin-pll tool.
 *
 * Target-Device:                GW2A-18 C8/I7
 * Given input frequency:        27.000 MHz
 * Requested output frequency:   126.000 MHz
 * Achieved output frequency:    126.000 MHz
 */

module hdmi_pll (
    input  rst,
    input  clk_in,
    output serial_clk,
    output pixel_clk,
    output locked
);

  // See UG286E for more details
  rPLL #(
      .DEVICE("GW2A-18"),
      .FCLKIN("27"),
      // PFD = CLKIN / IDIV = CLKOUT / FBDIV
      // CLKOUT = (CLKIN * FBDIV) / IDIV
      // VCO = CLKOUT * ODIV
      // CLKOUTD = CLKOUT / SDIV
      .IDIV_SEL(2),  // -> PFD = 9.0 MHz (range: 3-500 MHz)
      .FBDIV_SEL(13),  // -> CLKOUT = 126.0 MHz (range: 3.90625-625 MHz)
      .ODIV_SEL(4),  // -> VCO = 504.0 MHz (range: 500-1250 MHz)
      .PSDA_SEL(4'b0000)  //,
      // SDIV_SEL cannot be used to produce the pixel clock as it does not
      // support odd values (and we need a divisor of 5)
  ) pll (
      .CLKOUTP(),
      .CLKOUTD(),
      .CLKOUTD3(),
      .RESET(rst),
      .RESET_P(1'b0),
      .CLKFB(1'b0),
      .FBDSEL(6'b0),
      .IDSEL(6'b0),
      .ODSEL(6'b0),
      .PSDA(4'b0),
      .DUTYDA(4'b0),
      .FDLY(4'b0),
      .CLKIN(clk_in),  // 27 MHz
      .CLKOUT(serial_clk),  // 126.0 MHz
      .LOCK(locked)
  );

  // serial_clk frequency is 5 times pixel_clk frequency as OSER10 transmits on rising and falling edges
  CLKDIV #(
      .DIV_MODE(5),
      .GSREN("false")
  ) clk_div (
      .HCLKIN(serial_clk),
      .RESETN(~rst),
      .CALIB (1'b1),
      .CLKOUT(pixel_clk)
  );

endmodule
