

`timescale 1ns/1ns

module top(

	input wire sys_clk,
	input wire sys_rst,

	output wire [2:0] leds,

	output	[14:0]	mem_addr,
	output	[2:0]	mem_ba,
	output		mem_cas_n,
	output	[0:0]	mem_cke,
	output	[0:0]	mem_cs_n,
	output	[0:0]	mem_dm,
	output	[0:0]	mem_odt,
	output		mem_ras_n,
	output		mem_we_n,
	inout	[0:0]	mem_clk,
	inout	[0:0]	mem_clk_n,
	inout	[7:0]	mem_dq,
	inout	[0:0]	mem_dqs
);

	reg error;

	wire phy_clk;
	wire local_init_done;

	//-----------ddr2 read and write operation---------
	reg   [26 :0]     local_address;
	reg               local_burstbegin;
	reg               local_read_req;
	reg               local_write_req;

	reg		[15 :0]		local_wdata;
	wire	[15 :0]		local_rdata;

	reg [2:0] local_state;

	reg [15:0] match_cnt;

	wire			local_ready;
	wire			local_rdata_valid;
	wire			reset_phy_clk_n;

	parameter IDLE	= 0,
	BURST_WRITE		= 1,
	BURST_WRITE_B	= 2,
	BURST_READ		= 3,
	DONE			= 4;
	//-----------ddr2 read and write operation---------

	reg [2:0] test_pat;


	assign leds[2:1] = {2{local_init_done}} & test_pat[1:0];
	assign leds[0] = local_init_done ^ error;

	ddr2 ddr2_u0(

		.pll_ref_clk		(sys_clk),

		.global_reset_n		(~sys_rst),
		.soft_reset_n		(~sys_rst),

		.local_address		(local_address),
		.local_write_req	(local_write_req),
		.local_read_req		(local_read_req),
		.local_burstbegin	(local_burstbegin),
		.local_wdata		(local_wdata),
		.local_be			(2'b11),
		.local_size			(2'd2),
		.local_ready			(local_ready),
		.local_rdata			(local_rdata),
		.local_rdata_valid		(local_rdata_valid),
		.local_refresh_ack		(),
		.local_init_done		(local_init_done),

		.reset_phy_clk_n	(reset_phy_clk_n),
		.phy_clk			(phy_clk),
		.reset_request_n	(),
		.aux_half_rate_clk	(),
		.aux_full_rate_clk	(),

		.mem_addr(mem_addr),
		.mem_ba(mem_ba),
		.mem_cas_n(mem_cas_n),
		.mem_cke(mem_cke),
		.mem_cs_n(mem_cs_n),
		.mem_dm(mem_dm),
		.mem_odt(mem_odt),
		.mem_ras_n(mem_ras_n),
		.mem_we_n(mem_we_n),
		.mem_reset_n(),
		.mem_clk(mem_clk),
		.mem_clk_n(mem_clk_n),
		.mem_dq(mem_dq),
		.mem_dqs(mem_dqs)
	);

	always @(posedge phy_clk)
    if (!reset_phy_clk_n) begin
        local_state <= IDLE;
		
		error <= 1'b0;

		local_read_req   <= 1'b0;
		local_write_req  <= 1'b0;
		local_burstbegin <= 1'b0;
		
		local_address    <= 27'd0;

		local_wdata <= 16'h0;
		match_cnt <= 16'h0;

		test_pat <= 3'd0;
		
    end else begin

		if(local_init_done & local_rdata_valid)begin
			if(test_pat >= 3'd6)
				match_cnt <= match_cnt + 1'b1;
			if(match_cnt != local_rdata)
				error <= 1'b1;
		end

		local_read_req   <= 1'b0;
		local_write_req  <= 1'b0;
		local_burstbegin <= 1'b0;
	
        case(local_state)
        IDLE:
        begin
            if(local_init_done & local_ready)begin
                local_state <= BURST_WRITE;
				local_write_req  <= 1'b1;
			end

            local_address    <= 27'd0;
        end

        BURST_WRITE:
        begin
			if(local_init_done & local_ready)begin
				local_write_req <= 1'b1;
			end
            
			if(local_init_done & local_ready & local_write_req)begin
				if(test_pat >= 3'd6)
					local_wdata <= local_wdata + 1'b1;
				local_state <= BURST_WRITE_B;
			end
        end
		
		BURST_WRITE_B: begin
			local_write_req  <= 1'b1;

			if(local_init_done & local_ready & local_write_req)begin
				if(local_address >= 27'h7FF_FFFE)begin
					local_state <= BURST_READ;
					local_address <= 27'd0;
				end else begin
					if(test_pat >= 3'd6)
						local_wdata <= local_wdata + 1'b1;
					local_address <= local_address + 2'd2;
					local_state <= BURST_WRITE;
				end
				
				local_write_req  <= 1'b0;
			end
		end
		
        BURST_READ:
        begin
		
			local_burstbegin <= 1'b1;
			local_read_req <= 1'b1;
		
            if(local_init_done & local_ready & local_read_req)begin
				if(local_address >= 27'h7FF_FFFE)begin
					local_state <= DONE;
					local_address <= 27'd0;
					local_burstbegin <= 1'b0;
					local_read_req <= 1'b0;
				end else begin
					local_address <= local_address + 2'd2;
				end
			end      
        end
		
		DONE: begin
			if(!local_rdata_valid)begin
				local_state <= IDLE;
				test_pat <= test_pat + 1'b1;
				case(test_pat)
					3'd0: begin match_cnt <= 16'h0000; local_wdata <= 16'h0000; end
					3'd1: begin match_cnt <= 16'hFFFF; local_wdata <= 16'hFFFF; end
					3'd2: begin match_cnt <= 16'h5A5A; local_wdata <= 16'h5A5A; end
					3'd3: begin match_cnt <= 16'hA5A5; local_wdata <= 16'hA5A5; end
					3'd4: begin match_cnt <= 16'h5555; local_wdata <= 16'h5555; end
					3'd5: begin match_cnt <= 16'hAAAA; local_wdata <= 16'hAAAA; end
					3'd6: begin match_cnt <= 16'h0000; local_wdata <= 16'h0000; end
					3'd7: begin match_cnt <= 16'h0000; local_wdata <= 16'h0000; end
				endcase
			end
		end
		
        endcase
	end

endmodule
