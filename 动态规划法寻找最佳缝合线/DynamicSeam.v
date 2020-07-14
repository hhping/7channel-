`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/11 09:09:30
// Design Name: 
// Module Name: DynamicSeam
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
/*
�ⲿ�ִ��벻����
*/
module DynamicSeam
	#(parameter[31:0] WIDTH = 1100, parameter[31:0] HEIGHT = 1100, parameter[31:0] OVERLAPWIDTH = 300, parameter[31:0] OVERLAPHEIGHT = 1100)
	(input rst_n, input clk_p, input clk_n, input read_request);
	
//�ڲ��������ÿ��ʱ�����ڶ�ȡһ������
//������������
reg [31:0] row1 [OVERLAPWIDTH : 0];
reg [31:0] row2 [OVERLAPWIDTH : 0];
reg [31:0] cost [OVERLAPWIDTH : 0];
reg [31:0] coordinate [OVERLAPWIDTH : 0];
reg [31:0] cnt = 0;  //�Լ����������ݸü���������״̬ת��  

wire sys_clk;
//200MHz�Ĳ��ʱ��
  clk_wiz_0 instance_name
   (
    // Clock out ports
    .clk_out1(sys_clk),     // output clk_out1
    // Status and control signals
    .reset(rst_n), // input reset   //��λ�ź�
    .locked(),       // output locked
   // Clock in ports
    .clk_in1_p(cl_p),    // input clk_in1_p
    .clk_in1_n(clk_n));    // input clk_in1_n

//ͨ��ddr3��ȡ���ݴ�������л�����
//ddr3ģ��
//�������״̬��idle��read
reg [1:0] cstate;
reg [1:0] nstate;
parameter IDLE = 0;
parameter READ = 1;
parameter SeamFind = 2;
parameter row = 0;
parameter col = 0;
parameter read_col = 0;
//parameter 
//ddr3�е��û��ӿ��ź�
localparam nCK_PER_CLK           = 4;
localparam DQ_WIDTH              = 64;
localparam ADDR_WIDTH            = 29;
localparam DATA_WIDTH            = 64;
localparam PAYLOAD_WIDTH         = 64;

localparam APP_DATA_WIDTH        = 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
localparam APP_MASK_WIDTH        = APP_DATA_WIDTH / 8;
 wire init_calib_complete;

  wire [ADDR_WIDTH-1:0]                 app_addr;
  wire [2:0]                            app_cmd;
  wire                                  app_en;
  wire                                  app_rdy;
  wire [APP_DATA_WIDTH-1:0]             app_rd_data;
  wire                                  app_rd_data_end;
  wire                                  app_rd_data_valid;
  wire [APP_DATA_WIDTH-1:0]             app_wdf_data;
  wire                                  app_wdf_end;
  wire [APP_MASK_WIDTH-1:0]             app_wdf_mask;
  wire                                  app_wdf_rdy;
  wire                                  app_sr_active;
  wire                                  app_ref_ack;
  wire                                  app_zq_ack;
  wire                                  app_wdf_wren;

  wire                                  clk;
  wire                                  rst;
//��һ��״̬
always@(posedge sys_clk or negedge rst_n)
	begin
		if(!rst_n)   //�͵�ƽ��λ
			cstate <= IDLE;
		else
			cstate <= nstate;
	end
//�ڶ���״̬
always@(*)  
	begin
		case(cstate)
				IDLE: 
					if(read_request == 1)
						nstate <= READ;
					else
						nstate <= IDLE;
				READ:
					if(cnt == OVERLAPWIDTH * 2)
						nstate <= SeamFind;
					else
						nstate <= READ;
				SeamFind:
					if(cnt == OVERLAPWIDTH)
						nstate <= IDLE;
					else
						nstate <= SeamFind;
		endcase
	end
//������״̬
//��cnt�Ŀ���
always@(posedge sys_clk)  //��ʱ������ddr3�ṩ�Ĺ��û�ʹ�õ�ʱ�ӣ�200MHz
	begin
		case(cstate)
			IDLE:
				cnt <= 0;
			READ:
				if(cnt == 2 * OVERLAPWIDTH)
					cnt <= 0;
				else
					cnt <= cnt + 1'b1;
			SeamFind:
				if(cnt == OVERLAPWIDTH)
					cnt <= 0;
				else
					cnt <= cnt + 1'b1;
		endcase
	end
//�Ի������еĿ���
always@(posedge sys_clk)
	begin
		case(cstate)
			IDLE: row <= 0;
			READ: row <= 0;
			SeamFind: 
				begin
					if(row == OVERLAPHEIGHT)
						row <= 0;
					else
						row <= row + 1'b1;
				end
			endcase
	end
//�Ի����е��н��п��ƣ��Ը���coordinate��cost
always@(posedge sys_clk)
	begin 
		case(cstate)
			IDLE : col <= 0;
			READ: col <= 0;
			SeamFind :
				begin
					if(col < OVERLAPWIDTH)
						col <= col + 1'b1;
					else
						col <= 0;
				end
		endcase
	end
//��read_col���п��ƣ�����ȷ��ȡ����
always@(posedge sys_clk)
	begin
		case(cstate)
			IDLE: read_col <= 0;
			READ: 
				begin 
					if(read_col == OVERLAPWIDTH)
						read_col <= 0;
					else
						read_col <= read_col + 1'b1;
				end
		endcase
	end
		
//����������Ŀ���
always@(posedge sys_clk)
	begin
	//���ɵ�ַ
		case(cstate)
			IDLE:
				app_addr <= 29'b0;  //
			READ:
				begin
						mig_7series_0 u_mig_7series_0 (
						// Memory interface ports
						.ddr3_addr                      (ddr3_addr),  // output [14:0]		ddr3_addr
						`     (ddr3_ck_n),  // output [0:0]		ddr3_ck_n
						.ddr3_ck_p                      (ddr3_ck_p),  // output [0:0]		ddr3_ck_p
						.ddr3_cke                       (ddr3_cke),  // output [0:0]		ddr3_cke
						.ddr3_ras_n                     (ddr3_ras_n),  // output			ddr3_ras_n
						.ddr3_reset_n                   (ddr3_reset_n),  // output			ddr3_reset_n
						.ddr3_we_n                      (ddr3_we_n),  // output			ddr3_we_n
						.ddr3_dq                        (ddr3_dq),  // inout [63:0]		ddr3_dq
						.ddr3_dqs_n                     (ddr3_dqs_n),  // inout [7:0]		ddr3_dqs_n
						.ddr3_dqs_p                     (ddr3_dqs_p),  // inout [7:0]		ddr3_dqs_p
						.init_calib_complete            (init_calib_complete),  // output			init_calib_complete
						.ddr3_cs_n                      (ddr3_cs_n),  // output [0:0]		ddr3_cs_n
						.ddr3_dm                        (ddr3_dm),  // output [7:0]		ddr3_dm
						.ddr3_odt                       (ddr3_odt),  // output [0:0]		ddr3_od
						// Application interface ports
						.app_addr                       (app_addr),  // input [28:0]		app_addr
						.app_cmd                        (app_cmd),  // input [2:0]		app_cmd
						.app_en                         (app_en),  // input				app_en
						.app_wdf_data                   (app_wdf_data),  // input [511:0]		app_wdf_data
						.app_wdf_end                    (app_wdf_end),  // input				app_wdf_end
						.app_wdf_wren                   (app_wdf_wren),  // input				app_wdf_wren
						.app_rd_data                    (app_rd_data),  // output [511:0]		app_rd_data
						.app_rd_data_end                (app_rd_data_end),  // output			app_rd_data_end
						.app_rd_data_valid              (app_rd_data_valid),  // output			app_rd_data_valid
						.app_rdy                        (app_rdy),  // output			app_rdy
						.app_wdf_rdy                    (app_wdf_rdy),  // output			app_wdf_rdy
						.app_sr_req                     (app_sr_req),  // input			app_sr_req
						.app_ref_req                    (app_ref_req),  // input			app_ref_req
						.app_zq_req                     (app_zq_req),  // input			app_zq_req
						.app_sr_active                  (app_sr_active),  // output			app_sr_active
						.app_ref_ack                    (app_ref_ack),  // output			app_ref_ack
						.app_zq_ack                     (app_zq_ack),  // output			app_zq_ack
						.ui_clk                         (ui_clk),  // output			ui_clk
						.ui_clk_sync_rst                (ui_clk_sync_rst),  // output			ui_clk_sync_rs
						.app_wdf_mask                   (app_wdf_mask),  // input [63:0]		app_wdf_mask
						// System Clock Ports
						.sys_clk_i                       (sys_clk),
						.sys_rst                        (sys_rst) // input sys_rst
						);
					//����cnt������ŵĻ���λ��
					if(cnt <= OVERLAPWIDTH)
						begin
							row1[read_col] = app_rd_data;
						end
					else 
						begin
							row2[read_col] = app_rd_data;
						end
				end
			SeamFind:
				begin
					//�Ƚ�������������cost[col],��coordinate[col]
					if(cnt < OVERLAPWIDTH)
						begin
							localparam index = coordinate[col];
							localparam min <= row2[index];
							coordinate[col] <= index;
							if(col > 0 && min < row2[index - 1])
								begin
									min <= row2[index - 1];
									coordinate[index] <= index - 1;
								end
							if(col < OVERLAPWIDTH && min < row2[index + 1])
								begin
									min <= row2[index + 1];
									coordinate[index] <= index + 1;
								end
							cost[col] = cost[col] + min;
						end
				end
		endcase
	end
				
	
//�������е���������ʱ�����Կ�ʼѰ����ѷ������
	


endmodule