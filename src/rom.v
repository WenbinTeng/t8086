module rom (
    input           rom_en,
    input   [ 1:0]  rom_be,
    input   [19:0]  rom_addr,
    output  [15:0]  rom_data
);
    
    reg [7:0] rom_array [262143:0];

    initial begin
        
    end

    wire [17:0] a1 = {rom_addr[17:1], 1'b1};
    wire [17:0] a0 = {rom_addr[17:1], 1'b1};

    assign rom_data = rom_en ? { rom_be[1] ? rom_array[a1] : 8'bz, rom_be[0] ? rom_array[a0] : 8'bz } : 16'bz;

endmodule