`default_nettype none

module video_format_encoder (
    input pixel_clk,
    input rst,
    output reg de,
    output reg hsync,
    output reg vsync,
    output reg [3:0] ctl,
    // NOTE: yosys does not support arrays as module arguments
    output reg [7:0] pixel_data_0,
    output reg [7:0] pixel_data_1,
    output reg [7:0] pixel_data_2
);
  reg [23:0] frame_cnt;

  always @(*) begin
    pixel_data_0 = frame_cnt[7:0];
    pixel_data_1 = frame_cnt[15:8];
    pixel_data_2 = frame_cnt[23:16];
  end

  // 640x480p @ 59.94/60Hz video format according to CEA-861-D
  // Pixel clock frequency is 25.125/25.200MHz

  localparam integer HORIZONTAL_ACTIVE = 640;
  localparam integer HORIZONTAL_BLANKING = 160;
  localparam integer HORIZONTAL_ACTIVE_START = HORIZONTAL_BLANKING;
  localparam integer HSYNC_START = 16;
  localparam integer HSYNC_END = HSYNC_START + 96;
  localparam integer VIDEO_GUARD_START = HORIZONTAL_ACTIVE_START - 2;
  localparam integer VIDEO_PREAMBLE_START = VIDEO_GUARD_START - 8;

  localparam integer VERTICAL_ACTIVE = 480;
  localparam integer VERTICAL_BLANKING = 45;
  localparam integer VERTICAL_ACTIVE_START = 35;
  localparam integer VSYNC_START = 0;
  localparam integer VSYNC_END = VSYNC_START + 2;

  reg [$clog2(VERTICAL_BLANKING + VERTICAL_ACTIVE) - 1:0] vcnt;
  reg [$clog2(HORIZONTAL_BLANKING + HORIZONTAL_ACTIVE) - 1:0] hcnt;

  always @(posedge pixel_clk or posedge rst) begin
    if (rst) begin
      hcnt <= 0;
      vcnt <= 0;
      frame_cnt <= 0;
    end else begin
      if (hcnt < HORIZONTAL_BLANKING + HORIZONTAL_ACTIVE - 1) begin
        hcnt <= hcnt + 1;
      end else begin
        hcnt <= 0;

        if (vcnt < VERTICAL_BLANKING + VERTICAL_ACTIVE - 1) begin
          vcnt <= vcnt + 1;
        end else begin
          vcnt <= 0;
          frame_cnt <= frame_cnt + 1;
        end
      end
    end
  end

  always @(hcnt or vcnt) begin
    if (hcnt >= HSYNC_START && hcnt < HSYNC_END) begin
      hsync = 1'b0;
    end else begin
      hsync = 1'b1;
    end

    if (vcnt >= VSYNC_START && vcnt < VSYNC_END) begin
      vsync = 1'b0;
    end else begin
      vsync = 1'b1;
    end

    if (hcnt >= HORIZONTAL_ACTIVE_START && vcnt >= VERTICAL_ACTIVE_START && vcnt < VERTICAL_ACTIVE_START + VERTICAL_ACTIVE) begin
      de = 1'b1;
    end else begin
      de = 1'b0;
    end

    if (hcnt >= VIDEO_PREAMBLE_START && hcnt < VIDEO_GUARD_START) begin
      // Indicate that the next period is a video data period
      ctl = 4'b0001;
    end else if (hcnt >= VIDEO_GUARD_START && hcnt < HORIZONTAL_ACTIVE_START) begin
      // Video guard band
      // NOTE: Previous vsync and hsync assignment are coherent with the video guard
      {ctl[1], ctl[0]} <= 2'b10;
      {ctl[3], ctl[2]} <= 2'b11;
    end else begin
      ctl = 4'b0000;
    end
  end

`ifdef FORMAL
  // Formal verification

  // TODO: Check correct way to do that
  initial assume (rst);
  reg f_past_valid = 0;
  always @(posedge pixel_clk) begin
    f_past_valid <= 1;

    assert (hcnt >= 0 && hcnt < HORIZONTAL_BLANKING + HORIZONTAL_ACTIVE);
    assert (vcnt >= 0 && vcnt < VERTICAL_BLANKING + VERTICAL_ACTIVE);

    if (f_past_valid && !$past(rst) && !rst) begin
      if ($past(hcnt) != HORIZONTAL_BLANKING + HORIZONTAL_ACTIVE - 1)
        assert (hcnt > $past(hcnt));
        else begin
          assert (hcnt == 0);

          if ($past(vcnt) != VERTICAL_BLANKING + VERTICAL_ACTIVE - 1)
            assert (vcnt > $past(vcnt));
            else assert (vcnt == 0);
        end
    end

    if (hcnt >= HSYNC_START && hcnt < HSYNC_END)
      assert (!hsync);
      else assert (hsync);

    if (vcnt >= VSYNC_START && vcnt < VSYNC_END)
      assert (!vsync);
      else assert (vsync);

    if (vcnt >= VERTICAL_ACTIVE_START && vcnt < VERTICAL_ACTIVE_START + VERTICAL_ACTIVE) begin
      if (hcnt >= HORIZONTAL_ACTIVE_START)
        assert (de);
        else assert (!de);

      if (hcnt >= VIDEO_PREAMBLE_START && hcnt < VIDEO_GUARD_START) assert (ctl == 4'b0001);
      if (hcnt >= VIDEO_GUARD_START && hcnt < HORIZONTAL_ACTIVE_START) begin
        assert ({vsync, hsync} == 2'b11);
        assert ({ctl[1], ctl[0]} == 2'b10);
        assert ({ctl[3], ctl[2]} == 2'b11);
      end
    end
  end
`endif
endmodule
