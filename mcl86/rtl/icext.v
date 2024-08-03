`timescale 1ns / 1ps
`default_nettype none

module iceXt(
  input   wire            CLK_25,

  output  wire  [5:0]     VGA_R,
  output  wire  [5:0]     VGA_G,
  output  wire  [5:0]     VGA_B,
  output  wire            VGA_HSYNC,
  output  wire            VGA_VSYNC,

  output  wire  [17:0]    SRAM_A,
  inout   wire  [ 7:0]    SRAM_D,
  output  wire            SRAM_WE_n,
  output  wire            SRAM_CE_n,
  output  wire            SRAM_OE_n,
  output  wire  [ 3:0]    SRAM_BE_n,

//output  wire            AUDIO_L,
//output  wire            AUDIO_R,

//output  wire            LEDR,

//inout   wire            PS2CLKA,
//inout   wire            PS2CLKB,
//inout   wire            PS2DATA,
//inout   wire            PS2DATB,

//output  wire            SD_CS_n,
//output  wire            SD_DI,
//output  wire            SD_CK,
//input   wire            SD_DO,
  );

  wire clk_28_571;

  dcm dcm_system
  (
    .clkin  (CLK_25),       // 25.0000 Mhz
    .clkout0(clk_28_571),   // 28.5714 Mhz
  );

  wire [19:0] SRAM_A20;
  wire [ 7:0] cpuRamDataW; // data being written
  wire        cpuRamW;     // 1 - write, 0 - read

  System uSystem(
    .iClk        (clk_28_571),
    .iRst        (1'b0),
    .oCpuRamAddr (SRAM_A20),
    .iCpuRamDataR(SRAM_D),
    .oCpuRamDataW(cpuRamDataW),
    .oCpuRamR    (),
    .oCpuRamW    (cpuRamW),
    .oVgaR       (VGA_R),
    .oVgaG       (VGA_G),
    .oVgaB       (VGA_B),
    .oVgaVSync   (VGA_VSYNC),
    .oVgaHSync   (VGA_HSYNC)
  );

  assign SRAM_A    = SRAM_A20[17:0];
  assign SRAM_D    = !cpuRamW ? 8'hzz : cpuRamDataW;
  assign SRAM_WE_n = !cpuRamW;
  assign SRAM_CE_n = 1'b0;
  assign SRAM_OE_n = 1'b0;
  assign SRAM_BE_n = 4'b1110;

endmodule

module dcm(
    input  clkin,   // 25 MHz, 0 deg
    output clkout0, // 28.5714 MHz, 0 deg
    output locked
);
  (* FREQUENCY_PIN_CLKI="25" *)
  (* FREQUENCY_PIN_CLKOP="28.5714" *)
  (* ICP_CURRENT="12" *)
  (* LPF_RESISTOR="8" *)
  (* MFG_ENABLE_FILTEROPAMP="1" *)
  (* MFG_GMCREF_SEL="2" *)
  EHXPLLL #(
    .PLLRST_ENA("DISABLED"),
    .INTFB_WAKE("DISABLED"),
    .STDBY_ENABLE("DISABLED"),
    .DPHASE_SOURCE("DISABLED"),
    .OUTDIVIDER_MUXA("DIVA"),
    .OUTDIVIDER_MUXB("DIVB"),
    .OUTDIVIDER_MUXC("DIVC"),
    .OUTDIVIDER_MUXD("DIVD"),
    .CLKI_DIV(7),
    .CLKOP_ENABLE("ENABLED"),
    .CLKOP_DIV(23),
    .CLKOP_CPHASE(11),
    .CLKOP_FPHASE(0),
    .FEEDBK_PATH("CLKOP"),
    .CLKFB_DIV(8)
  ) pll_i (
    .RST(1'b0),
    .STDBY(1'b0),
    .CLKI(clkin),
    .CLKOP(clkout0),
    .CLKFB(clkout0),
    .CLKINTFB(),
    .PHASESEL0(1'b0),
    .PHASESEL1(1'b0),
    .PHASEDIR(1'b1),
    .PHASESTEP(1'b1),
    .PHASELOADREG(1'b1),
    .PLLWAKESYNC(1'b0),
    .ENCLKOP(1'b0),
    .LOCK(locked)
	);
endmodule
