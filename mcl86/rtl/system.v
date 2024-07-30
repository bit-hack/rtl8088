`timescale 1ns / 1ps
`default_nettype none

module Reset(
  input  iClk,
  input  iRst,
  output oRst
);
  reg [11:0] counter = 12'hfff;

  always @(posedge iClk) begin
    if (iRst) begin
      counter <= 12'hfff;
    end else begin
      counter <= counter - { 11'd0, oRst };
    end
  end
  assign oRst = ~(counter == 12'h0);
endmodule

module CpuArbiter(
  input         iClk,
  input         iRst,
  input         iNMI,     // 1 NMI          0 zz
  input         iInt,     // 1 intr         0 zz
  input  [ 7:0] iData,
  output [19:0] oAddr,
  output [ 7:0] oData,
  output        oMemW,    // 1 mem write    0 zz
  output        oMemR,    // 1 mem read     0 zz
  output        oIOW,     // 1 io write     0 zz
  output        oIOR,     // 1 io read      0 zz
  output        oIntA     // 1 zz           0 int ack
);

  wire        iom;        // 1 io           0 mem
  wire        rd_n;       // 1 zz           0 read
  wire        wr_n;       // 1 zz           0 write
  wire        ale;        // 1 latch addr   0 zz
  wire        dtr;        // 1 transmit     0 receive
  wire        den;        // 1              0 data enable  
  wire        adoe;

  // cpu clock divider
  reg [3:0] cpuClk = 0;
  always @(posedge iClk) begin
    cpuClk <= cpuClk + 1;
  end

  // cpu address latching
  wire [19:0] addr;
  reg  [19:0] cpuAddr = 0;
  always @(posedge iClk) begin
    if (ale) begin
      cpuAddr <= addr;
    end
  end
  assign oAddr = cpuAddr;

  // read/write control signals
  assign oMemW = dtr & (!iom) & (!wr_n);
  assign oIOW  = dtr & ( iom) & (!wr_n);
  assign oMemR = den & (!iom) & (!rd_n);
  assign oIOR  = den & ( iom) & (!rd_n);

  // multiplexed data bus
  assign oData = addr[7:0];

  cpu_8088 cpu(
    .CORE_CLK_INT (iClk),
    .CLK          (cpuClk[3]),  // iClk/4
    .RESET_INT    (iRst),
    .TEST_N_INT   (1),          // 0 wait for test instr.
    .READY_IN     (1),          // 1 data is ready
    .NMI          (iNMI),
    .INTR         (iInt),
    .INTA_n       (oIntA),
    .ALE          (ale),
    .RD_n         (rd_n),
    .WR_n         (wr_n),
    .IOM          (iom),
    .DTR          (dtr),
    .DEN          (den),
    .AD_OE        (adoe),       // 1 drive data bus, 0 tri-state data bus
    .AD_OUT       (addr),
    .AD_IN        (iData)
  );

endmodule

module CpuTracer(
  input         iClk,
  input  [19:0] iCpuAddr,
  input  [ 7:0] iCpuDataR,
  input  [ 7:0] iCpuDataW,
  input         iCpuMemW,
  input         iCpuMemR,
  input         iCpuIOW, 
  input         iCpuIOR
);

  reg  [3:0] ctrlOld = 0;
  wire [3:0] ctrlNew = { iCpuMemW, iCpuMemR, iCpuIOW, iCpuIOR };

  always @(posedge iClk) begin
    if ( {ctrlOld[0], ctrlNew[0]} == 2'b10)  $display(" IO Read  [%x] => %x", iCpuAddr[9:0], iCpuDataR);
    if ( {ctrlOld[1], ctrlNew[1]} == 2'b10)  $display(" IO Write [%x] <= %x", iCpuAddr[9:0], iCpuDataW);
//  if ( {ctrlOld[2], ctrlNew[2]} == 2'b10)  $display("Mem Read  [%x] => %x", iCpuAddr,      iCpuDataR);
//  if ( {ctrlOld[3], ctrlNew[3]} == 2'b10)  $display("Mem Write [%x] <= %x", iCpuAddr,      iCpuDataW);

    ctrlOld <= ctrlNew;
  end

endmodule

module Bios(
  input             iClk,
  input             iRst,
  input      [19:0] iAddr,
  output reg [ 7:0] oData=0
);
 
  
  reg  [ 7:0] rom[1024*8];  // 13'h2000 size
  wire [12:0] biosAddr = iAddr[12:0];
  
  initial begin
`ifdef XT_BIOS
    $readmemh("pcxt31.hex", rom);
`else
    $readmemh("landmark.hex", rom);
`endif
  end
  
  always @(posedge iClk) begin
    oData <= rom[biosAddr];
  end
  
endmodule

module System(
  input         iClk,
  input         iRst,
  // cpu memory interface
  output [19:0] oCpuRamAddr,
  input  [ 7:0] iCpuRamDataR,
  output [ 7:0] oCpuRamDataW,
  output        oCpuRamW,
  output        oCpuRamR
);

  wire rst;
  Reset uReset(
    .iClk(iClk),
    .iRst(iRst),
    .oRst(rst)
  );

  // 0xFE000-0xFFFFF
  wire        selectBios = { cpuAddr[19:13], 1'b0 } == 8'hFE;
  wire        selectRam  = !selectBios;

  wire [19:0] cpuAddr;
  wire [ 7:0] cpuDataIn = selectBios ? biosDataR : iCpuRamDataR;
  wire [ 7:0] cpuDataOut;
  wire        cpuMemW;
  wire        cpuMemR;
  wire        cpuIOW;
  wire        cpuIOR;

  // at some point wire this up to the bios and graphics
  assign oCpuRamAddr  = cpuAddr;
  assign oCpuRamDataW = cpuDataOut;
  assign oCpuRamW     = selectRam & cpuMemW;
  assign oCpuRamR     = selectRam & cpuMemR;

  wire [7:0] biosDataR;
  Bios uBios(
    .iClk (iClk),
    .iRst (rst),
    .iAddr(cpuAddr),
    .oData(biosDataR)
  );

  CpuArbiter uCpu(
    .iClk (iClk),
    .iRst (rst),
    .iNMI (0),
    .iInt (0),
    .iData(cpuDataIn),
    .oAddr(cpuAddr),
    .oData(cpuDataOut),
    .oMemW(cpuMemW),
    .oMemR(cpuMemR),
    .oIOW (cpuIOW),
    .oIOR (cpuIOR),
    .oIntA()
  );

  CpuTracer uTracer(
    .iClk     (iClk),
    .iCpuAddr (cpuAddr),
    .iCpuDataR(cpuDataIn),
    .iCpuDataW(cpuDataOut),
    .iCpuMemW (cpuMemW),
    .iCpuMemR (cpuMemR),
    .iCpuIOW  (cpuIOW), 
    .iCpuIOR  (cpuIOR)
  );

endmodule
