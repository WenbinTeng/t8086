module ram (
    input           clk,

    input           ram_rd_en,
    input           ram_rd_we,
    input   [19:0]  ram_rd_addr,
    output  [15:0]  ram_rd_data,

    input           ram_wr_en,
    input           ram_wr_we,
    input   [19:0]  ram_wr_addr,
    input   [15:0]  ram_wr_data
);

    reg [7:0] ram_array [786431:0];

    wire [19:0] wr_a0 = {ram_wr_addr[19:1], 1'b0};
    wire [19:0] wr_a1 = {ram_wr_addr[19:1], 1'b1};

    always @(posedge clk) begin
        if (ram_wr_en) begin
            if (ram_wr_we) begin
                ram_array[wr_a1] <= ram_wr_data[15:8];
                ram_array[wr_a0] <= ram_wr_data[ 7:0];
            end
            else begin
                ram_array[ram_wr_addr] <= ram_wr_data[7:0];
            end
        end
    end

    wire [19:0] rd_a0 = {ram_rd_addr[19:1], 1'b0};
    wire [19:0] rd_a1 = {ram_rd_addr[19:1], 1'b1};

    wire [ 7:0] rd_w0 =
        ram_wr_en &&  ram_wr_we && (rd_a0 == wr_a0      ) ? ram_wr_data[ 7:0] :
        ram_wr_en && ~ram_wr_we && (rd_a0 == ram_wr_addr) ? ram_wr_data[ 7:0] :
        ram_array[rd_a0];
    wire [ 7:0] rd_w1 =
        ram_wr_en &&  ram_wr_we && (rd_a1 == wr_a1      ) ? ram_wr_data[15:8] :
        ram_wr_en && ~ram_wr_we && (rd_a1 == ram_wr_addr) ? ram_wr_data[ 7:0] :
        ram_array[rd_a1];
    wire [ 7:0] rd_b =
        ram_wr_en &&  ram_wr_we && (ram_rd_addr == wr_a1      ) ? ram_wr_data[15:8] :
        ram_wr_en &&  ram_wr_we && (ram_rd_addr == wr_a0      ) ? ram_wr_data[ 7:0] :
        ram_wr_en && ~ram_wr_we && (ram_rd_addr == ram_wr_addr) ? ram_wr_data[ 7:0] :
        ram_array[ram_rd_addr];

    assign ram_rd_data = ram_rd_en ? ram_rd_we ? {rd_w1, rd_w0} : {8'bz, rd_b} : 16'bz;

endmodule