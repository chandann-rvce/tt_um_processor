`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
   
  tt_um_example processor (

     // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(1'b1),
      .VGND(1'b0),
`endif
      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

  
    initial begin
        clk = 0;
        forever #20 clk = ~clk;
    end

    initial begin
        rst_n = 0; // Reset the processor
        #50 rst_n = 1;
        #40 ui_in = 4'b0000; uio_in = 4'b0000;
        #40 ui_in = 4'b0000; uio_in = 4'b0001;
        #40 ui_in = 4'b0000; uio_in = 4'b0010;
        #40 ui_in = 4'b0000; uio_in = 4'b0011;
        #40 ui_in = 4'b0000; uio_in = 4'b0100;
        #40 ui_in = 4'b0000; uio_in = 4'b0101;
        #40 ui_in = 4'b0000; uio_in = 4'b0110;
        #40 ui_in = 4'b0000; uio_in = 4'b0111;
        #40 ui_in = 4'b0000; uio_in = 4'b1000;
        #40 ui_in = 4'b0000; uio_in = 4'b1001;
        #40 ui_in = 4'b0000; uio_in = 4'b1010;
        #40 ui_in = 4'b0000; uio_in = 4'b1011;
        #40 ui_in = 4'b0000; uio_in = 4'b1100;
        #40 ui_in = 4'b0000; uio_in = 4'b1101;
        #40 ui_in = 4'b0000; uio_in = 4'b1110;
        #40 ui_in = 4'b0000; uio_in = 4'b1111;
        ////////////////////////////////
        #40 uio_in = 4'b0000; ui_in = 4'b0000;
        #40 uio_in = 4'b0000; ui_in = 4'b0001;
        #40 uio_in = 4'b0000; ui_in = 4'b0010;
        #40 uio_in = 4'b0000; ui_in = 4'b0011;
        #40 uio_in = 4'b0000; ui_in = 4'b0100;
        #40 uio_in = 4'b0000; ui_in = 4'b0101;
        #40 uio_in = 4'b0000; ui_in = 4'b0110;
        #40 uio_in = 4'b0000; ui_in = 4'b0111;
        #40 uio_in = 4'b0000; ui_in = 4'b1000;
        #40 uio_in = 4'b0000; ui_in = 4'b1001;
        #40 uio_in = 4'b0000; ui_in = 4'b1010;
        #40 uio_in = 4'b0000; ui_in = 4'b1011;
        #40 uio_in = 4'b0000; ui_in = 4'b1100;
        #40 uio_in = 4'b0000; ui_in = 4'b1101;
        #40 uio_in = 4'b0000; ui_in = 4'b1110;
        #40 uio_in = 4'b0000; ui_in = 4'b1111;
    end
   
    initial
       #800 $finish;
    
    initial begin
       $monitor("Time=%0d | ui_in=%b, uio_in=%b | uo_out=%b", $time, ui_in, uio_in, uo_out);
    end
endmodule
