//// plant_interface_task
//`define encrypt = 2'b00;
//`define decrypt = 2'b01;
//`define rng = 2'b10;
//// modexp_triple_M_task
//`define modexp_exp_N2 = 2'b00;
//`define modexp_mult_N2 = 2'b01;
//`define modexp_mult_N2_plus_2 = 2'b10;
//`define modexp_mult_N = 2'b11;
//// controller_task
//`define setpoint = 2'b00;
//`define control = 2'b01
//`define update_state = 2'b10;
//// montmult_M
//`define montmult_N2 = 2'b00;
//`define montmult_N2_plus_2 = 2'b01
//`define montmult_N = 2'b10;

//// modexp_single_M_task
//`define modexp_exp = 1'b0;
//`define modexp_mult = 1'b1

module paillier_inverted_pendulum(clk,start,theta,alpha,theta_setpoint,alpha_setpoint,done,control_input);

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
input [data_length - 1:0] theta;
input [data_length - 1:0] alpha;
input [data_length - 1:0] theta_setpoint;
input [data_length - 1:0] alpha_setpoint;
output done;
output [data_length - 1:0] control_input;

wire [0:1] plant_interface_task_signal = 2'b00;
wire [0:1] controller_task_signal = 2'b00;

reg [data_length - 1:0] theta_reg = 0; 
reg [data_length - 1:0] alpha_reg = 0; 
reg [data_length - 1:0] theta_setpoint_reg = 0; 
reg [data_length - 1:0] alpha_setpoint_reg = 0;

wire [527:0] plant_interface_in = 0;
wire [527:0] plant_interface_out = 0; 
wire [527:0] controller_theta = 0; 
wire [527:0] controller_alpha = 0; 
wire [527:0] control_input_enc = 0; 

reg [527:0] control_input_enc_reg = 0; 
reg [527:0] theta_enc_reg = 0;

wire plant_interface_start = 1'b0;
wire controller_start = 1'b0; 
wire plant_interface_done = 1'b0; 
wire controller_done = 1'b0; 
reg first_iteration = 1'b0; 

wire plant_interface_last_iteration = 1'b0; 
wire controller_last_iteration = 1'b0;
reg [3:0] plant_interface_counter = 3'b000;  // natural range 0 to 5 := 0;
reg [1:0] controller_counter = 2'b00;  // natural range 0 to 3 := 0;

plant_interface plant_interface(
    .clk(clk),
    .start(plant_interface_start),
    .my_task(plant_interface_task_signal),
    .data_in(plant_interface_in),
    .done(plant_interface_done),
    .data_out(plant_interface_out)
);

controller_inv_pen controller_inverted_pendulum(
    .clk(clk),
    .start(controller_start),
    .my_task(controller_task_signal),
    .theta(controller_theta),
    .alpha(controller_alpha),
    .done(controller_done),
    .control_input(control_input_enc));



assign done = plant_interface_done & controller_done & plant_interface_last_iteration & controller_last_iteration;

assign control_input = plant_interface_out[data_length - 1:0];
// 2'b00 - enc 2'b01 - dec 2'b01 - rng
assign plant_interface_task_signal = (plant_interface_counter == 0 || plant_interface_counter == 1) ? 2'b00 : (plant_interface_counter == 2 || plant_interface_counter == 3) ? 2'b10 : 2'b01;
assign plant_interface_in [data_length - 1:0] = (plant_interface_counter == 0) ? (theta_reg) : (plant_interface_counter == 1) ? (alpha_reg) : (plant_interface_counter == 2 || plant_interface_counter == 3) ? (1234567890) : control_input_enc_reg;

assign controller_task_signal = (controller_counter == 0) ? 2'b00 : (controller_counter == 1) ? 2'b01 : 2'b10;

assign controller_theta [data_length - 1:0] = controller_counter == 0 ? theta_setpoint_reg : theta_enc_reg;
assign controller_alpha [data_length - 1:0] = controller_counter == 0 ? alpha_setpoint_reg : plant_interface_out;

assign plant_interface_last_iteration = (plant_interface_counter == 5) ? 1'b1 : 1'b0;
assign controller_last_iteration = (controller_counter == 3) ? 1'b1 : 1'b0;

assign plant_interface_start = (first_iteration == 1'b1 || (plant_interface_done == 1'b1 && plant_interface_last_iteration == 1'b0)) ? 1'b1 : 1'b0;
assign controller_start = (first_iteration == 1'b1 || (controller_done == 1'b1 && controller_last_iteration == 1'b0 && (controller_counter != 1 || (plant_interface_counter == 2 && plant_interface_done == 1'b1)))) ? 1'b1 : 1'b0;

 always @(posedge clk) begin
    if((start == 1'b 1)) begin
      // Update input registers and counter, start baseloop for the first time
      theta_reg <= theta;
      alpha_reg <= alpha;
      theta_setpoint_reg <= theta_setpoint;
      alpha_setpoint_reg <= alpha_setpoint;
      plant_interface_counter <= 0;
      controller_counter <= 0;
      first_iteration <= 1'b1;
    end
    else begin
      if((controller_start == 1'b1)) begin
        // Increment counter
        controller_counter <= controller_counter + 1;
      end
      if((plant_interface_start == 1'b1)) begin
        // Increment counter
        plant_interface_counter <= plant_interface_counter + 1;
      end
      if((first_iteration == 1'b1)) begin
        first_iteration <= 1'b0;
      end
      if((controller_counter == 2 && controller_done == 1'b1)) begin
        control_input_enc_reg <= control_input_enc;
      end
      if((plant_interface_counter == 1 && plant_interface_done == 1'b1)) begin
        theta_enc_reg <= plant_interface_out;
      end
    end
  end
  
endmodule