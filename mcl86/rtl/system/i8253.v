//////////////////////////////////////////////////////////////////////////////////
//
// This file is part of the Next186 Soc PC project
// http://opencores.org/project,next186
//
// Filename: timer8253.v
// Description: Part of the Next186 SoC PC project, timer
// 	8253 simplified timer (no gate, only counters 0 and 2, no read back command)
// Version 1.0
// Creation date: May2012
//
// Author: Nicolae Dumitrache 
// e-mail: ndumitrache@opencores.org
//
/////////////////////////////////////////////////////////////////////////////////
// 
// Copyright (C) 2012 Nicolae Dumitrache
// 
// This source file may be used and distributed without 
// restriction provided that this copyright statement is not 
// removed from the file and that any derivative work contains 
// the original copyright notice and the associated disclaimer.
// 
// This source file is free software; you can redistribute it 
// and/or modify it under the terms of the GNU Lesser General 
// Public License as published by the Free Software Foundation;
// either version 2.1 of the License, or (at your option) any 
// later version. 
// 
// This source is distributed in the hope that it will be 
// useful, but WITHOUT ANY WARRANTY; without even the implied 
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
// PURPOSE. See the GNU Lesser General Public License for more 
// details. 
// 
// You should have received a copy of the GNU Lesser General 
// Public License along with this source; if not, download it 
// from http://www.opencores.org/lgpl.shtml 
// 
///////////////////////////////////////////////////////////////////////////////////
// Additional Comments: 
// http://wiki.osdev.org/Programmable_Interval_Timer
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module Pit8253(
  input             clk,
  input             CS,     // 1-selected
  input             WR,     // 1-write, (0-read?)
  input       [1:0] addr,
  input       [7:0] din,    // data write
  output wire [7:0] dout,   // data read
  output            out0,
  output            out2
);

  localparam CLK_FREQ = 28636000;             // 28.636 MHz
  localparam PIT_FREQ =  1193182;             //  1.1931818181 Mhz
  localparam CLK_DIV  = CLK_FREQ / PIT_FREQ;  // 23.999

  wire pit_clk_en = (clk_div == 0);
  reg [4:0] clk_div = 0;
  always @(posedge clk) begin
    clk_div <= (clk_div==0) ? 23 : clk_div - 5'd1;
  end

  wire       a0   = (addr == 0);
  wire       a2   = (addr == 2);
  wire       a3   = (addr == 3);
  wire       cmd0 = a3 && din[7:6] == 0;
  wire       cmd2 = a3 && din[7:6] == 2;
  wire [7:0] dout0;
  wire [7:0] dout2;
  wire [7:0] mode0;
  wire [7:0] mode2;

  Pit8253Cntr cntr0(
    .CS  (CS && (a0 || cmd0)),
    .WR  (WR), 
    .clk (clk), 
    .cmd (cmd0), 
    .din (din), 
    .dout(dout0), 
    .mode(mode0), 
    .CE  (pit_clk_en)
  );

  Pit8253Cntr cntr2(
    .CS  (CS && (a2 || cmd2)),
    .WR  (WR), 
    .clk (clk), 
    .cmd (cmd2), 
    .din (din), 
    .dout(dout2), 
    .mode(mode2), 
    .CE  (pit_clk_en)
  );

  assign out0 = mode0[7];
  assign out2 = mode2[7];
  assign dout = a0 ? dout0 : dout2;

endmodule

module Pit8253Cntr(
  input            CS,
  input            WR,	  // write cmd/data
  input            clk,	  // CPU clk
  input            cmd,
  input      [7:0] din,
  output     [7:0] dout,
  output reg [7:0] mode,	// mode[7] = output
  input            CE	    // count enable
);

  reg [15:0] count  = 0;
  reg [15:0] init   = 0;
  reg [ 1:0] state  = 0; // state[1] = init reg filled
  reg        strobe = 0;
  reg        rd     = 0;
  reg        latch  = 0;
  reg        newcmd = 0;
  wire       c1     = (count == 1);
  wire       c2     = (count == 2);

  assign dout = mode[5] & (~mode[4] | rd) ? count[15:8] : count[7:0];

  always @(posedge clk) begin

    if (CS) begin
      if (WR) begin
        mode[6] <= 1;
        rd      <= 0;
        latch   <= 0;
        if (cmd) begin	// command
          if (|din[5:4]) begin
            mode[5:0] <= din[5:0];
            newcmd    <= 1;
            state     <= {1'b0, din[5] & ~din[4]};
          end else
            latch <= &mode[5:4];
        end else begin	// data
          state <= state[0] + ^mode[5:4] + 1;
          if (state[0]) init[15:8] <= din;
          else          init[ 7:0] <= din;
        end
      end else begin
        rd <= ~rd;
        if (rd)
          latch <= 0;
      end
    end else if (state[1] && CE && !latch) begin

      newcmd <= 0;

      case (mode[3:1])

      // interrupt on terminal count, hardware retriggerable one shot
      3'b000, 3'b001:
        if (mode[6]) begin
          mode[7:6] <= 2'b00;
          count     <= init;
        end else begin
          count <= count - 1;
          if (c1)
            mode[7] <= 1;
        end

      // rate generator + duplicate
      3'b010, 3'b110: begin
        mode[7] <= ~c2;
        if (c1 | newcmd) begin
          mode[6] <= 1'b0;
          count   <= init;
        end else
          count <= count - 1;
        end

      // square wave generator + duplicate
      3'b011, 3'b111: begin
        if (c1 | c2 | newcmd) begin
          mode[7:6] <= {~mode[7] | newcmd, 1'b0};
          count     <= {init[15:1], (~mode[7] | newcmd) & init[0]};
        end else
          count <= count - 2;
        end

      // software triggered strobe, hardware triggered strobe
      3'b100, 3'b101:
        if (mode[6]) begin
          mode[7:6] <= 2'b10;
          count     <= init;
          strobe    <= 1;
        end else begin
          count <= count - 1;
        if (c1) begin
          if (strobe)
            mode[7] <= 0;
          strobe <= 0;
        end else
          mode[7] <= 1;
        end

      endcase
    end
  end

endmodule
