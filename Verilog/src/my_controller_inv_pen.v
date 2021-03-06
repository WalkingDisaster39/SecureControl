 // controller_task
`define setpoint 2'b00
`define control  2'b01
`define update_state  2'b10

module controller_inv_pen (clk,start, my_task, theta, alpha, done, control_input );

//Should be multiple of 16
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
parameter M_length = 512;

input clk;
input start;
input [0:1] my_task;
input [527:0] theta;
input [527:0] alpha;
output done;
output [527:0] control_input;

wire clk;
wire start;
wire [0:1] my_task;
wire [527:0] theta;
wire [527:0] alpha;
wire done;
wire [527:0] control_input;

reg [0:1] task_reg = 2'b00;
wire [0:1] exp_task = 1'b 0;
reg [527:0] theta_reg = 0; 
reg [527:0] alpha_reg = 0; 
reg [527:0] theta_setpoint_reg = 0; 
reg [527:0] alpha_setpoint_reg = 0; 
wire [527:0] exp_base = 0;
wire [527:0] exp_exponent = 0; 
wire [527:0] enc_base = 0; 
wire [527:0] enc_exponent = 0; 
wire [527:0] con_base = 0; 
wire [527:0] con_exponent = 0; 
wire [527:0] state_base = 0; 
wire [527:0] state_exponent = 0; 
wire [527:0] exp_out = 0;

reg [527:0] state = R_mod_N2[527:0];
wire exp_start = 1'b 0;
wire exp_done = 1'b 0; 
reg first_iteration = 1'b 0; 
wire last_iteration = 1'b 0;
reg [3:0] counter = 0;

modexp_single_M modexp_single_M (
    .clk(clk),
    .start(exp_start),
    .my_task(exp_task),
    .base_in(exp_base),
    .exponent(exp_exponent),
    .done(exp_done),
    .power(exp_out)
);

assign done = exp_done & last_iteration;
assign control_input = exp_out;

`define modexp_exp_N2 = 2'b00;
`define modexp_mult_N2 = 2'b01;
`define modexp_mult_N2_plus_2 = 2'b10;
`define modexp_mult_N = 2'b11;
assign exp_task = ((counter == 0 || counter == 2 || counter == 4 || counter == 6 || counter == 8) && task_reg == 2'b01) || ((counter == 0 || counter == 1) && task_reg == 2'b10) ? 1'b0 : 1'b1;

  // Select data inputs to modexp based on the task

assign exp_base = (task_reg == 2'b01) ? con_base : (task_reg == 2'b10) ? state_base : enc_base;
assign exp_exponent = (task_reg == 2'b01) ? con_exponent : (task_reg == 2'b10) ? state_exponent : enc_exponent;

assign enc_base = (counter == 0) ? theta_reg : counter == 2 ? alpha_reg : exp_out + 1;
assign enc_exponent = (counter == 0) || counter == 2 ? N_mont[527:0] : R2_mod_N2[527:0];

assign con_base = (counter == 0) ? theta_reg : counter == 4 ? theta_reg : counter == 6 ? alpha_reg : exp_out;
assign con_exponent = (counter == 0) ? {528{1'b1}} : counter == 1 ? theta_setpoint_reg : counter == 2 ? k_p_theta[527:0] : counter == 3 ? state : counter == 4 ? k_d_theta[527:0] : counter == 5 ? state : counter == 6 ? {528{1'b1}} : counter == 7 ? alpha_setpoint_reg : counter == 8 ? k_alpha[527:0] : state;

assign state_base = (counter == 0) ? theta_reg : counter == 1 ? alpha_reg : exp_out;
assign state_exponent = (counter == 0) ? neg_k_d_theta[527:0] : counter == 1 ? neg_k_d_alpha[527:0] : state;

assign last_iteration = (counter == 4 && task_reg == 2'b00) || (counter == 10 && task_reg == 2'b01) || (counter == 3 && task_reg == 2'b10) ? 1'b 1 : 1'b 0;
assign exp_start = first_iteration | ((exp_done &  ~last_iteration));

 always @(posedge clk) begin
    if((start == 1'b 1)) begin

// Update input registers and counter, start baseloop for the first time

      if((my_task != 2'b10)) begin
        theta_reg <= theta;
        alpha_reg <= alpha;
      end
      counter <= 0;
      first_iteration <= 1'b 1;
      task_reg <= my_task;
    end
    else begin
      if((exp_start == 1'b 1)) begin
        // Increment counter
        counter <= counter + 1;
        if((first_iteration == 1'b 1)) begin
          first_iteration <= 1'b 0;
        end
      end
      if((task_reg == 1'b0 && counter == 2 && exp_done == 1'b 1)) begin
        theta_setpoint_reg <= exp_out;
      end
      if((task_reg == 1'b0 && counter == 4 && exp_done == 1'b 1)) begin
        alpha_setpoint_reg <= exp_out;
      end
      if((((task_reg == 2'b01 && (counter == 4 || counter == 6)) || (task_reg == 2'b10 && (counter == 1 || counter == 3))) && exp_done == 1'b 1)) begin
        state <= exp_out;
      end
      if((task_reg == 2'b01 && counter == 1 && exp_done == 1'b1)) begin
        theta_reg <= exp_out;
      end
      if((task_reg == 2'b01 && counter == 8 && exp_done == 1'b1)) begin
        alpha_reg <= exp_out;
      end
    end
  end

endmodule
