module top (
    input           clk,    // clock
    input           rst,    // reset
    input           rdy,    // ready
    input           test,   // test signal
    input           mn,     // mode control
    inout   [15:0]  ad,     // address data bus
    inout   [ 3:0]  as,     // address status bus
    output          ale,    // address latch enable
    output          rd_n,   // read, active LOW
    output          wr_n,   // write, active LOW
    output          m_n,    // access external memory or IO
    output          bhe_n,  // bus high enable, active LOW
    output          den_n,  // data enable
    output          dt,     // data transmit
    input           intr,   // interupt request
    input           nmi,    // non-maskable interrupt request
    output          inta_n, // interupt acknowledge, active LOW
    input           hold,   // hold request
    output          hlda    // hold acknowledge
);
    wire            rom_en;
    wire    [15:0]  rom_addr;
    wire    [ 7:0]  rom_data;

    wire            ram_rd_en;
    wire            ram_rd_we;
    wire            ram_rd_de;
    wire    [15:0]  ram_rd_addr;
    wire    [ 7:0]  ram_rd_data;

    wire            ram_wr_en;
    wire            ram_wr_we;
    wire            ram_wr_de;
    wire    [15:0]  ram_wr_addr;
    wire    [ 7:0]  ram_wr_data;

    core u_core (
        .clk            (clk),
        .rst            (rst),
        
        .rom_en         (rom_en),
        .rom_addr       (rom_addr),
        .rom_data       (rom_data),

        .ram_rd_en      (ram_rd_en),
        .ram_rd_we      (ram_rd_we),
        .ram_rd_de      (ram_rd_de),
        .ram_rd_addr    (ram_rd_addr),
        .ram_rd_data    (ram_rd_data),

        .ram_wr_en      (ram_wr_en),
        .ram_wr_we      (ram_wr_we),
        .ram_wr_de      (ram_wr_de),
        .ram_wr_addr    (ram_wr_addr),
        .ram_wr_data    (ram_wr_data)
    );

    ram u_ram (
        .clk            (clk),

        .ram_rd_en      (ram_rd_en),
        .ram_rd_we      (ram_rd_we),
        .ram_rd_de      (ram_rd_de),
        .ram_rd_addr    (ram_rd_addr),
        .ram_rd_data    (ram_rd_data),

        .ram_wr_en      (ram_wr_en),
        .ram_wr_we      (ram_wr_we),
        .ram_wr_de      (ram_wr_de),
        .ram_wr_addr    (ram_wr_addr),
        .ram_wr_data    (ram_wr_data)
    );

    rom u_rom (
        .rom_en         (rom_en),
        .rom_addr       (rom_addr),
        .rom_data       (rom_data)
    );

endmodule