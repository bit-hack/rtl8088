`default_nettype none

module cpu_8088
  (
    input               CORE_CLK_INT,           // Core Clock
    input               CLK,                    // 8088 Pins
    input               RESET_INT,
    input               TEST_N_INT,
    input               READY_IN,
    input               NMI,
    input               INTR,
    output reg          INTA_n,
    output reg          ALE,
    output reg          RD_n,
    output reg          WR_n,
    output reg          IOM,
    output reg          DTR,
    output reg          DEN,
    output reg          AD_OE,
    output reg [19:0]   AD_OUT,
    input      [ 7:0]   AD_IN);

    wire  [15:0] EU_BIU_COMMAND;         // EU to BIU Signals
    wire  [15:0] EU_BIU_DATAOUT;
    wire  [15:0] EU_REGISTER_R3;
    wire         EU_PREFIX_LOCK;
    wire         EU_FLAG_I;

    wire         BIU_DONE;               // BIU to EU Signals
    wire         BIU_CLK_COUNTER_ZERO;
    wire  [1:0]  BIU_SEGMENT;
    wire         BIU_NMI_CAUGHT;
    wire         BIU_NMI_DEBOUNCE;
    wire         BIU_INTR;

    wire  [7:0]  PFQ_TOP_BYTE;
    wire         PFQ_EMPTY;
    wire [15:0]  PFQ_ADDR_OUT;

    wire [15:0]  BIU_REGISTER_ES;
    wire [15:0]  BIU_REGISTER_SS;
    wire [15:0]  BIU_REGISTER_CS;
    wire [15:0]  BIU_REGISTER_DS;
    wire [15:0]  BIU_REGISTER_RM;
    wire [15:0]  BIU_REGISTER_REG;
    wire [15:0]  BIU_RETURN_DATA;


  biu_min biu(
    .CORE_CLK_INT,           // Core Clock
    .CLK,                    // 8088 Pins
    .RESET_INT,
    .READY_IN,
    .NMI,
    .INTR,
    .INTA_n,
    .ALE,
    .RD_n,
    .WR_n,
    .IOM,
    .DTR,
    .DEN,
    .AD_OE,
    .AD_OUT,
    .AD_IN,
    .EU_BIU_COMMAND,         // EU to BIU Signals
    .EU_BIU_DATAOUT,
    .EU_REGISTER_R3,
    .EU_PREFIX_LOCK,
    .BIU_DONE,               // BIU to EU Signals
    .BIU_CLK_COUNTER_ZERO,
    .BIU_SEGMENT,
    .BIU_NMI_CAUGHT,
    .BIU_NMI_DEBOUNCE,
    .BIU_INTR,
    .PFQ_TOP_BYTE,           // prefetch queue
    .PFQ_EMPTY,
    .PFQ_ADDR_OUT,
    .BIU_REGISTER_ES,        // segment registers
    .BIU_REGISTER_SS,
    .BIU_REGISTER_CS,
    .BIU_REGISTER_DS,
    .BIU_REGISTER_RM,
    .BIU_REGISTER_REG,
    .BIU_RETURN_DATA
  );

  mcl86_eu_core eu(  
    .CORE_CLK_INT,           // Core Clock
    .RESET_INT,              // Pipelined 8088 RESET pin
    .TEST_N_INT,             // Pipelined 8088 TEST_n pin
    .EU_BIU_COMMAND,         // EU to BIU Signals
    .EU_BIU_DATAOUT,         
    .EU_REGISTER_R3, 
    .EU_PREFIX_LOCK,
    .EU_FLAG_I,          
    .BIU_DONE,               // BIU to EU Signals
    .BIU_CLK_COUNTER_ZERO,
    .BIU_NMI_CAUGHT,
    .BIU_NMI_DEBOUNCE,
    .BIU_INTR,
    .PFQ_TOP_BYTE,
    .PFQ_EMPTY,
    .PFQ_ADDR_OUT,
    .BIU_REGISTER_ES,
    .BIU_REGISTER_SS,
    .BIU_REGISTER_CS,
    .BIU_REGISTER_DS,
    .BIU_REGISTER_RM,
    .BIU_REGISTER_REG,
    .BIU_RETURN_DATA
  );

endmodule
