
`timescale 1ps/1ps

module tb_top;

   wire [7:0]	ddr2_dq;
   wire [0:0]	ddr2_dqs;
   wire [0:0]	ddr2_dqs_n;
   wire [0:0]	ddr2_dm;
   wire [0:0]	ddr2_clk;
   wire [0:0]	ddr2_clk_n;
   wire [14:0]	ddr2_addr;
   wire [2:0]	ddr2_ba;
   wire			ddr2_ras_n;
   wire			ddr2_cas_n;
   wire			ddr2_we_n;
   wire [0:0]	ddr2_cs_n;
   wire [0:0]	ddr2_cke;
   wire [0:0]	ddr2_odt;

	reg sys_clk;
	reg sys_rst;

	always begin
		#5000 sys_clk = ~sys_clk;
	end

	top DUT(
		.sys_clk		(sys_clk),
		.sys_rst		(sys_rst),
		
		.leds			(),

		.mem_addr	(ddr2_addr),
		.mem_ba		(ddr2_ba),
		.mem_cas_n	(ddr2_cas_n),
		.mem_cke	(ddr2_cke),
		.mem_cs_n	(ddr2_cs_n),
		.mem_dm		(ddr2_dm),
		.mem_odt	(ddr2_odt),
		.mem_ras_n	(ddr2_ras_n),
		.mem_we_n	(ddr2_we_n),
		.mem_clk	(ddr2_clk),
		.mem_clk_n	(ddr2_clk_n),
		.mem_dq		(ddr2_dq),
		.mem_dqs	(ddr2_dqs)
	);

	ddr2_model u_mem0(
		.ck        (ddr2_clk),
		.ck_n      (ddr2_clk_n),
		.cke       (ddr2_cke),
		.cs_n      (ddr2_cs_n),
		.ras_n     (ddr2_ras_n),
		.cas_n     (ddr2_cas_n),
		.we_n      (ddr2_we_n),
		.dm_rdqs   (ddr2_dm),
		.ba        (ddr2_ba),
		.addr      (ddr2_addr),
		.dq        (ddr2_dq),
		.dqs       (ddr2_dqs),
		.dqs_n     (),
		.rdqs_n    (),
		.odt       (ddr2_odt)
	);

	initial begin
		fork begin
			#0 sys_rst = 1'b0;
			sys_clk = 1'b1;
			
			#10000 sys_rst = 1'b1;
			#100000 sys_rst = 1'b0;
		end join
	end

endmodule
