`timescale 1ns / 1ps
`default_nettype none

module eu_rom(
  input             clka,
  input      [11:0] addra,
  output reg [31:0] douta
  );

  reg [31:0] rom[4096];
  initial $readmemb("roms/microcode.mem", rom);

  always @(posedge clka) begin
    douta <= rom[addra];
  end

endmodule
