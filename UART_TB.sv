`include "defines.v"

module UART_TB ();
  parameter c_CLOCK_PERIOD_NS = 40;
  parameter c_CLKS_PER_BIT= 217;    
  parameter c_BIT_PERIOD= 8680;     
  reg Clock = 0;
  reg reset_n = 0;

  always #(c_CLOCK_PERIOD_NS/2) Clock <= ~Clock;

`ifdef UART_TX_ONLY
 
  wire Tx_Done;
  reg Tx_Ready = 0;
  wire Tx_Active;
  wire Tx_Data;
  reg [7:0] Tx_Byte = 0;
  
  uart_controller #(.CLOCK_RATE(25000000), .BAUD_RATE(115200)) xUART_TX (
    .clk (Clock),
    .reset_n (reset_n),
    .i_Tx_Ready (Tx_Ready),
    .i_Tx_Byte (Tx_Byte),
    .o_Tx_Active (Tx_Active),
    .o_Tx_Data (Tx_Data),
    .o_Tx_Done (Tx_Done)
  );

  initial begin
    reset_n = 0;
    repeat(5) @(posedge Clock);
    reset_n = 1;


    @(posedge Clock);
    Tx_Byte = 8'b01010101;
    Tx_Ready = 1;
    @(posedge Clock);
    Tx_Ready = 0;

    #100000;
    $finish();
  end

`elsif UART_RX_ONLY
 
  wire [7:0] Rx_Byte;
  reg        UART_Rx = 1;
  wire       Rx_Done;
  reg [7:0]  DataToSend_RX = 8'b01010101;
  integer    i;


  uart_controller #(.CLOCK_RATE(25000000), .BAUD_RATE(115200), .RX_OVERSAMPLE(16)) xUART_RX (
    .clk         (Clock),
    .reset_n     (reset_n),
    .i_Rx_Data   (UART_Rx),
    .o_Rx_Done   (Rx_Done),
    .o_Rx_Byte   (Rx_Byte)
  );

  initial begin
  
    reset_n = 0;
    repeat(5) @(posedge Clock);
    reset_n = 1;

    #(c_BIT_PERIOD);

    UART_Rx = 0;
    #(c_BIT_PERIOD);

    for (i = 0; i < 8; i = i + 1) begin
      UART_Rx = DataToSend_RX[i];
      #(c_BIT_PERIOD);
    end

    UART_Rx = 1;
    #(c_BIT_PERIOD);

    #20000;
    $finish();
  end

`else

  wire Rx_Done;
  wire [7:0] Rx_Byte;
  reg  [7:0] Tx_Byte = 0;
  reg Tx_Ready = 0;
  wire Tx_Data;


  wire UART_Line = Tx_Data;
  wire UART_Rx = UART_Line;

  reg [7:0] DataToSend[0:7]     = {8'h01, 8'h10, 8'h22, 8'h32, 8'h55, 8'hAA, 8'hAB, 8'h88};
  reg [7:0] DataReceived[0:7];
  integer ii;

 
  uart_controller #(.CLOCK_RATE(25000000), .BAUD_RATE(115200), .RX_OVERSAMPLE(16)) xUART (
    .clk (Clock),
    .reset_n (reset_n),
    .i_Tx_Byte (Tx_Byte),
    .i_Tx_Ready (Tx_Ready),
    .i_Rx_Data (UART_Rx),
    .o_Rx_Done (Rx_Done),
    .o_Rx_Byte (Rx_Byte),
    .o_Tx_Data (Tx_Data)
  );

  initial begin
    // Reset
    reset_n = 0;
    repeat(5) @(posedge Clock);
    reset_n = 1;


    for (ii = 0; ii < 8; ii = ii + 1) begin
      Tx_Byte  = DataToSend[ii];
      Tx_Ready = 1;
      @(posedge Clock);
      Tx_Ready = 0;

  
      wait(Rx_Done);
      DataReceived[ii] = Rx_Byte;

      if (DataToSend[ii] == Rx_Byte)
        $display("Test Passed: TX = %h, RX = %h", DataToSend[ii], Rx_Byte);
      else
        $display("Test Failed: TX = %h, RX = %h", DataToSend[ii], Rx_Byte);

      #10000;
    end

    #50000;
    $finish();
  end
`endif

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0);
  end
endmodule
