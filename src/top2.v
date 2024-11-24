module top2 (
    input clk,
    output reg led,
    output reg led2
);
  wire clk_fast;
  wire clk_slow;

  hdmi_pll hdmi_pll (
      .clock_in(clk),
      .clock_out(clk_fast),
      .clock_out_div(clk_slow)
  );

  localparam integer CLK_FREQ = 252_000_000;
  integer cnt;
  reg clk_1s;

  always @(posedge clk_fast) begin
    if (cnt < CLK_FREQ / 2) begin
      clk_1s <= 1'b1;
    end else begin
      clk_1s <= 1'b0;
    end

    if (cnt + 1 < CLK_FREQ) begin
      cnt <= cnt + 1;
    end else begin
      cnt <= 0;
    end
  end

  always @(posedge clk_1s) begin
    led <= ~led;
  end

  // localparam integer CLK2_FREQ = 25_200_000;
  localparam integer CLK2_FREQ = 27_000_000;
  integer cnt2;
  reg clk_1s_2;

  // always @(posedge clk_slow) begin
  always @(posedge clk) begin
    if (cnt2 < CLK2_FREQ / 2) begin
      clk_1s_2 <= 1'b1;
    end else begin
      clk_1s_2 <= 1'b0;
    end

    if (cnt2 + 1 < CLK2_FREQ) begin
      cnt2 <= cnt2 + 1;
    end else begin
      cnt2 <= 0;
    end
  end

  always @(posedge clk_1s_2) begin
    led2 <= ~led2;
  end
endmodule
