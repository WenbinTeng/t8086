module ram (
    input           clk,

    input           ram_rd_en,
    input   [19:0]  ram_rd_addr,
    output  [ 7:0]  ram_rd_data,

    input           ram_wr_en,
    input   [19:0]  ram_wr_addr,
    input   [ 7:0]  ram_wr_data
);

    reg [7:0] ram_array [786431:0];

    always @(posedge clk) begin
        if (ram_wr_en) begin
            ram_array[ram_wr_addr] <= ram_wr_data;
        end
            
    end

    assign ram_rd_data = ram_rd_en ? ram_wr_en && (ram_rd_addr == ram_wr_addr) ? ram_wr_data : ram_array[ram_rd_addr] : 8'bz;

endmodule