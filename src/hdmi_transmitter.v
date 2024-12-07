// HDMI transmitter
//
// Only video data is supported (data island period and control/configuration
// commands not supported).
module hdmi_transmitter (
    input serial_clk,
    input pixel_clk,
    input rst,
    input de,
    input [7:0] pixel_data[3],
    input hsync,
    input vsync,
    input [3:0] ctl,
    output tmds_data[3]
);
  reg d0[3];
  reg d1[3];
  reg [9:0] tmds_symbols[3];

  // NOTE: Continuous assignment to arrays and assignment to an array slice are not supported yet by Icarus
  always @(*) begin
    d0[0] = hsync;
    d1[0] = vsync;
    d0[1] = ctl[0];
    d1[1] = ctl[1];
    d0[2] = ctl[2];
    d1[2] = ctl[3];
  end

  genvar channel_idx;
  generate
    for (channel_idx = 0; channel_idx < 3; channel_idx = channel_idx + 1) begin
      always @(posedge pixel_clk or posedge rst) begin
        if (rst) begin
          cnt_prev[channel_idx] <= 0;
        end else begin
          cnt_prev[channel_idx] <= cnt[channel_idx];
        end
      end

      tmds_encoder tmds_encoder (
          .d(pixel_data[channel_idx]),
          .c0(d0[channel_idx]),
          .c1(d1[channel_idx]),
          .de(de),
          .cnt_prev(cnt_prev[channel_idx]),
          .q_out(tmds_symbols[channel_idx]),
          .cnt(cnt[channel_idx])
      );

      // OSER10 serializes on rising and falling edges of FCLK
      // See https://cdn.gowinsemi.com.cn/UG289E.pdf
      OSER10 serializer (
          .D0(tmds_symbols[channel_idx][0]),
          .D1(tmds_symbols[channel_idx][1]),
          .D2(tmds_symbols[channel_idx][2]),
          .D3(tmds_symbols[channel_idx][3]),
          .D4(tmds_symbols[channel_idx][4]),
          .D5(tmds_symbols[channel_idx][5]),
          .D6(tmds_symbols[channel_idx][6]),
          .D7(tmds_symbols[channel_idx][7]),
          .D8(tmds_symbols[channel_idx][8]),
          .D9(tmds_symbols[channel_idx][9]),
          .FCLK(serial_clk),
          .PCLK(pixel_clk),
          .RESET(rst),
          .Q(tmds_data[channel_idx])
      );
    end
  endgenerate
endmodule
