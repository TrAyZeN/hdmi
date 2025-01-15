`default_nettype none
/**
 * PLL configuration
 *
 * This Verilog module was generated automatically
 * using the gowin-pll tool.
 * Use at your own risk.
 *
 * Target-Device:                GW2A-18 C8/I7
 * Given input frequency:        27.000 MHz
 * Requested output frequency:   126.000 MHz
 * Achieved output frequency:    126.000 MHz
 */

module hdmi_pll (
    input  clock_in,
    output clock_out,
    output clock_out_div,
    output locked
);

  rPLL #(
      .FCLKIN("27"),
      // PFD = CLKIN / IDIV = CLKOUT / FBDIV
      // CLKOUT = (CLKIN * FBDIV) / IDIV
      // VCO = CLKOUT * ODIV
      .IDIV_SEL(2),  // -> PFD = 9.0 MHz (range: 3-500 MHz)
      .FBDIV_SEL(13),  // -> CLKOUT = 126.0 MHz (range: 3.90625-625 MHz)
      .ODIV_SEL(4),  // -> VCO = 504.0 MHz (range: 500-1250 MHz)
      .PSDA_SEL(4'b0000),
      .DYN_SDIV_SEL(5)
  ) pll (
      .CLKOUTP(),
      .CLKOUTD(clock_out_div),  // 25.200 MHz
      .CLKOUTD3(),
      .RESET(1'b0),
      .RESET_P(1'b0),
      .CLKFB(1'b0),
      .FBDSEL(6'b0),
      .IDSEL(6'b0),
      .ODSEL(6'b0),
      .PSDA(4'b0),
      .DUTYDA(4'b0),
      .FDLY(4'b0),
      .CLKIN(clock_in),  // 27 MHz
      .CLKOUT(clock_out),  // 126.0 MHz
      .LOCK(locked)
  );

endmodule
