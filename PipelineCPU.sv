`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  J. Callenes
// 
// Create Date: 01/04/2019 04:32:12 PM
// Design Name: 
// Module Name: PIPELINED_OTTER_CPU
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

  typedef enum logic [6:0] {
           LUI      = 7'b0110111,
           AUIPC    = 7'b0010111,
           JAL      = 7'b1101111,
           JALR     = 7'b1100111,
           BRANCH   = 7'b1100011,
           LOAD     = 7'b0000011,
           STORE    = 7'b0100011,
           OP_IMM   = 7'b0010011,
           OP       = 7'b0110011,
           SYSTEM   = 7'b1110011
 } opcode_t;
        
typedef struct packed{
    opcode_t opcode;
    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [4:0] rd_addr;
    logic rs1_used;
    logic rs2_used;
    logic rd_used;
    logic [3:0] alu_fun;
    logic memWrite;
    logic memRead2;
    logic regWrite;
    logic [1:0] rf_wr_sel;
    logic [2:0] mem_type;  //sign, size
    logic [31:0] pc;
    logic [31:0] pc_plus4;
} pipereg;


//typedef struct packed {
//    logic [31:0] rs1;
//    logic [31:0] alu_b_in;
//    logic [31:0] rs2;
//    logic [31:0] pc;
//    logic [31:0] pc_plus4;
//    logic [6:0] opcode;
//    logic [2:0] func3;
//    logic [1:0] sign;
//    logic size;
//    logic jump;
//    logic branch;
//    logic rf_write;
//    logic memWE2;
//    logic memRDEN2;
//    logic [3:0] alu_fun;
//    logic [1:0] rf_wr_sel;
//    logic [31:0] itype;
//    logic [31:0] btype;
//    logic [31:0] jtype;
//    logic [31:0] rd_addr;
//    logic [31:0] rs1_addr;
//    logic [31:0] rs2_addr;
//} de_ex_buffer;


module OTTER_MCU(input CLK,
                input INTR,
                input RESET,
                input [31:0] IOBUS_IN,
                output [31:0] IOBUS_OUT,
                output [31:0] IOBUS_ADDR,
                output logic IOBUS_WR 
);           

    wire [6:0] opcode;
    wire [31:0] pc, pc_value, next_pc, jalr_pc, branch_pc, jump_pc, int_pc,A,B,
        I_immed,S_immed,U_immed,
        aluBin,aluAin,aluResult,
        rfIn,
        csr_reg, mem_data;
    
    wire [31:0] IR;
    wire memRead1,memRead2;
    logic pcWrite;
    wire regWrite,memWrite, op1_sel,mem_op,IorD,pcWriteCond,memRead;
    wire [1:0] opB_sel, rf_sel, wb_sel, mSize;
    logic [1:0] pc_sel;
    wire [3:0]alu_fun;
    wire opA_sel;
    
    logic br_lt,br_eq,br_ltu;
    wire mem_RDEN2, mem_WE2;
    wire [31:0] mem_addr2, mem_dout2;
    
    logic ex_mem_memRDEN2, ex_mem_regWrite, ex_mem_memWE2; 
    
    logic br_eq, br_lt, br_ltu;
      
    logic [31:0] bag_branch, bag_jal, bag_jalr, forwarded_A, forwarded_B;
    logic [31:0] ex_mem_result, ex_forwarded_rs2, jalr_forwarded;
    
    logic de_ex_flushed;

    
    
//==== Instruction Fetch ===========================================
    wire [31:0] pc_mux_out;
    
    logic flush_de_ex, flush_if_de;
    logic stall;

     logic [31:0] if_de_pc;
     logic [31:0] if_de_pc_plus4;
     logic [31:0] if_de_ir;
     logic if_de_flushed, flush_next_if_de;
     
     assign if_de_ir = IR;
     
     
     always_ff @(posedge CLK) begin
                if (!stall) begin
                    if_de_pc <= pc;
                    if_de_pc_plus4 <= pc+4;
                end
                if (flush_next_if_de || flush_de_ex) if_de_flushed = 1;
                else if_de_flushed = 0;
     end
     
     always_ff @(posedge CLK) begin
        if (flush_if_de) flush_next_if_de = 1;
        else flush_next_if_de = 0;
     end
     
     
     assign pcWrite = ~stall; 	
     assign memRead1 = 1'b1; 	//Fetch new instruction every cycle
     
     
//==== Instruction Decode ===========================================
    
//    input w_en,
//    input [4:0] adr1,
//    input [4:0] adr2,
//    input [4:0] w_adr,
//    input [31:0] w_data,
//    input clk,
//    output logic [31:0] rs1,
//    output logic[31:0] rs2
    logic mem_wb_reg_write;
    logic [31:0] rf_write_rd_addr, mem_to_reg_mux_out;
    
    
    
    logic [31:0] de_ex_rs1, de_ex_rs2, de_ex_pc, de_ex_pc_plus4;
    
    wire [3:0] de_alu_fun;
    wire [1:0] de_alu_srca, de_rf_wr_sel;
    wire [2:0] de_alu_srcb;
   
    wire [31:0] rs1, rs2;
    
    logic [31:0] de_ex_itype, de_ex_btype, de_ex_jtype;
    wire [31:0] utype, itype, stype, btype;
    
    logic [31:0] jtype;
    
    assign utype = {if_de_ir[31:12],12'b0};
    assign itype = {{21{if_de_ir[31]}}, if_de_ir[30:20]};
    assign stype = {{21{if_de_ir[31]}},if_de_ir[30:25],if_de_ir[11:7]};
    assign btype = {{20{if_de_ir[31]}},if_de_ir[7],if_de_ir[30:25],if_de_ir[11:8],1'b0};
    assign jtype = {{12{if_de_ir[31]}},if_de_ir[19:12],if_de_ir[20],if_de_ir[30:21],1'b0};
    
    wire de_jump, de_branch, de_regWrite, de_memWE2, de_memRDEN2;
    logic de_ex_jump, de_ex_branch, de_ex_regWrite, de_ex_memWE2, de_ex_memRDEN2, de_store, de_ex_store;
    
    logic [3:0] de_ex_alu_fun;
    
    wire [1:0] de_rf_wr_sel;
    logic [1:0] de_ex_rf_wr_sel;
    
    wire [1:0] alu_srca_sel;
    wire [2:0] alu_srcb_sel;
    
    logic [6:0] de_ex_opcode;
    logic [4:0] mem_wb_rd_addr;
    
    CU_DCDR Decoder (
                    .ir_opcode_dcdr(if_de_ir[6:0]),
                    .ir_funct_dcdr(if_de_ir[14:12]),
                    .ir_30_dcdr(if_de_ir[30]),
                    .int_taken_dcdr(0),
                    .jump(de_jump),
                    .branch(de_branch),
                    .store(de_store),
                    .regWrite(de_regWrite),
                    .memWE2(de_memWE2),
                    .memRDEN2(de_memRDEN2),
                    .alu_fun_dcdr(de_alu_fun),
                    .alu_scra_dcdr(alu_srca_sel),
                    .alu_scrb_dcdr(alu_srcb_sel),
                    .rf_wr_sel_dcdr(de_rf_wr_sel)
                    );
    
    
    
    RegFile RegFile (
                    .w_en(mem_wb_reg_write),
                    .adr1(if_de_ir[19:15]),
                    .adr2(if_de_ir[24:20]),
                    .w_adr(mem_wb_rd_addr),
                    .w_data(mem_to_reg_mux_out),
                    .clk(CLK),
                    .rs1(rs1),
                    .rs2(rs2)
                    );
                    
    
    wire [31:0] de_used_rs1, de_used_rs2;
    logic imm_A, imm_B;
    
    
    mux2to1 DE_ALU_A_MUX (
                      .in0(rs1),
                      .in1(utype),
                      .sel(alu_srca_sel[0]),
                      .out(de_used_rs1)
                      );
                      
    mux4to1 DE_ALU_B_MUX (
                      .in0(rs2),
                      .in1(itype),
                      .in2(stype),
                      .in3(if_de_pc),
                      .sel(alu_srcb_sel[1:0]),
                      .out(de_used_rs2)
                      );
                    
    logic [31:0] de_ex_opA;
    logic [31:0] de_ex_opB;
    logic [31:0] de_ex_rs2;
    
    // Instatiate decode_execute buffer
    pipereg de_ex_buffer;
    
    pipereg if_de_buffer;
    
    // Instantiate opcode structure
    opcode_t OPCODE;
    assign OPCODE_t = opcode_t'(opcode);
    
   // de_ex de_ex_buffer;
   
//    assign de_ex_buffer.rs1_addr=if_de_ir[19:15];
//    assign de_inst.rs2_addr=if_de_ir[24:20];
//    assign de_inst.rd_addr=if_de_ir[11:7];


//    assign de_inst.opcode=OPCODE;
   
//    assign de_inst.rs1_used=    de_inst.rs1_addr != 0
//                                && de_inst.opcode != LUI
//                                && de_inst.opcode != AUIPC
//                                && de_inst.opcode != JAL;
                                
    logic [31:0] de_ex_utype, de_ex_itype, de_ex_stype, de_ex_btype, de_ex_jtype, de_ex_alu_b;
    logic [2:0] de_ex_func3;
    logic [4:0] de_ex_rs1_addr, de_ex_rs2_addr, de_ex_rd_addr;
    logic [4:0] ex_mem_rd_addr;

    logic [1:0] de_ex_size, forward_A_SEL, forward_B_SEL;
    logic de_ex_sign, jal_taken, jalr_taken, branch_taken, de_load, de_ex_load, ex_mem_load;
    
    /////// PUT THIS IN THE DECODE STAGE AT THE END FOR UNCONDITIONAL JUMP
    always_comb begin
          de_load = 0;
          branch_taken = 0;
          
          if (if_de_ir[6:0] == 7'b0000011) de_load = 1;
   
          if (de_ex_branch && !de_ex_flushed) begin
          // Not jump instruction (branch instead)
            begin
              case (de_ex_func3)
              // BEQ
              3'b000: begin
                 branch_taken = forwarded_A == forwarded_B ? 1 : 0;
              end
              
              // BNE
              3'b001: begin
                branch_taken = forwarded_A == forwarded_B ? 0 : 1;
              end
              
              // BLT
              3'b100: begin
                branch_taken = $signed(forwarded_A) < $signed(forwarded_B) ? 1 : 0;
              end
              
              // BGE
              3'b101: begin
                branch_taken = $signed(forwarded_A) < $signed(forwarded_B) ? 0 : 1;
              end
              
              // BLTU
              3'b110: begin
                branch_taken = forwarded_A < forwarded_B ? 1 : 0;
              end
              
              // BGEU
              3'b111: begin
                branch_taken = forwarded_A < forwarded_B ? 0 : 1;
              end
              
              default: begin
                branch_taken = 0;
              end
              endcase
              
          end
          end
    end
    
    always_comb begin
    jal_taken = 0;
    jalr_taken = 0;
    
    if (de_jump == 1 && !flush_next_if_de) begin
             if (if_de_ir[6:0] == 7'b1101111) begin
             // JAL opcode
                jal_taken = 1;
             end else begin
             // JALR
                jalr_taken = 1;
             end
         end
    end
    
    logic [1:0] forward_rs2, jalr_sel;
    
    
    HazardUnit HazardUnit(
               .rs1_in(de_ex_rs1_addr),
               .rs2_in(de_ex_rs2_addr),
               .de_rd(de_ex_rd_addr),
               .de_rd_reg_write(de_ex_regWrite),
               .ex_rd(ex_mem_rd_addr),
               .ex_rd_reg_write(ex_mem_regWrite),
               .mem_rd(mem_wb_rd_addr),
               .mem_rd_reg_write(mem_wb_reg_write),
               .load(ex_mem_load),
               .jal_taken(jal_taken),
               .jalr_taken(jalr_taken),
               .branch(branch_taken),
               .store(de_ex_store),
               .forward_rs2(forward_rs2),
               .imm_A(imm_A),
               .imm_B(imm_B),
               .pc_mux_out(pc_sel),
               .de_rs1_jalr(if_de_ir[19:15]),
               .jalr_sel(jalr_sel),
               .flush_if_de(flush_if_de),
               .flush_de_ex(flush_de_ex),
               .stall(stall),
               .alu_sel_1(forward_A_SEL),
               .alu_sel_2(forward_B_SEL)
    );
    
    
    always_ff @(posedge CLK) begin
        
            // Assign used values
            de_ex_rs1_addr <= if_de_ir[19:15];
            de_ex_rs1 <= de_used_rs1;
            de_ex_alu_b <= de_used_rs2;
            de_ex_rs2 <= rs2;
            de_ex_rs2_addr <= if_de_ir[24:20];
            de_ex_pc <= if_de_pc;
            de_ex_pc_plus4 <= if_de_pc_plus4;
            de_ex_opcode <= if_de_ir[6:0];
            de_ex_func3 <= if_de_ir[14:12];
            de_ex_sign <= if_de_ir[14];
            de_ex_size <= if_de_ir[13:12];
            de_ex_load <= de_load;
            de_ex_store <= de_store;
            if (alu_srca_sel != 0) imm_A <= 1;
            else imm_A <= 0;
            
            if (alu_srcb_sel != 0) imm_B <= 1;
            else imm_B <= 0;
            
            // Assign control values
            de_ex_branch <= de_branch;
            if (if_de_flushed) begin
                de_ex_regWrite <= 0;
                de_ex_memWE2 <= 0;
                de_ex_flushed <= 1;
            end
            else begin
                de_ex_regWrite <= de_regWrite;
                de_ex_memWE2 <= de_memWE2;
                de_ex_flushed <= 0;
            end
            de_ex_memRDEN2 <= de_memRDEN2;
            de_ex_alu_fun <= de_alu_fun;
            de_ex_rf_wr_sel <= de_rf_wr_sel;
            
            // Assign immediate values in DE_EX buffer
            de_ex_itype <= itype;
            de_ex_btype <= btype;
            de_ex_jtype <= jtype;
            
            // Assign register addresses
            de_ex_rd_addr <= if_de_ir[11:7];
        
        
    end
     
    
	
	
//==== Execute ======================================================
     logic [31:0] ex_mem_rs2;
     logic ex_mem_aluRes = 0;
     logic [31:0] opA_forwarded;
     logic [31:0] opB_forwarded;
     
     wire ex_jump;
     assign ex_jump = de_ex_jump;
     // BRANCH CONDITIONAL GENERATOR
//    input [31:0] rs1,
//    input [31:0] rs2,
//    output br_eq,
//    output br_lt,
//    output br_ltu
//    );
//    assign br_eq = rs1==rs2;
//    assign br_lt = $signed(rs1)<$signed(rs2);
//    assign br_ltu = rs1 < rs2;


    BRANCH_ADDR_GEN BAG (
                   .J_TYPE_IMM(jtype),
                   .B_TYPE_IMM(de_ex_btype),
                   .I_TYPE_IMM(itype), // Immediately decoded
                   .rs1(jalr_forwarded),
                   .PC_B(de_ex_pc),
                   .PC_J(if_de_pc),
                   .branch(bag_branch),
                   .jal(bag_jal),
                   .jalr(bag_jalr)
                   );
                   
    mux4to1 JALR_forward (
                    .in0(rs1),
                    .in1(ex_result),
                    .in2(ex_mem_result),
                    .in3(mem_to_reg_mux_out),
                    .sel(jalr_sel),
                    .out(jalr_forwarded)
                    );

    mux4to1 PC_MUX (.in0 (pc+4),
                    .in1 (bag_jalr),
                    .in2 (bag_branch),
                    .in3 (bag_jal),
                    .sel (pc_sel),
                    .out (pc_mux_out)
                    );
                    
    mux4to1 ALU_forward_A (
                    .in0 (de_ex_rs1),
                    .in1 (ex_mem_result),
                    .in2 (mem_to_reg_mux_out),
                    .in3 (0),
                    .sel (forward_A_SEL),
                    .out (forwarded_A)
                    );
    
    mux4to1 ALU_forward_B (
                    .in0 (de_ex_alu_b),
                    .in1 (ex_mem_result),
                    .in2 (mem_to_reg_mux_out),
                    .in3 (0),
                    .sel (forward_B_SEL),
                    .out (forwarded_B)
                    );
                    
    mux4to1 MEM_forward_rs2 (
                    .in0 (de_ex_rs2),
                    .in1 (ex_mem_result),
                    .in2 (mem_to_reg_mux_out),
                    .in3 (0),
                    .sel (forward_rs2),
                    .out (ex_forwarded_rs2)
                    );

    PC PC_mod (
           .PC_RST(RESET),
           .PC_WE(pcWrite), 
           .PC_DIN(pc_mux_out),
           .CLK(CLK), 
           .PC_COUNT(pc)
           );

     
//    input [31:0] srcA,
//    input [31:0] srcB,
//    input [3:0] alu_fun,
//    output logic [31:0] alu_result
    wire [31:0] ex_result;
    logic [1:0] ex_mem_rf_wr_sel;
    logic [31:0] ex_mem_pc_plus4;
    
    ALU ALU (
            .srcA(forwarded_A),
            .srcB(forwarded_B),
            .alu_fun(de_ex_alu_fun),
            .alu_result(ex_result)
        ); // the ALU
        
     
    logic [1:0] ex_mem_size;
    logic ex_mem_sign;
    logic [31:0] ex_mem_rs2;
    
    always_ff @(posedge CLK) begin
        ex_mem_result <= ex_result;
        ex_mem_rs2 <= ex_forwarded_rs2;
        ex_mem_load <= de_ex_load;
        
        ex_mem_memRDEN2 <= de_ex_memRDEN2;
        ex_mem_regWrite <= de_ex_regWrite;
        ex_mem_rf_wr_sel <= de_ex_rf_wr_sel;
        ex_mem_memWE2 <= de_ex_memWE2;
        
        ex_mem_size <= de_ex_size;
        ex_mem_sign <= de_ex_sign;
        
        ex_mem_pc_plus4 <= de_ex_pc;
        ex_mem_rd_addr <= de_ex_rd_addr;
        
    end



//==== Memory ======================================================
     
//    wire mem_RDEN2, mem_WE2;
//    wire [31:0] mem_addr2, mem_dout2;
    assign mem_RDEN2 = ex_mem_memRDEN2;
    assign mem_WE2 = ex_mem_memWE2;
    assign mem_addr2 = ex_mem_result;
    
    logic [31:0] mem_wb_dout2, mem_wb_pc_plus4, mem_wb_result;
    
    logic [1:0] mem_wb_rf_wr_sel;
    logic mem_wb_regWrite;
    
    wire [1:0] size;
    wire sign;
    
    assign size = ex_mem_size;
    assign sign = ex_mem_sign;
    
    // OTTER_mem_dualport(MEM_CLK,MEM_ADDR1,MEM_ADDR2,MEM_DIN2,MEM_WRITE2,MEM_READ1,MEM_READ2,ERR,MEM_DOUT1,MEM_DOUT2,IO_IN,IO_WR);
    OTTER_mem_byte Mem(
                .MEM_CLK(CLK),
                .MEM_ADDR1(pc),
                .MEM_ADDR2(mem_addr2),
                .MEM_DIN2(ex_mem_rs2),
                .MEM_WRITE2(mem_WE2),
                .MEM_READ1(memRead1),
                .MEM_READ2(mem_RDEN2),
                .MEM_DOUT1(IR),
                .MEM_DOUT2(mem_dout2),
                .IO_IN(IOBUS_IN),
                .IO_WR(IOBUS_WR),
                .MEM_SIZE(size),
                .MEM_SIGN(sign)
                );
    
//    Memory Mem (.MEM_CLK(CLK),
//                .MEM_RDEN1(memRead1),
//                .MEM_RDEN2(mem_RDEN2),
//                .MEM_WE2(mem_WE2),
//                .MEM_DIN2(ex_mem_rs2),
//                .MEM_ADDR1(pc[15:2]),
//                .MEM_ADDR2(mem_addr2),
//                .MEM_SIZE(size),
//                .MEM_SIGN(sign),
//                .IO_IN(IOBUS_IN),
//                .IO_WR(IOBUS_WR),
//                .MEM_DOUT1(IR),
//                .MEM_DOUT2(mem_dout2)
//                );
        
    assign IOBUS_ADDR = ex_mem_result;
    assign IOBUS_OUT = ex_mem_rs2;
    assign mem_wb_dout2 = mem_dout2;
    
    always_ff @(posedge CLK) begin
        mem_wb_rd_addr <= ex_mem_rd_addr;
        mem_wb_pc_plus4 <= ex_mem_pc_plus4;
        mem_wb_result <= ex_mem_result;
        
        mem_wb_rf_wr_sel <= ex_mem_rf_wr_sel;
        mem_wb_regWrite <= ex_mem_regWrite;
        
    end
 
     
//==== Write Back ==================================================
    
    mux4to1 RF_WRITE_MUX (
               .in0(ex_mem_pc_plus4),
               .in1(0),
               .in2(mem_wb_dout2),
               .in3(mem_wb_result),
               .sel(mem_wb_rf_wr_sel),
               .out(mem_to_reg_mux_out)
               );
               
    assign rf_write_rd_addr = mem_wb_rd_addr;
    assign mem_wb_reg_write = mem_wb_regWrite;

 
 

       
            
endmodule
