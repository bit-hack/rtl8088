// Graphics Gremlin
//
// Copyright (c) 2021 Eric Schlaepfer
// This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
// International License. To view a copy of this license, visit
// http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
// Commons, PO Box 1866, Mountain View, CA 94042, USA.
//

`default_nettype none


module cga_vram(
    // Clock
    input             clk,
    // Port 0 is read/write
    input      [18:0] isa_addr,
    input      [ 7:0] isa_din,
    output reg [ 7:0] isa_dout,
    input             isa_read,
    input             isa_write,
    input             isa_op_enable,
    // Port 1 is read only
    input      [18:0] pixel_addr,
    output reg [ 7:0] pixel_data,
    input             pixel_read
    );

    reg [ 7:0] vram[16*1024];  // 16KB

`ifdef SPLASH
    initial begin
        $readmemh("rand16kb.hex", vram);
    end
`endif

    always @(posedge clk) begin

      // port 0
      if (isa_write) begin
        vram[ isa_addr[13:0] ] <= isa_din;
      end else begin
        if (isa_read) begin
          isa_dout <= vram[ isa_addr[13:0] ];
        end
      end

      // port 1
      pixel_data <= vram[ pixel_addr[13:0] ];
    end

endmodule
