module ram (
    input           clk,

    input           ram_rd_en,
    input   [ 1:0]  ram_rd_be,
    input   [19:0]  ram_rd_addr,
    output  [15:0]  ram_rd_data,

    input           ram_wr_en,
    input   [ 1:0]  ram_wr_be,
    input   [19:0]  ram_wr_addr,
    input   [15:0]  ram_wr_data
);

    reg [7:0] ram_array [786431:0];

    wire [19:0] wr_a1 = {ram_wr_addr[19:1], 1'b1};
    wire [19:0] wr_a0 = {ram_wr_addr[19:1], 1'b0};

    always @(posedge clk) begin
        if (ram_wr_en) begin
            if (ram_wr_be[1]) ram_array[wr_a1] <= ram_wr_data[15:8];
            if (ram_wr_be[0]) ram_array[wr_a0] <= ram_wr_data[ 7:0];
        end
            
    end

    wire [19:0] rd_a1 = {ram_rd_addr[19:1], 1'b1};
    wire [19:0] rd_a0 = {ram_rd_addr[19:1], 1'b0};

    assign ram_rd_data = ram_rd_en ? {
        ram_rd_be[1] ? ram_wr_en && (ram_rd_addr[19:1] == ram_wr_addr[19:1]) ? ram_wr_data[15:8] : ram_array[rd_a1] : 8'bz,
        ram_rd_be[0] ? ram_wr_en && (ram_rd_addr[19:1] == ram_wr_addr[19:1]) ? ram_wr_data[ 7:0] : ram_array[rd_a0] : 8'bz
    } : 16'bz;

endmodule