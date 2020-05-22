
// modexp_single_M_task

`define modexp_exp  1'b0
`define modexp_mult 1'b1


module modexp_single_M (clk, start, my_task, base_in, exponent, done, power);

parameter cycles_per_sampling = 30000;
parameter key_length = 256;
parameter data_length = 32;
parameter [2047:0] N2 = 508'h1778EB55F880F45868FCBBAA0E3411D3B134284D427EE14309C24941EB42E9B7A63200697FA831F9079F50C23D151877A764ACF0BE62040A94CF09BDDF23469;
parameter N2_dash = 16'h6427;
parameter [2047:0] N_mont = 508'h138FD70691ED6093BA71A1D3DC302F7E24D692CDE4AEF2F0287E865E1FD0A1045DEB148374ED4722F556808B87B567C4D52A30E6A9B0240ECD87DF27F2F8BA5;
parameter [2047:0] N_plus_1_mont = 508'hA61394247DD8E660BC2132DD5DCFE7A8A930EBBC26C7DF710A66C272632786A2835382CAE13CEDE09C25B4B4A83599F04E7D9D7C28A5416448920E3D253BDF;
parameter [2047:0] N2_plus_2 = 508'h1778EB55F880F45868FCBBAA0E3411D3B134284D427EE14309C24941EB42E9B7A63200697FA831F9079F50C23D151877A764ACF0BE62040A94CF09BDDF2346B;
parameter [15:0]   N2_plus_2_dash = 16'h27BD;
parameter [2047:0] N = 256'h13611A1EC706880C740F5081ECE4FABD0866205F6DD4061577A9275E12695093;
parameter [15:0] N_dash = 16'h B265;
parameter [2047:0] random_seed = 508'hB1FEEFAFADBE9EFDBACD510261CCF4F17A5088BA4D402DC93BBA837CB4826C27A109463FAEFEF20662D96DA751B5E811E51EED0665E4F8FFEA89C610BD5FA8;
parameter [2047:0] lambda = 508'h33AD9AFCBD66C021357E2C0522629CA0B8D0DCD6C99331A360C85042AA8C348;
parameter [2047:0] N_inv_R_mont = 508'h14FFB8D29D6FFE75E4B10794BF40B6FD27039C9B7CB1F727884A229F5130ACB082C505AF92D33B2163C8C7DD4BDBE1DBC2381AE8446D13B6C97B7B8A916F80D;
parameter [2047:0] mu_mont = 256'hE228860E3E3B5BDC36E523B5A2B7FF2FCD227B92F62D4B7FDC1A8ED984BD474;
parameter [2047:0] k_p_theta = 32'hFFFFFFDF;
parameter [2047:0] k_d_theta = 32'hFFFFE00B;
parameter [2047:0] k_alpha = 32'hFFFFD623;
parameter [2047:0] neg_k_d_theta = 16'h1FF5;
parameter [2047:0] neg_k_d_alpha = 16'h27F3;
parameter [2047:0] R2_mod_N2 = 508'hBDD0D1FC84A56B42D19C5A9DB797FA71960982BAB9EE33BB2485A3493B365A75012A71B635151A77167FAD41A5A2689667AFBC6EA822F61FBEEA76D6AE4476;
parameter [2047:0] R_mod_N2 = 508'hE4A4D91AE71222ABA4D2D0407E0E0D016F0A43B203C6C49F1EA2F0AF1A4C11D707C2412B8CEB9B41C0B2B81FFE30A51D72255E1D73C34120BD04B79BE7E4A3;
parameter N2_length = 512;

input clk;
input start;
input my_task;
input [N2_length + 15:0] base_in;
input [N2_length + 15:0] exponent;
output done;
output [N2_length + 15:0] power;

wire clk;
wire start;
wire my_task;
wire [N2_length + 15:0] base_in;
wire [N2_length + 15:0] exponent;
wire done;
wire [N2_length + 15:0] power;
//reg mult_start;
//reg baseloop_in;
//reg mult_done;

// Declare I/O registers
reg task_reg = 1'b 0;
reg [N2_length + 15:0] base_reg = 0; 
reg [N2_length + 15:0] exponent_reg = 0;
reg [N2_length + 15:0] power_reg = 0; 
wire [N2_length + 15:0] baseloop_in = 0; 
wire [N2_length + 15:0] baseloop_out = 0; 
wire [N2_length + 15:0] poweracc_in = 0; 
wire [N2_length + 15:0] poweracc_out = 0;
reg [4:0] counter = 0; 
reg mult_first_start = 1'b0;
wire last_iteration = 1'b0; 
wire mult_start = 1'b0; 
wire mult_done = 1'b0; 
reg old = 1'b0;



montmult_single_M baseloop (
    .clk(clk),
    .start(mult_start),
    .multiplier(baseloop_in),
    .multiplicand(baseloop_in),
    .done(mult_done),
    .product(baseloop_out)
);

montmult_single_M poweracc(
    .clk(clk),
    .start(mult_start),
    .multiplier(baseloop_in),
    .multiplicand(poweracc_in),
    //.done(open), //open is open ports in vhdl, not in verilog, needs to change
    .product(poweracc_out)
    );


assign done = mult_done & last_iteration;
assign power = (old == 1'b 1 || task_reg == 1'b1) ? poweracc_out : power_reg;

assign poweracc_in = (task_reg == 1'b1) ? exponent_reg : old == 1'b0 ? power_reg : poweracc_out;
assign last_iteration = (counter == data_length || (counter == 1 && task_reg == 1'b1)) ? 1'b1 : 1'b0;
assign mult_start = mult_first_start | ((mult_done &&  ~last_iteration));

always @(posedge clk) begin
    if((start == 1'b 1)) begin
// Update input registers, reset internal registers and counter, start baseloop for the first time
      task_reg <= my_task;
      base_reg <= base_in;
      exponent_reg <= exponent;
      power_reg <= R_mod_N2[N2_length + 15:0];
      counter <= 0;
      mult_first_start <= 1'b 1;
      old <= 1'b 0;
    end
    else if((mult_start == 1'b 1)) begin
// Shift exponent register
      exponent_reg[data_length - 2:0] <= exponent_reg[data_length - 1:1];
      old <= exponent_reg[0];
// Update power_reg if multiplication just completed was necessary
      if((old == 1'b 1)) begin
        power_reg <= poweracc_out;
      end
// Increment counter
      counter <= counter + 1;
      if((mult_first_start == 1'b 1)) begin
        mult_first_start <= 1'b 0;
      end
    end
  end

endmodule