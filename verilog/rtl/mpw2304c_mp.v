`default_nettype none

module mpw2304c_mp(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [17:0] io_in,
    output [17:0] io_out,
    output [17:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk, valid, clk_sdm;
    wire rst, dout_cos, dout_sin;

    wire [15:0] wdata, count, din, sin_d, cos_d;

    wire [3:0] wstrb;
    wire [31:0] la_write;
    
    localparam BITS = 16;

    // WB MI A
    assign valid = wbs_cyc_i && wbs_stb_i; 
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
    assign wdata = wbs_dat_i[15:0];

    // IO
    assign io_oeb = {(17){rst}};
    assign din = io_in[17:2];
    assign dout_cos = io_out[0];
    assign dout_sin = io_out[1];
    

    // IRQ
    assign irq = 3'b000;	// Unused

    // LA
    assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
    assign clk_sdm = io_in[0];
    assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;

	sdm_2o #(BITS, 6) dac_sin(
		.clk(clk_sdm),
        .rst_n(rst),
        .din(sin_d),
        .dout(dout_sin)
	);
	
	sdm_2o #(BITS, 6) dac_cos(
		.clk(clk_sdm),
        .rst_n(rst),
        .din(cos_d),
        .dout(dout_cos)
	);
	
	
	counter #(BITS) integrator(
		.clk(clk),
		.reset(~rst),
		.incr(din),
		.count(count)
	);
	
	wire signed [BITS:0] rescale;
	
	assign rescale = 17'b01100100100010000*(count >> 1) - 17'b01100100100010000;
	
	cordic_pipelined #(BITS, 14) cord_val(
		.angle(rescale),
		.sinus(sin_d),
		.cosinus(cos_d),
		.clk(clk)		
	);
endmodule
`default_nettype wire

