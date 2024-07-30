module top(
  input         iClk,
  input         iReset,
  output [19:0] oAddr,
  output [ 7:0] oMData,
  input  [ 7:0] iMData,
  output        oMRd,
  output        oMWr,
  input         iReady,
  output [11:0] oPort,
  output [ 7:0] oPData,
  input  [ 7:0] iPData,
  output        oPRd,
  input         iPRd,
  output        oPWr,
  input         iPWr,
  output [ 7:0] oIrq,
  input  [ 7:0] iIrq
);

  V188 cpu(
    .clk    (iClk),
    .reset_n(iReset),
    .a      (oAddr),
    .dout   (oMData),
    .din    (iMData),
    .mrdout (oMRd),
    .mwrout (oMWr),
    .ready  (iReady),
    .port   (oPort),
    .iodout (oPData),
    .iodin  (iPData),
    .iordout(oPRd),
    .iordin (iPRd),
    .iowrout(oPWr),
    .iowrin (iPWr),
    .irqout (oIrq),
    .irqin  (iIrq),
    .mcout  ()
  );
  
  wire [15:0] ax    /*verilator public_flat_rd*/ = cpu.ax;
  wire [15:0] cx    /*verilator public_flat_rd*/ = cpu.cx;
  wire [15:0] dx    /*verilator public_flat_rd*/ = cpu.dx;
  wire [15:0] bx    /*verilator public_flat_rd*/ = cpu.bx;
  wire [15:0] sp    /*verilator public_flat_rd*/ = cpu.sp;
  wire [15:0] bp    /*verilator public_flat_rd*/ = cpu.bp;
  wire [15:0] si    /*verilator public_flat_rd*/ = cpu.si;
  wire [15:0] di    /*verilator public_flat_rd*/ = cpu.di;
  wire [15:0] es    /*verilator public_flat_rd*/ = cpu.es;
  wire [15:0] cs    /*verilator public_flat_rd*/ = cpu.cs;
  wire [15:0] ss    /*verilator public_flat_rd*/ = cpu.ss;   
  wire [15:0] ds    /*verilator public_flat_rd*/ = cpu.ds;
  wire [15:0] fs    /*verilator public_flat_rd*/ = cpu.fs;
  wire [15:0] gs    /*verilator public_flat_rd*/ = cpu.gs;
  wire [15:0] flags /*verilator public_flat_rd*/ = cpu.flags;
  wire [15:0] ip    /*verilator public_flat_rd*/ = cpu.ip;
  wire [28:0] state /*verilator public_flat_rd*/ = cpu.state;

endmodule

module MICROCODE(
  input             clock,
  input      [11:0] address_a,
  output reg [17:0] q_a);

  reg [31:0] data[4096];

  initial begin
    $readmemh("C:\\personal\\V188\\verilator\\mcode.hex", data);
  end

  always @(*) begin
    q_a = data[ address_a ][17:0];
  end

endmodule

module Mul1 (
  input             clock,
  input      [15:0] dataa,
  input      [15:0] datab,
  output reg [31:0] result);

  always @(posedge clock) begin
    result <= $unsigned(dataa) * $unsigned(datab);
  end

endmodule

module SignedMul (
  input             clock,
  input      [15:0] dataa,
  input      [15:0] datab,
  output reg [31:0] result);

  always @(posedge clock) begin
    result <= $signed(dataa) * $signed(datab);
  end

endmodule

