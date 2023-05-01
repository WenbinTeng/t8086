module core (
    input           clk,
    input           rst,
    
    inout   [15:0]  ad,
    inout   [ 3:0]  as,

    output          rom_en,
    output  [15:0]  rom_addr,
    input   [ 7:0]  rom_data,

    output          ram_rd_en,
    output  [15:0]  ram_rd_addr,
    input   [ 7:0]  ram_rd_data,

    output          ram_wr_en,
    output  [15:0]  ram_wr_addr,
    output  [ 7:0]  ram_wr_data
);

    

endmodule