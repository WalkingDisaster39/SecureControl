module spi(clk, start, miso, bus_in, done, sclk, mosi, ss, bus_out);

parameter [31:0] input_width = 136; //136
parameter [31:0] cycles_per_half_bit = 8; //8

input clk;
input start;
input miso;
input [input_width - 1:0] bus_in;
output done;
output sclk;
output mosi;
output ss;
output [input_width - 1:0] bus_out;

wire clk;
wire start;
wire miso;
wire [input_width - 1:0] bus_in;
wire done;
wire sclk;
wire mosi;
wire ss;
wire [input_width - 1:0] bus_out;

// Declare I/O registers
reg sclk_reg = 1'b 1;
reg [input_width - 1:0] bus_in_reg = 0; reg [input_width - 1:0] bus_out_reg = 0;
reg [31:0] bit_counter = input_width;
reg [31:0] clk_counter = 0;

// Set output signals
assign done = bit_counter < input_width ? 1'b 0 : 1'b 1;
assign sclk = sclk_reg;
assign mosi = bus_in_reg[input_width - 1];
assign ss = bit_counter < input_width ? 1'b 0 : 1'b 1;
assign bus_out = bus_out_reg;

always @(posedge clk) begin
    if((start == 1'b 1)) begin
      // Update input registers, reset internal registers and counter
      bus_in_reg <= bus_in;
      bit_counter <= 0;
      clk_counter <= 0;
    end
    else if((bit_counter < input_width)) begin
      // Increment counters
      if((clk_counter < (cycles_per_half_bit - 1))) begin
        clk_counter <= clk_counter + 1;
      end
      else begin
        if((sclk_reg == 1'b 0)) begin
          // Shift bus_in register up
          bus_in_reg[input_width - 1:1] <= bus_in_reg[input_width - 2:0];
          bit_counter <= bit_counter + 1;
        end
        else begin
          // Shift bus_out register up
          bus_out_reg[input_width - 1:1] <= bus_out_reg[input_width - 2:0];
          bus_out_reg[0] <= miso;
        end
        clk_counter <= 0;
        sclk_reg <=  ~sclk_reg;
      end
    end
  end

endmodule