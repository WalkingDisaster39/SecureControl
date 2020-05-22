module uart( clk, start, bus_in, done, serial_out);


// Should be multiple of 8

parameter [31:0] input_width = 48; //48
parameter [31:0] cycles_per_bit = 391; //391

input clk;
input start;
input [input_width - 1:0] bus_in;
output done;
output serial_out;

wire clk;
wire start;
wire [input_width - 1:0] bus_in;
wire done;
wire serial_out;

// Declare I/O registers
reg [input_width - 1:0] bus_reg = 0;
reg [2:0] byte_counter = (input_width / 8) + 1;;
reg [3:0] bit_counter = 9;
reg [8:0] clk_counter = 0;

// Set output signals
  assign done = byte_counter == 1'b 0 ? 1'b 1 : 1'b 0;
  assign serial_out = (bit_counter == 9 || byte_counter == 1'b 0) ? 1'b 1 : bit_counter == 0 ? 1'b 0 : bus_reg[0];

always @(posedge clk) begin
    if((start == 1'b 1)) begin
    // Update input registers, reset internal registers and counter
      bus_reg <= bus_in;
      byte_counter <= 0;
      bit_counter <= 0;
      clk_counter <= 0;
    end
    else if((byte_counter < 1'b 1)) begin
    // natural(input_width / 8)
    // Increment counters
      if((clk_counter < (cycles_per_bit - 1))) begin
        clk_counter <= clk_counter + 1;
      end
      else begin
        clk_counter <= 0;
        if((bit_counter > 0 && bit_counter < 9)) begin
    // Shift bus register
          bus_reg[input_width - 2:0] <= bus_reg[input_width - 1:1];
        end
        if((bit_counter < 9)) begin
          bit_counter <= bit_counter + 1;
        end
        else begin
          bit_counter <= 0;
          byte_counter <= byte_counter + 1;
        end
      end
    end
  end
endmodule