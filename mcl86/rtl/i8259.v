`default_nettype none

//          a0 d7  d6  d5  d4  d3  d2  d1  d0
//
// icw1     0  a7  a6  a5  1   lt  ai  sn  i4
// icw2     1  t7  t6  t5  t4  t3  .   .   . 
// icw3     1  s7  s6  s5  s4  s3  s2  s1  s0
// icw4     1  0   0   0   snm buf ms  aei upm
// ocw1     1  m7  m6  m5  m4  m3  m2  m1  m0
// ocw2     0  r   sl  eoi 0   0   l2  l1  l0
// ocw3     0  0   esm smm 0   1   p   rr  ris
//

module i8259(
    input        clk_i,
    input        wr_i,
    input        a0_i,
    input  [7:0] data_i,
    input  [7:0] intr_i,
    input        inta_i,    // int ack.
    output       int_o,
    output [7:0] data_o
);

endmodule
