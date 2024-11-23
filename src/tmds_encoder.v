// TMDS encoder.
//
// This encoder implements the TMDS encoding algorithm from DVI 1.0
// specification (https://glenwing.github.io/docs/DVI-1.0.pdf).
module tmds_encoder (
    input [7:0] d,
    // HDMI d0 and d1 are inverted ?
    input c0,
    input c1,
    input de,
    // cnt(t-1)
    input signed [4:0] cnt_prev,
    output reg [9:0] q_out,
    // cnt(t)
    output reg signed [4:0] cnt
);

  reg [3:0] n1_d;
  reg [8:0] q_m;
  reg [3:0] n1_q_m;
  reg [3:0] n0_q_m;

  always @(*) begin
    n1_d = d[0] + d[1] + d[2] + d[3] + d[4] + d[5] + d[6] + d[7];

    if (n1_d > 4 || (n1_d == 4 && d[0] == 0)) begin
      q_m[0] = d[0];
      q_m[1] = ~(q_m[0] ^ d[1]);
      q_m[2] = ~(q_m[1] ^ d[2]);
      q_m[3] = ~(q_m[2] ^ d[3]);
      q_m[4] = ~(q_m[3] ^ d[4]);
      q_m[5] = ~(q_m[4] ^ d[5]);
      q_m[6] = ~(q_m[5] ^ d[6]);
      q_m[7] = ~(q_m[6] ^ d[7]);
      q_m[8] = 1'b0;
    end else begin
      q_m[0] = d[0];
      q_m[1] = q_m[0] ^ d[1];
      q_m[2] = q_m[1] ^ d[2];
      q_m[3] = q_m[2] ^ d[3];
      q_m[4] = q_m[3] ^ d[4];
      q_m[5] = q_m[4] ^ d[5];
      q_m[6] = q_m[5] ^ d[6];
      q_m[7] = q_m[6] ^ d[7];
      q_m[8] = 1'b1;
    end

    n1_q_m = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
    n0_q_m = ~q_m[0] + ~q_m[1] + ~q_m[2] + ~q_m[3] + ~q_m[4] + ~q_m[5] + ~q_m[6] + ~q_m[7];

    if (de == 1'b1) begin
      if (cnt_prev == 0 || (n1_q_m == n0_q_m)) begin
        q_out[9]   = ~q_m[8];
        q_out[8]   = q_m[8];
        q_out[7:0] = q_m[8] ? q_m[7:0] : ~q_m[7:0];

        if (q_m[8] == 1'b0) begin
          cnt = cnt_prev + (n0_q_m - n1_q_m);
        end else begin
          cnt = cnt_prev + (n1_q_m - n0_q_m);
        end
      end else begin
        if ((cnt_prev > 0 && n1_q_m > n0_q_m) || (cnt_prev < 0 && n0_q_m > n1_q_m)) begin
          q_out[9] = 1'b1;
          q_out[8] = q_m[8];
          q_out[7:0] = ~q_m[7:0];
          cnt = cnt_prev + 2 * q_m[8] + (n0_q_m - n1_q_m);
        end else begin
          q_out[9] = 1'b0;
          q_out[8] = q_m[8];
          q_out[7:0] = q_m[7:0];
          cnt = cnt_prev - (2 * ((~q_m[8]) & 1)) + (n1_q_m - n0_q_m);
        end
      end
    end else begin
      cnt = 0;
      case ({
        c1, c0
      })
        2'b00: q_out = 10'b0010101011;
        2'b01: q_out = 10'b1101010100;
        2'b10: q_out = 10'b0010101010;
        2'b11: q_out = 10'b1101010101;
      endcase
    end
  end

endmodule
