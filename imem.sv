`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/26/2025 04:30:21 PM
// Design Name: 
// Module Name: imem
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


module imem(
 input  logic [31:0] a,
 output logic [31:0] w0,
 output logic [31:0] w1,
 output logic [31:0] w2,
 output logic [31:0] w3,
 output logic [31:0] w4,
 output logic [31:0] w5,
 output logic [31:0] w6,
 output logic [31:0] w7
);

//mem array
 logic [31:0] ram[0:16383];
 
 // Initialize mem from file
 initial $readmemh("Test_All.mem", ram, 0, 16383);
 
 //changed memory so it does output 8 words
 assign w0 = ram[a[31:2]];
 assign w1 = ram[a[31:2]+1];
 assign w2 = ram[a[31:2]+2];
 assign w3 = ram[a[31:2]+3];
 assign w4 = ram[a[31:2]+4];
 assign w5 = ram[a[31:2]+5];
 assign w6 = ram[a[31:2]+6];
 assign w7 = ram[a[31:2]+7];
endmodule

