/**
     * PLL configuration
     *
     * This Verilog module was generated automatically
     * using the gowin-pll tool.
     * Use at your own risk.
     *
     * Target-Device:                GW2A-18 C8/I7
     * Given input frequency:        12.000 MHz
     * Requested output frequency:   252.000 MHz
     * Achieved output frequency:    252.000 MHz
     */

    module top2_pll(
            input  clock_in,
            output clock_out,
            output locked
        );

        rPLL #(
            .FCLKIN("12.0"),
            .IDIV_SEL(0), // -> PFD = 12.0 MHz (range: 3-500 MHz)
            .FBDIV_SEL(20), // -> CLKOUT = 252.0 MHz (range: 500-625 MHz)
            .ODIV_SEL(2) // -> VCO = 504.0 MHz (range: 625-1250 MHz)
        ) pll (.CLKOUTP(), .CLKOUTD(), .CLKOUTD3(), .RESET(1'b0), .RESET_P(1'b0), .CLKFB(1'b0), .FBDSEL(6'b0), .IDSEL(6'b0), .ODSEL(6'b0), .PSDA(4'b0), .DUTYDA(4'b0), .FDLY(4'b0), 
            .CLKIN(clock_in), // 12.0 MHz
            .CLKOUT(clock_out), // 252.0 MHz
            .LOCK(locked)
        );

    endmodule

    