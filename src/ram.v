module ram (
    input           clk,

    input           ram_rd_en,
    input           ram_rd_we,
    input           ram_rd_de,
    input   [19:0]  ram_rd_addr,
    output  [31:0]  ram_rd_data,

    input           ram_wr_en,
    input           ram_wr_we,
    input           ram_wr_de,
    input   [19:0]  ram_wr_addr,
    input   [31:0]  ram_wr_data
);

    reg [7:0] ram_array [786431:0];

    wire [19:0] wr_wa1 = {ram_wr_addr[19:1], 1'b1};
    wire [19:0] wr_wa0 = {ram_wr_addr[19:1], 1'b0};
    
    wire [19:0] wr_da3 = {ram_wr_addr[19:2], 2'b11};
    wire [19:0] wr_da2 = {ram_wr_addr[19:2], 2'b10};
    wire [19:0] wr_da1 = {ram_wr_addr[19:2], 2'b01};
    wire [19:0] wr_da0 = {ram_wr_addr[19:2], 2'b00};

    always @(posedge clk) begin
        if (ram_wr_en) begin
            if (ram_wr_de) begin
                ram_array[wr_da3] <= ram_wr_data[31:24];
                ram_array[wr_da2] <= ram_wr_data[23:16];
                ram_array[wr_da1] <= ram_wr_data[15: 8];
                ram_array[wr_da0] <= ram_wr_data[ 7: 0];
            end
            else if (ram_wr_we) begin
                ram_array[wr_wa1] <= ram_wr_data[15: 8];
                ram_array[wr_wa0] <= ram_wr_data[ 7: 0];
            end
            else begin
                ram_array[ram_wr_addr] <= ram_wr_data[7:0];
            end
        end
    end

    wire [19:0] rd_a3 = ram_rd_de ? {ram_rd_addr[19:2], 2'b11} : ram_rd_we ? {ram_rd_addr[19:1], 1'b1} : ram_rd_addr;
    wire [19:0] rd_a2 = ram_rd_de ? {ram_rd_addr[19:2], 2'b10} : ram_rd_we ? {ram_rd_addr[19:1], 1'b0} : ram_rd_addr;
    wire [19:0] rd_a1 = ram_rd_de ? {ram_rd_addr[19:2], 2'b01} : ram_rd_we ? {ram_rd_addr[19:1], 1'b1} : ram_rd_addr;
    wire [19:0] rd_a0 = ram_rd_de ? {ram_rd_addr[19:2], 2'b00} : ram_rd_we ? {ram_rd_addr[19:1], 1'b0} : ram_rd_addr;

    assign ram_rd_data = {
        ram_rd_en && ram_rd_de ?
        ram_wr_en && ram_wr_de && (rd_a3 == wr_da3     ) ? ram_wr_data[31:24] :
        ram_wr_en && ram_wr_we && (rd_a3 == wr_wa1     ) ? ram_wr_data[15: 8] :
        ram_wr_en &&              (rd_a3 == ram_rd_addr) ? ram_wr_data[ 7: 0] :
        ram_array[rd_a3] : 8'b0,
        ram_rd_en && ram_rd_de ?
        ram_wr_en && ram_wr_de && (rd_a2 == wr_da2     ) ? ram_wr_data[23:16] :
        ram_wr_en && ram_wr_we && (rd_a2 == wr_wa0     ) ? ram_wr_data[ 7: 0] :
        ram_wr_en &&              (rd_a2 == ram_rd_addr) ? ram_wr_data[ 7: 0] :
        ram_array[rd_a2] : 8'b0,
        ram_rd_en && (ram_rd_de || ram_rd_we) ?
        ram_wr_en && ram_wr_de && (rd_a1 == wr_da1     ) ? ram_wr_data[23:16] :
        ram_wr_en && ram_wr_we && (rd_a1 == wr_wa1     ) ? ram_wr_data[15: 8] :
        ram_wr_en &&              (rd_a1 == ram_rd_addr) ? ram_wr_data[ 7: 0] :
        ram_array[rd_a1] : 8'b0,
        ram_rd_en ?
        ram_wr_en && ram_wr_de && (rd_a0 == wr_da0     ) ? ram_wr_data[23:16] :
        ram_wr_en && ram_wr_we && (rd_a0 == wr_wa0     ) ? ram_wr_data[15: 8] :
        ram_wr_en &&              (rd_a0 == ram_rd_addr) ? ram_wr_data[ 7: 0] :
        ram_array[rd_a0] : 8'b0
    };

endmodule