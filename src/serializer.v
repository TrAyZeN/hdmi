// Convert parallel data to serial.
//
// It is implemented with a parallel-in serial-out (PISO) shift register.
module serializer #(
    parameter integer WIDTH = 10
) (
    input rst,
    // Serial clock
    input clk,
    input we,
    input [WIDTH-1:0] data_in,
    output serial_out
);
  reg [WIDTH-1:0] piso_shift_register;

  assign serial_out = piso_shift_register[0];

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      for (integer i = 0; i < WIDTH; i = i + 1) begin
        piso_shift_register[i] <= 1'b0;
      end
    end else begin
      if (we) begin
        piso_shift_register <= data_in;
      end else begin
        for (integer i = 0; i + 1 < WIDTH; i = i + 1) begin
          piso_shift_register[i] <= piso_shift_register[i+1];
        end
      end
    end
  end
endmodule
