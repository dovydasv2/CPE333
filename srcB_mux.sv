`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2024 02:49:05 PM
// Design Name: 
// Module Name: srcB_mux
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


module mux4to1(
    input [1:0] sel,
    input [31:0] in0,
    input [31:0] in1,
    input [31:0] in2,
    input [31:0] in3,
    output logic [31:0] out
    );
    always_comb begin
        case(sel)
            2'b00:
                out = in0;
            2'b01:
                out = in1;
            2'b10:
                out = in2;
            2'b11:
                out = in3;
            default:
                out = in0;
        endcase
    end
endmodule
