`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2024 02:49:05 PM
// Design Name: 
// Module Name: srcA_mux
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


module mux2to1(
    input [31:0] in0,
    input [31:0] in1,
    input sel,
    output logic [31:0] out
    );
    
    always_comb begin
        case(sel)
            1'b0:
                out = in0;
            1'b1:
                out = in1;
            default:
                out = in0;
            endcase
    end
endmodule
