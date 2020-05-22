//montmult_M
`define montmult_N2 2'b00
`define montmult_N2_plus_2  2'b01
`define montmult_N  2'b10

module montmult_triple_M(clk, start, multiplier, multiplicand, M_select, done, product);

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
input [M_length + 15:0] multiplier;
input [M_length + 15:0] multiplicand;
input [1:0] M_select;
output done;
output [M_length + 15:0] product;

wire clk;
wire start;
wire [M_length + 15:0] multiplier;
wire [M_length + 15:0] multiplicand;
wire [1:0] M_select;
wire done;
wire [M_length + 15:0] product;

wire [M_length + 31:0] Z = 0; 
reg [M_length + 31:0] Z_reg = 0; 
wire [M_length + 31:0] T = 0;
reg [M_length + 15:0] multiplier_reg = 0; 
reg [M_length + 15:0] multiplicand_reg = 0;
reg [M_length + 15:0] T_reg = 0;
reg [M_length - 1:0] M_reg = 0;
reg [15:0] M_dash_reg = 0;
wire [31:0] U = 0;  
reg [5:0] counter = (M_length / 16) + 3;

// Set output signals
assign done = (counter == (M_length / 16) + 2 ) ? 1'b1 : 1'b0;  // M_length / 16 = 32
assign product = T_reg;

// Set internal signals
assign Z = multiplier_reg[15:0] * multiplicand_reg;
assign U = ((T_reg[15:0] + Z_reg[15:0])) * M_dash_reg;
assign T = T_reg + Z_reg + M_reg * U[15:0];
  
 
  always @(posedge clk) begin
    if((start == 1'b 1 || counter < ((M_length / 16) + 2))) begin
      // сменить число на константу равную длине сообщения (M_length / 16) + 2
      if((start == 1'b 1)) begin
        // Clear T register and counter
        T_reg <={(M_length + 15){1'b0}};
        counter <= 0;
      end
      else begin
        // Shift T into register, increment counter
        T_reg <= T[M_length + 31:16];
        counter <= counter + 1;
      end
    end
  end

  always @(posedge clk) begin
    if((start == 1'b 1)) begin
      // Update multiplier register, clear Z register
      multiplier_reg <= multiplier;
      Z_reg <= {(M_length + 31){1'b0}};
    end
    else begin
      // Shift multiplicand register, update Z register
      multiplier_reg[M_length - 1:0] <= multiplier_reg[M_length + 15:16];
      Z_reg <= Z;
    end
  end

  always @(posedge clk) begin
    if((start == 1'b 1)) begin
      multiplicand_reg <= multiplicand;
      case(M_select)
      2'b00 : begin
        M_reg <= N2[M_length - 1:0];
        M_dash_reg <= N2_dash;
      end
      2'b01 : begin
        M_reg <= N2_plus_2[M_length - 1:0];
        M_dash_reg <= N2_plus_2_dash;
      end
      2'b10 : begin
        M_reg <= N[M_length - 1:0];
        M_dash_reg <= N_dash;
      end
      endcase
    end
  end
endmodule

