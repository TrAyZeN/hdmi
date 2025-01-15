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
  always @(*) begin
    pixel_data_0 = 8'hff;
    pixel_data_1 = 8'hff;
    pixel_data_2 = 8'hff;
  end

  // 640x480p @ 59.94/60Hz video format according to CEA-861-D
  // Pixel clock frequency is 25.125/25.200MHz

  localparam integer HORIZONTAL_BLANKING = 160;
  localparam integer HORIZONTAL_ACTIVE = 640;
  localparam integer HORIZONTAL_ACTIVE_START = HORIZONTAL_BLANKING;
  localparam integer HSYNC_START = 16;
  localparam integer HSYNC_END = HSYNC_START + 96;
  localparam integer VIDEO_GUARD_START = HORIZONTAL_ACTIVE_START - 2;
  localparam integer VIDEO_PREAMBLE_START = VIDEO_GUARD_START - 8;

  localparam integer VERTICAL_BLANKING = 45;
  localparam integer VERTICAL_ACTIVE_START = 35;
  localparam integer VERTICAL_ACTIVE = 480;

  reg [$clog2(VERTICAL_BLANKING + VERTICAL_ACTIVE) - 1:0] vcnt;
  reg [$clog2(HORIZONTAL_BLANKING + HORIZONTAL_ACTIVE) - 1:0] hcnt;

  always @(posedge pixel_clk or posedge rst) begin
    if (rst) begin
      hsync <= 1'b1;
      vsync <= 1'b1;
      ctl   <= 1'b0;

      hcnt  <= 0;
      vcnt  <= 0;
    end else begin
      if (hcnt >= HSYNC_START && hcnt < HSYNC_END) begin
        hsync <= 1'b0;
      end else begin
        hsync <= 1'b1;
      end

      if (vcnt < 2) begin
        vsync <= 1'b0;
      end else begin
        vsync <= 1'b1;
      end

      if (hcnt >= HORIZONTAL_ACTIVE_START && vcnt >= VERTICAL_ACTIVE_START && vcnt < VERTICAL_ACTIVE_START + VERTICAL_ACTIVE) begin
        de <= 1'b1;
      end else begin
        de <= 1'b0;
      end

      if (hcnt >= VIDEO_PREAMBLE_START && hcnt < VIDEO_GUARD_START) begin
        ctl <= 4'b0001;
      end else if (hcnt >= VIDEO_GUARD_START && hcnt < HORIZONTAL_ACTIVE_START) begin
        // TODO
      end else begin
        ctl <= 4'b0000;
      end

      // Update increment hcnt and vcnt
      if (hcnt + 1 < HORIZONTAL_BLANKING + HORIZONTAL_ACTIVE) begin
        hcnt <= hcnt + 1;
      end else begin
        hcnt <= 0;

        if (vcnt + 1 < VERTICAL_BLANKING + VERTICAL_ACTIVE) begin
          hcnt <= 0;
        end else begin
          vcnt <= 0;
        end
      end
    end
  end
endmodule
