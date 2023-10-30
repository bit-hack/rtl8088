module top(
    input         clk_i,
    input         clk_cpu_i,
    input         rst_i,
    input         test_i,
    input         ready_i,
    input         nmi_i,
    input         intr_i,
    output        inta_o,
    output        ale_o,
    output        rd_o,
    output        wr_o,
    output        iom_o,
    output        dtr_o,
    output        den_o,
    output        oe_o,
    output [19:0] ad_o,
    input  [ 7:0] ad_i
    );

  cpu_8088 cpu(
    .CORE_CLK_INT (clk_i),
    .CLK          (clk_cpu_i),
    .RESET_INT    (rst_i),
    .TEST_N_INT   (test_i),
    .READY_IN     (ready_i),
    .NMI          (nmi_i),
    .INTR         (intr_i),
    .INTA_n       (inta_o),
    .ALE          (ale_o),
    .RD_n         (rd_o),
    .WR_n         (wr_o),
    .IOM          (iom_o),
    .DTR          (dtr_o),
    .DEN          (den_o),
    .AD_OE        (oe_o),
    .AD_OUT       (ad_o),
    .AD_IN        (ad_i)
  );

endmodule
