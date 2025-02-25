`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2018 08:37:20 AM
// Design Name: 
// Module Name: simTemplate
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
module simTemplate(
     );
    
     logic CLK=0,BTNL,BTNC,PS2Clk,PS2Data,VGA_HS,VGA_VS,Tx;
     logic [15:0] SWITCHES,LEDS;
     logic [7:0] CATHODES,VGA_RGB;
     logic [3:0] ANODES;
   
    OTTER_Wrapper DUT (.CLK (CLK),
                       .BTNL (BTNL),
                       .BTNC (BTNC),
                       .SWITCHES (SWITCHES),
                       .LEDS (LEDS),
                       .CATHODES (CATHODES),
                       .ANODES (ANODES)
                       );
                       
    reg [31:0] cycle_count = 0;

    initial forever  #10  CLK =  ! CLK; 
    
   always @ (posedge CLK) begin
        cycle_count <= cycle_count + 1;
   end
    
    initial begin
        BTNC=1;
        #100 
        BTNC=0;
        SWITCHES=15'd0;

      //$finish;
    end
    
    
       
  /*  initial begin
         if(ld_use_hazard)
            $display("%t -------> Stall ",$time);
        if(branch_taken)
            $display("%t -------> branch taken",$time); 
      end*/
endmodule
