`default_nettype none

module top (
    input clk,
    // TODO: Check polarity
    input rst,
    output [2:0] tmds_data_p,
    output [2:0] tmds_data_n,
    output tmds_clk_p,
    output tmds_clk_n
    // TODO: CEC, EDID_CLK, EDID_DAT
);
  wire serial_clk, pixel_clk;
  wire de, hsync, vsync;
  wire [3:0] ctl;
  wire [7:0] pixel_data[3];
  wire tmds_data[3];
  wire pll_locked;

  hdmi_pll hdmi_pll (
      .rst(rst),
      .clk_in(clk),
      .serial_clk(serial_clk),
      .pixel_clk(pixel_clk),
      .locked(pll_locked)
  );

  wire hdmi_rst = rst | ~pll_locked;

  video_format_encoder video_format_encoder (
      .pixel_clk(pixel_clk),
      .rst(hdmi_rst),
      .de(de),
      .hsync(hsync),
      .vsync(vsync),
      .ctl(ctl),
      .pixel_data_0(pixel_data[0]),
      .pixel_data_1(pixel_data[1]),
      .pixel_data_2(pixel_data[2])
  );

  hdmi_transmitter hdmi_transmitter (
      .serial_clk(serial_clk),
      .pixel_clk(pixel_clk),
      .rst(hdmi_rst),
      .de(de),
      .pixel_data_0(pixel_data[0]),
      .pixel_data_1(pixel_data[1]),
      .pixel_data_2(pixel_data[2]),
      .hsync(hsync),
      .vsync(vsync),
      .ctl(ctl),
      .tmds_data_0(tmds_data[0]),
      .tmds_data_1(tmds_data[1]),
      .tmds_data_2(tmds_data[2])
  );

  generate
    genvar channel_idx;
    for (channel_idx = 0; channel_idx < 3; channel_idx = channel_idx + 1) begin
      TLVDS_OBUF tmds_channel_driver (
          .I (tmds_data[channel_idx]),
          .O (tmds_data_p[channel_idx]),
          .OB(tmds_data_n[channel_idx])
      );
    end
  endgenerate

  TLVDS_OBUF tmds_clk_driver (
      .I (pixel_clk),
      .O (tmds_clk_p),
      .OB(tmds_clk_n)
  );
endmodule
