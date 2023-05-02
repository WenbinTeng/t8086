module core (
    input           clk,
    input           rst,
    
    inout   [15:0]  ad,
    inout   [ 3:0]  as,

    output          rom_en,
    output  [19:0]  rom_addr,
    input   [ 7:0]  rom_data,

    output          ram_rd_en,
    output          ram_rd_we,
    output  [19:0]  ram_rd_addr,
    input   [ 7:0]  ram_rd_data,

    output          ram_wr_en,
    output          ram_wr_we,
    output  [19:0]  ram_wr_addr,
    output  [ 7:0]  ram_wr_data
);

    integer i;

    reg [7:0] inst_reg [5:0];

    reg [5:0] clear_byte;

    reg [5:0] first_byte;

    reg [15:0] addr_reg;

    reg [15:0] data_reg;

    reg [15:0] register [7:0];

    reg [15:0] segment_register [3:0];

    reg [15:0] flags;


endmodule