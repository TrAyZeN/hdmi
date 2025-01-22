`default_nettype none
`include "video_formats.vh"

// Produce control and data signals based on the video format timings.
//
// Make pass valid CEA-861-D video format parameters. See video_formats.vh for
// already defined ones.
module video_format_encoder #(
) (
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
  // Number of active horizontal clocks per line
  localparam integer HORIZONTAL_ACTIVE = `HORIZONTAL_ACTIVE;
  // Number of blanking horizontal clocks per line
  localparam integer HORIZONTAL_BLANKING = `HORIZONTAL_BLANKING;
  // Horizontal clock offset (zero-based) of hsync enable
  localparam integer HSYNC_START = `HSYNC_START;
  // hsync enable duration in horizontal clocks
  localparam integer HSYNC_LEN = `HSYNC_LEN;
  // Line offset (zero-based) of active lines
  localparam integer VERTICAL_ACTIVE_START = `VERTICAL_ACTIVE_START;
  // Number of active vertical lines
  localparam integer VERTICAL_ACTIVE = `VERTICAL_ACTIVE;
  // Number of blanking vertical lines
  localparam integer VERTICAL_BLANKING = `VERTICAL_BLANKING;
  // Line offset (zero-based) of vsync enable
  localparam integer VSYNC_START = `VSYNC_START;
  // vsync enable duration in lines
  localparam integer VSYNC_LEN = `VSYNC_LEN;
  // High polarity of the hsync and vsync signals. 0 means sync signals are
  // low when enable, 1 means sync signals are high when enable.
  localparam integer SYNC_EN_POLARITY = `SYNC_EN_POLARITY;

  localparam integer HORIZONTAL_ACTIVE_START = HORIZONTAL_BLANKING;
  localparam integer HSYNC_END = HSYNC_START + HSYNC_LEN;
  localparam integer VIDEO_GUARD_START = HORIZONTAL_ACTIVE_START - 2;
  localparam integer VIDEO_PREAMBLE_START = VIDEO_GUARD_START - 8;

  localparam integer VSYNC_END = VSYNC_START + VSYNC_LEN;

  reg [23:0] frame_cnt;

  always @(*) begin
    if (hcnt < HORIZONTAL_BLANKING + HORIZONTAL_ACTIVE / 3) begin
      pixel_data_0 = frame_cnt[7:0];
      pixel_data_1 = frame_cnt[15:8];
      pixel_data_2 = frame_cnt[23:16];
    end else if (hcnt < HORIZONTAL_BLANKING + 2 * (HORIZONTAL_ACTIVE / 3)) begin
      pixel_data_0 = frame_cnt[15:8];
      pixel_data_1 = frame_cnt[7:0];
      pixel_data_2 = frame_cnt[23:16];
    end else begin
      pixel_data_0 = frame_cnt[15:8];
      pixel_data_1 = frame_cnt[23:16];
      pixel_data_2 = frame_cnt[7:0];
    end
  end

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
      hsync = SYNC_EN_POLARITY ? 1'b1 : 1'b0;
    end else begin
      hsync = SYNC_EN_POLARITY ? 1'b0 : 1'b1;
    end

    if (vcnt >= VSYNC_START && vcnt < VSYNC_END) begin
      vsync = SYNC_EN_POLARITY ? 1'b1 : 1'b0;
    end else begin
      vsync = SYNC_EN_POLARITY ? 1'b0 : 1'b1;
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
      // WARN: I don't think it is still the case for other formats than 640x480
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
      assert (SYNC_EN_POLARITY ? hsync : !hsync);
      else assert (SYNC_EN_POLARITY ? !hsync : hsync);

    if (vcnt >= VSYNC_START && vcnt < VSYNC_END)
      assert (SYNC_EN_POLARITY ? vsync : !vsync);
      else assert (SYNC_EN_POLARITY ? !vsync : vsync);

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
`endif  // FORMAL
endmodule
