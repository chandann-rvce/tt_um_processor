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

    ////////////////////////////////////////////
    // Define Processor IOs
    ////////////////////////////////////////////
    wire [3:0] IN1, IN2;
    wire [7:0] OUT;
    wire zero;
    wire reset;
    
    ////////////////////////////////////////////
    // Assign Processor IOs to pins
    ////////////////////////////////////////////

    assign IN1 = ui_in[3:0]; // 4-bit Input 01
    assign IN2 = uio_in[3:0]; // 4-bit Input 02
    assign reset = rst_n; // reset active low
    assign uio_oe = 8'b0;  // Assuming uio is always input in this context
    assign uio_out [7:1] = 7'b0; // Assign remaining bits to zero
    wire _unused = &{ena};
    
    ////////////////////////////////////////////
    // Processor program starts from here
    ////////////////////////////////////////////

    wire [15:0] instruction_code;
    wire [3:0] alu_control;
    wire regwrite;

    // Instantiate IFU module
    IFU IFU_module(
        .clk(clk),
        .reset(reset),
        .instruction_code(instruction_code)
    );

    // Instantiate CONTROL module
    CONTROL control_module(
        .func(instruction_code[6:3]),
        .opcode(instruction_code[2:0]),
        .alu_control(alu_control),
        .regwrite_control(regwrite)
    );

    // Instantiate DATAPATH module
    DATAPATH datapath_module(
        .IN1(IN1),
        .IN2(IN2),
        .read_reg_num1(instruction_code[15:13]),
        .read_reg_num2(instruction_code[12:10]),
        .write_reg(instruction_code[9:7]),
        .alu_control(alu_control),
        .regwrite(regwrite),
        .clk(clk),
        .reset(reset),
        .write_data(OUT),
        .zero_flag(zero)
    );
    

    ///////////////////////////////////////////////////
    // Assign output signal   
    ///////////////////////////////////////////////////
    assign uo_out = OUT // 7-bit Output
    assign uio_out[0] = zero; // Zero flag
   
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Instruction Fetch Unit (IFU)
//////////////////////////////////////////////////////////////////////////////////
module IFU(
    input clk,
    input reset,
    output reg [15:0] instruction_code
);
    reg [15:0] PC; // Program Counter
    reg [7:0] Memory [0:31]; // 32 bytes memory

    always @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 16'b0;
        else
            PC <= PC + 2;
    end

    always @(posedge clk) begin
        instruction_code <= {Memory[PC+1], Memory[PC]};
    end

    // Initialize Memory
    initial begin
        Memory[0] = 8'h03; Memory[1] = 8'h05; // Example: AND instruction
        Memory[2] = 8'h0B; Memory[3] = 8'h05; // Example: OR instruction
        // Load more instructions as needed
    end

endmodule

//////////////////////////////////////////////////////////////////////////////////
// Control Unit
//////////////////////////////////////////////////////////////////////////////////
module CONTROL(
    input [3:0] func,
    input [2:0] opcode,
    output reg [3:0] alu_control,
    output reg regwrite_control
);
    always @(*) begin
        if (opcode == 3'b011) begin // ALU operations
            regwrite_control = 1'b1;
            case (func)
                4'b0000: alu_control = 4'b0000; // AND
                4'b0001: alu_control = 4'b0001; // OR
                4'b0010: alu_control = 4'b0010; // XOR
                4'b0011: alu_control = 4'b0011; // NAND
                4'b0100: alu_control = 4'b0100; // NOR
                4'b0101: alu_control = 4'b0101; // XNOR
                4'b0110: alu_control = 4'b0110; // ADD
                4'b0111: alu_control = 4'b0111; // SUBTRACT
                4'b1000: alu_control = 4'b1000; // MULTIPLY
                4'b1001: alu_control = 4'b1001; // DIVIDE
                4'b1010: alu_control = 4'b1010; // MODULUS
                4'b1011: alu_control = 4'b1011; // LESS THAN
                4'b1100: alu_control = 4'b1100; // GREATER THAN
                4'b1101: alu_control = 4'b1101; // EQUAL TO
                4'b1110: alu_control = 4'b1110; // SHIFT LEFT
                4'b1111: alu_control = 4'b1111; // SHIFT RIGHT
                default: alu_control = 4'b0000;
            endcase
        end else begin
            alu_control = 4'b0000;
            regwrite_control = 1'b0;
        end
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Arithmetic Logic Unit (ALU)
//////////////////////////////////////////////////////////////////////////////////
module ALU(
    input [3:0] in1,
    input [3:0] in2,
    input [3:0] alu_control,
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
    input reset
);
    reg [3:0] reg_memory [7:0]; // 8 registers, each 4 bits wide

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_memory[0] <= 4'b0;
            reg_memory[1] <= 4'b0;
            reg_memory[2] <= 4'b0;
            reg_memory[3] <= 4'b0;
            reg_memory[4] <= 4'b0;
            reg_memory[5] <= 4'b0;
            reg_memory[6] <= 4'b0;
            reg_memory[7] <= 4'b0;
        end else begin
            read_data1 <= reg_memory[read_reg_num1];
            read_data2 <= reg_memory[read_reg_num2];
            if (regwrite) begin
                {reg_memory[write_reg+1],reg_memory[write_reg]} <= write_data;
            end
        end
    end

endmodule

//////////////////////////////////////////////////////////////////////////////////
// DataPath
//////////////////////////////////////////////////////////////////////////////////
module DATAPATH(
    input [3:0] IN1,
    input [3:0] IN2,
    input [2:0] read_reg_num1,
    input [2:0] read_reg_num2,
    input [2:0] write_reg,
    input [3:0] alu_control,
    input regwrite,
    input clk,
    input reset,
    output [7:0] write_data,
    output zero_flag
);
    reg [3:0] reg_read_data1;
    reg [3:0] reg_read_data2;
    wire [7:0] alu_result;
    wire zero;

    REG_FILE reg_file_module(
        .read_reg_num1(read_reg_num1),
        .read_reg_num2(read_reg_num2),
        .write_reg(write_reg),
        .write_data(alu_result),
        .read_data1(reg_read_data1),
        .read_data2(reg_read_data2),
        .regwrite(regwrite),
        .clk(clk),
        .reset(reset)
    );

    ALU alu_module(
        .in1(IN1),
        .in2(IN2),
        .alu_control(alu_control),
        .alu_result(alu_result),
        .zero_flag(zero)
    );

    assign write_data = alu_result;
    assign zero_flag = zero;

endmodule
