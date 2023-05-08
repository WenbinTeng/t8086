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
    input   [15:0]  ram_rd_data,

    output          ram_wr_en,
    output          ram_wr_we,
    output  [19:0]  ram_wr_addr,
    output  [15:0]  ram_wr_data
);

    `include "def.v"

    integer i;

    reg [15:0] program_counter;

    always @(posedge clk or negedge rst) begin
        if (~rst)
            program_counter <= 'b0;
        else
            program_counter <= program_counter + 'b1;
    end

    reg [7:0] inst_reg [4:0];

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            for (i = 0; i < 5; i = i + 1) begin
                inst_reg[i] <= 'b0;
            end
        end
        else begin
            for (i = 1; i < 5; i = i + 1) begin
                inst_reg[i] <= inst_reg[i-1];
            end
            inst_reg[0] <= rom_data;
        end
    end

    reg [4:0] clear_byte;

    always @(*) begin
        
    end

    reg [4:0] first_byte;

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            first_byte <= 'b0;
        end
        else begin
            for (i = 1; i < 5; i = i + 1) begin
                first_byte[i] <= clear_byte[i] & first_byte[i-1];
            end
            first_byte[0] <= ~clear_byte[0] && ~(
                first_byte[4]&&length6(inst_reg[4],inst_reg[3])||
                first_byte[3]&&length5(inst_reg[3],inst_reg[2])||
                first_byte[2]&&length4(inst_reg[2],inst_reg[1])||
                first_byte[1]&&length3(inst_reg[1],inst_reg[0])||
                first_byte[0]&&length2(inst_reg[0],rom_data   )
                );
        end
    end

    reg [15:0] addr_reg;

    reg [15:0] data_reg;

    reg [15:0] register [7:0];

    reg [15:0] segment_register [3:0];

    reg [15:0] flags;


endmodule