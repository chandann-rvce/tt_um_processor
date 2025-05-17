/*
 * Copyright (c) 2025 Shylashree N, Chandan N and Nischay B S
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_processor (
  input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    
     wire _unused = &{ena};
     
    // Assign Output Pins
    assign uio_oe  = 8'b00000000;
    assign uio_out[7:1] = 7'd0;

    // Input and Output of
    wire [15:0] inst;       // 16-bit instruction input

    // Connect pin to instruction
    assign inst [7:0]  = ui_in [7:0];    // Lower 8 bits are Input pins
    assign inst [15:8] = uio_in [7:0];   // Upper 8 bits are IO pins


    // Signal declarations
    wire [2:0] opcode;             // Opcode field of the instruction
    wire [2:0] rd, rs1, rs2;       // Destination and source registers
    wire [3:0] func;               // Function of the opcode
    wire [3:0] reg_data1;   // Data from register 1
    wire [3:0] reg_data2;   // Data from register 2
    wire [7:0] alu_result;  // ALU output result
    wire alu_zero;                 // ALU zero signal
    wire regwrite; // Write the ALU data to  register


    // Fields from the instruction
    assign opcode      = inst[2:0];
    assign func        = inst[6:3];
    assign reg2        = inst[9:7];
    assign reg1        = inst[12:10];
    assign regw        = inst[15:13];


    // ALU control signal based on func
    wire [3:0] alu_control;
    assign alu_control = func;
    assign regwrite = (opcode == 3'b011);

    // Instantiate the register file
    REG_FILE reg_file (
        .clk(clk),
        .rst_n(rst_n),
        .read_reg_num1(reg1),
        .read_reg_num2(reg2),
        .write_reg(regw),
        .regwrite(regwrite),
        .write_data(alu_result),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );

    // Instantiate the ALU
    ALU alu_block (
        .alu_control(alu_control),
        .in1(reg_data1),
        .in2(reg_data2),
        .alu_result(alu_result),
        .zero_flag(alu_zero)
    );

    // Connect output
    assign uo_out[7:0] = alu_result;
    assign uio_out[0] = alu_zero;
  

endmodule
//////////////////////////////////////////////////////////////////////////////////
// Arithmetic Logic Unit (ALU)
//////////////////////////////////////////////////////////////////////////////////
module ALU(
    input wire [3:0] in1,
    input wire  in2,
    input wire  alu_control,
    output reg [7:0] alu_result,
    output reg zero_flag
);
    always @(*) begin
        case(alu_control)
            4'b0000: alu_result = {4'b0000, in1 & in2};         // AND
            4'b0001: alu_result = {4'b0000, in1 | in2};         // OR
            4'b0010: alu_result = {4'b0000, in1 ^ in2};         // XOR
            4'b0011: alu_result = {4'b0000, ~(in1 & in2)};      // NAND
            4'b0100: alu_result = {4'b0000, ~(in1 | in2)};      // NOR
            4'b0101: alu_result = {4'b0000, ~(in1 ^ in2)};      // XNOR
            4'b0110: alu_result = {4'b0000, in1 + in2};          // ADD
            4'b0111: alu_result = {4'b0000, in1 - in2};          // SUBTRACT
            4'b1000: alu_result = in1 * in2;          // MULTIPLY
            4'b1001: alu_result = ({4'b0000, in2} != 0) ? {4'b0000, in1} / {4'b0000, in2} : 8'hFF; // DIVIDE
            4'b1010: alu_result = {4'b0000, in1 % in2};          // MODULUS
            4'b1011: alu_result = (in1 < in2) ? 8'b1 : 8'b0; // LESS THAN
            4'b1100: alu_result = (in1 > in2) ? 8'b1 : 8'b0; // GREATER THAN
            4'b1101: alu_result = (in1 == in2) ? 8'b1 : 8'b0; // EQUAL TO
            4'b1110: alu_result = {4'b0000, in1 << in2};         // SHIFT LEFT
            4'b1111: alu_result = {4'b0000, in1 >> in2};         // SHIFT RIGHT
            default: alu_result = 8'h00;
        endcase

        zero_flag = (alu_result == 8'b0) ? 1'b1 : 1'b0;
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Register File
//////////////////////////////////////////////////////////////////////////////////
module REG_FILE(
    input [2:0] read_reg_num1,
    input [2:0] read_reg_num2,
    input [2:0] write_reg,
    input [7:0] write_data,
    output reg [3:0] read_data1,
    output reg [3:0] read_data2,
    input regwrite,
    input clk,
    input rst_n
);
    reg [3:0] reg_memory [7:0]; // 8 registers, each 4 bits wide

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_memory[0] <= 4'd0;
            reg_memory[1] <= 4'd1;
            reg_memory[2] <= 4'd2;
            reg_memory[3] <= 4'd3;
            reg_memory[4] <= 4'd4;
            reg_memory[5] <= 4'd5;
            reg_memory[6] <= 4'd6;
            reg_memory[7] <= 4'd7;
        end else begin
            read_data1 <= reg_memory[read_reg_num1];
            read_data2 <= reg_memory[read_reg_num2];
            if (regwrite) begin
                {reg_memory[write_reg+1],reg_memory[write_reg]} <= write_data;
            end
        end
    end

endmodule
