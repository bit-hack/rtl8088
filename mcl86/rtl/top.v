`timescale 1ns / 1ps
`default_nettype none

module top(
  input         iClk,
  // sram interface
  output [19:0] iSramAddr,
  inout  [ 7:0] ioSramData,
  output        oSramWe,
  // video interface
  output [ 5:0] oVgaR,
  output [ 6:0] oVgaG,
  output [ 5:0] oVgaB,
  output        oVgaVSync,
  output        oVgaHSync  
);

  wire [7:0] cpuRamDataW; // data being written
  wire       cpuRamW;     // 1 - write, 0 - read

  System uSystem(
    .iClk        (iClk),
    .iRst        (0),
    .oCpuRamAddr (iSramAddr),
    .iCpuRamDataR(ioSramData),
    .oCpuRamDataW(cpuRamDataW),
    .oCpuRamR    (),
    .oCpuRamW    (cpuRamW),
    .oVgaR       (oVgaR),
    .oVgaG       (oVgaG),
    .oVgaB       (oVgaB),
    .oVgaVSync   (oVgaVSync),
    .oVgaHSync   (oVgaHSync)
  );

  assign ioSramData = cpuRamW ? cpuRamDataW : 8'hzz;
  assign oSramWe    = cpuRamW;

endmodule
