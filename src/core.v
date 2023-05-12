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
                first_byte[4] && length6(inst_reg[4], inst_reg[3]) ||
                first_byte[3] && length5(inst_reg[3], inst_reg[2]) ||
                first_byte[2] && length4(inst_reg[2], inst_reg[1]) ||
                first_byte[1] && length3(inst_reg[1], inst_reg[0]) ||
                first_byte[0] && length2(inst_reg[0], rom_data   )
                );
        end
    end

    reg [15:0] disp_sel;

    always @(*) begin
        if (~rst)                                   disp_sel = 'b0;
        else if (field_mod(inst_reg[1]) == 2'b00)   disp_sel = 'b0;
        else if (field_mod(inst_reg[1]) == 2'b01)   disp_sel = {8{inst_reg[0][7]}, inst_reg[0]};
        else if (field_mod(inst_reg[1]) == 2'b10)   disp_sel = {  rom_data,        inst_reg[0]};
        else                                        disp_sel = 'b0;
    end

    reg [15:0] addr_reg;

    always @(posedge clk or negedge rst) begin
        if (~rst) addr_reg <= 'b0;
        else if (first_byte[2] && (
            mov_rm_r_b (inst_reg[2]) || mov_r_rm_b (inst_reg[2]) ||
            mov_rm_r_w (inst_reg[2]) || mov_r_rm_w (inst_reg[2]) ||
            mov_rm_i_b (inst_reg[2]) || mov_rm_i_w (inst_reg[2]) ||
            mov_rm_sr  (inst_reg[2]) || mov_sr_rm  (inst_reg[2]) ||
            push_rm    (inst_reg[2]) || pop_rm     (inst_reg[2]) ||
            xchg_r_rm_b(inst_reg[2]) || xchg_r_rm_w(inst_reg[2]) ||
            lea        (inst_reg[2]) ||
            lds        (inst_reg[2]) || les        (inst_reg[2]) 
        )) begin
            if (field_mod(inst_reg[1]) == 2'b00 && field_r_m(inst_reg[1]) == 3'b110) begin
                addr_reg <= disp_sel;
            end
            else begin
                case (field_r_m(inst_reg[1]))
                    3'b000: addr_reg <= `BX + `SI + disp_sel;
                    3'b001: addr_reg <= `BX + `DI + disp_sel;
                    3'b010: addr_reg <= `BP + `SI + disp_sel;
                    3'b011: addr_reg <= `BP + `DI + disp_sel;
                    3'b100: addr_reg <= `SI + disp_sel;
                    3'b101: addr_reg <= `DI + disp_sel;
                    3'b110: addr_reg <= `BP + disp_sel;
                    3'b111: addr_reg <= `BX + disp_sel;
                    default: addr_reg <= 'b0;
                endcase
            end
        end
        else if (first_byte[2] && (
            mov_a_m_b(inst_reg[2]) || mov_a_m_w(inst_reg[2]) ||
            mov_m_a_b(inst_reg[2]) || mov_m_a_w(inst_reg[2])
        )) begin
            addr_reg <= {inst_reg[0], inst_reg[1]};
        end
    end

    reg [15:0] data_reg;

    always @(posedge clk or negedge rst) begin
        if (~rst) data_reg <= 'b0;
        else if (first_byte[3] && is_reg_mod(inst_reg[2])) begin
            if      (mov_r_rm_b (inst_reg[3]))      data_reg <= {8'b0, register[field_r_m(inst_reg[2])]};
            else if (mov_r_rm_w (inst_reg[3]))      data_reg <= {register[reg_w_hi(field_r_m(inst_reg[2]))], register[reg_w_lo(field_r_m(inst_reg[2]))]};
            else if (mov_sr_rm  (inst_reg[3]))      data_reg <= {register[reg_w_hi(field_r_m(inst_reg[2]))], register[reg_w_lo(field_r_m(inst_reg[2]))]};
            else if (push_rm    (inst_reg[3]))      data_reg <= {register[reg_w_hi(field_r_m(inst_reg[2]))], register[reg_w_lo(field_r_m(inst_reg[2]))]};
            else if (xchg_r_rm_b(inst_reg[3]))      data_reg <= {8'b0, register[field_reg(inst_reg[2])]};
            else if (xchg_r_rm_w(inst_reg[3]))      data_reg <= {register[reg_w_hi(field_r_m(inst_reg[2]))], register[reg_w_lo(field_r_m(inst_reg[2]))]};
        end
        else if (first_byte[3]) begin
            if      (mov_rm_r_b (inst_reg[3]))      data_reg <= {8'b0, register[field_reg(inst_reg[2])]};
            else if (mov_r_rm_b (inst_reg[3]))      data_reg <= ram_rd_data;
            else if (mov_rm_r_w (inst_reg[3]))      data_reg <= {register[reg_w_hi(field_r_m(inst_reg[2]))], register[reg_w_lo(field_r_m(inst_reg[2]))]};
            else if (mov_r_rm_w (inst_reg[3]))      data_reg <= ram_rd_data;
            else if (mov_a_m_b  (inst_reg[3]))      data_reg <= ram_rd_data;
            else if (mov_a_m_w  (inst_reg[3]))      data_reg <= ram_rd_data;
            else if (mov_m_a_b  (inst_reg[3]))      data_reg <= `AX;
            else if (mov_m_a_w  (inst_reg[3]))      data_reg <= `AX;
            else if (mov_sr_rm  (inst_reg[3]))      data_reg <= ram_rd_data;
            else if (mov_rm_sr  (inst_reg[3]))      data_reg <= segment_register[field_reg(inst_reg[2])[1:0]];
            else if (push_rm    (inst_reg[3]))      data_reg <= ram_rd_data;
            else if (push_r     (inst_reg[3]))      data_reg <= {register[reg_w_hi(field_r_m(inst_reg[3]))], register[reg_w_lo(field_r_m(inst_reg[3]))]};
            else if (push_sr    (inst_reg[3]))      data_reg <= segment_register[field_reg(inst_reg[2])[1:0]];
            else if (pop_rm     (inst_reg[3]))      data_reg <= ram_rd_data;
            else if (pop_r      (inst_reg[3]))      data_reg <= ram_rd_data;
            else if (pop_sr     (inst_reg[3]))      data_reg <= ram_rd_data;
            else if (xchg_r_rm_b(inst_reg[3]))      data_reg <= ram_rd_data;
            else if (xchg_r_rm_w(inst_reg[3]))      data_reg <= ram_rd_data;
            else if (lds        (inst_reg[3]))      data_reg <= ram_rd_data;
            else if (les        (inst_reg[3]))      data_reg <= ram_rd_data;
            else if (lahf       (inst_reg[3]))      data_reg <= flags;
            else if (sahf       (inst_reg[3]))      data_reg <= {8'b0, `AH};
            else if (pushf      (inst_reg[3]))      data_reg <= flags;
            else if (popf       (inst_reg[3]))      data_reg <= ram_rd_data;
        end
    end

    reg [7:0] register [15:0];

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            for (i = 0; i < 16; i = i + 1) begin
                register <= 'b0;
            end
        end
        else if (first_byte[4] && is_reg_mod(inst_reg[3])) begin
            if      (mov_rm_r_b (inst_reg[4]))      register[field_r_m(inst_reg[3])] <= data_reg[7:0];
            else if (mov_rm_r_w (inst_reg[4]))      {register[reg_w_hi(field_r_m(inst_reg[3]))], register[reg_w_lo(field_r_m(inst_reg[3]))]} <= data_reg;
            else if (mov_rm_i_b (inst_reg[4]))      register[field_r_m(inst_reg[3])] <= inst_reg[2];
            else if (mov_rm_i_w (inst_reg[4]))      {register[reg_w_hi(field_r_m(inst_reg[3]))], register[reg_w_lo(field_r_m(inst_reg[3]))]} <= {inst_reg[1], inst_reg[2]};
            else if (mov_rm_sr  (inst_reg[4]))      {register[reg_w_hi(field_r_m(inst_reg[3]))], register[reg_w_lo(field_r_m(inst_reg[3]))]} <= data_reg;
            else if (pop_rm     (inst_reg[4]))      {register[reg_w_hi(field_r_m(inst_reg[3]))], register[reg_w_lo(field_r_m(inst_reg[3]))], `SP} <= {data_reg, `SP + 'h2};
            else if (xchg_r_rm_b(inst_reg[4]))      {register[field_reg(inst_reg[3])], register[field_r_m(inst_reg[3])]} <= {data_reg[7:0], register[field_reg(inst_reg[3])]};
            else if (xchg_r_rm_w(inst_reg[4]))      {register[reg_w_hi(field_reg(inst_reg[3]))], register[reg_w_lo(field_reg(inst_reg[3]))], register[reg_w_hi(field_r_m(inst_reg[3]))], register[reg_w_lo(field_r_m(inst_reg[3]))]} <= {data_reg, register[reg_w_hi(field_reg(inst_reg[3]))], register[reg_w_lo(field_reg(inst_reg[3]))]};
        end
        else if (first_byte[4]) begin
            else if (mov_r_rm_b (inst_reg[4]))      register[field_reg(inst_reg[3])] <= data_reg[7:0];
            else if (mov_r_rm_w (inst_reg[4]))      {register[reg_w_hi(field_reg(inst_reg[3]))], register[reg_w_lo(field_reg(inst_reg[3]))]} <= data_reg;
            else if (mov_r_i_b  (inst_reg[4]))      register[field_r_m(inst_reg[4])] <= inst_reg[3];
            else if (mov_r_i_w  (inst_reg[4]))      {register[reg_w_hi(field_r_m(inst_reg[4]))], register[reg_w_lo(field_r_m(inst_reg[4]))]} <= {inst_reg[2], inst_reg[3]};
            else if (mov_a_m_b  (inst_reg[4]))      `AL <= data_reg[ 7:0];
            else if (mov_a_m_w  (inst_reg[4]))      `AX <= data_reg[15:0];
            else if (push_rm    (inst_reg[4]))      `SP <= `SP - 'h2;
            else if (push_r     (inst_reg[4]))      `SP <= `SP - 'h2;
            else if (push_sr    (inst_reg[4]))      `SP <= `SP - 'h2;
            else if (pop_r      (inst_reg[4]))      {register[reg_w_hi(field_r_m(inst_reg[4]))], register[reg_w_lo(field_r_m(inst_reg[4]))], `SP} <= {data_reg, `SP + 'h2};
            else if (pop_sr     (inst_reg[4]))      {segment_register[field_reg(inst_reg[2])[1:0]], `SP} <= {data_reg, `SP + 'h2};
            else if (xchg_r_rm_b(inst_reg[4]))      register[field_reg(inst_reg[3])] <= data_reg[7:0];
            else if (xchg_r_rm_w(inst_reg[4]))      {register[reg_w_hi(field_reg(inst_reg[3]))], register[reg_w_lo(field_reg(inst_reg[3]))]} <= data_reg;
            else if (xlat       (inst_reg[4]))      `AL <= data_reg[ 7:0];
            else if (lea        (inst_reg[4]))      {register[reg_w_hi(field_reg(inst_reg[3]))], register[reg_w_lo(field_reg(inst_reg[3]))]} <= addr_reg;
            else if (lds        (inst_reg[4]))      {register[reg_w_hi(field_reg(inst_reg[3]))], register[reg_w_lo(field_reg(inst_reg[3]))]} <= data_reg;
            else if (les        (inst_reg[4]))      {register[reg_w_hi(field_reg(inst_reg[3]))], register[reg_w_lo(field_reg(inst_reg[3]))]} <= data_reg;
            else if (lahf       (inst_reg[4]))      `AH <= data_reg[7:0];
            else if (pushf      (inst_reg[4]))      `SP <= `SP - 'h2;
            else if (popf       (inst_reg[4]))      `SP <= `SP + 'h2;
        end
    end

    reg [15:0] segment_register [3:0];

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            for (i = 0; i < 4; i = i + 1) begin
                segment_register[i] <= 'b0;
            end
        end
        else if (first_byte[4]) begin
            if      (mov_sr_rm  (inst_reg[4]))      segment_register[field_reg(inst_reg[3])[1:0]] <= data_reg;
            else if (lds        (inst_reg[4]))      `DS <= ram_rd_data;
            else if (les        (inst_reg[4]))      `ES <= ram_rd_data;
        end
    end

    reg [15:0] flags;

    always @(posedge clk or negedge rst) begin
        if (~rst)
            flags <= 'b0;
        else if (first_byte[4]) begin
            if      (sahf       (inst_reg[4]))      flags <= {flags[15:8], data_reg[7:0]};
            else if (popf       (inst_reg[4]))      flags <= data_reg;
        end
    end

    assign ram_rd_en = (first_byte[3] && is_mem_mod(inst_reg[2]) && (
        mov_r_rm_b (inst_reg[3]) || mov_r_rm_w (inst_reg[3]) ||
        push_rm    (inst_reg[3]) ||
        xchg_r_rm_b(inst_reg[3]) || xchg_r_rm_w(inst_reg[3])

    )) || (first_byte[3] && (
        mov_a_m_b  (inst_reg[3]) || mov_a_m_w  (inst_reg[3]) ||
        pop_rm     (inst_reg[3]) ||
        pop_r      (inst_reg[3]) ||
        pop_sr     (inst_reg[3]) ||
        xlat       (inst_reg[3]) ||
        lds        (inst_reg[3]) || les        (inst_reg[3]) ||
        popf       (inst_reg[3])
    )) || (first_byte[4] && (
        lds        (inst_reg[4]) || les        (inst_reg[4])
    ));

    assign ram_rd_we = (first_byte[3] && is_mem_mod(inst_reg[2]) && (
        mov_r_rm_w (inst_reg[3]) ||
        push_rm    (inst_reg[3]) ||
        xchg_r_rm_w(inst_reg[3])
    )) || (first_byte[3] && (
        mov_a_m_w  (inst_reg[3]) ||
        pop_rm     (inst_reg[3]) ||
        pop_r      (inst_reg[3]) ||
        pop_sr     (inst_reg[3]) ||
        lds        (inst_reg[3]) || les        (inst_reg[3]) ||
        popf       (inst_reg[3])
    )) || (first_byte[4] && (
        lds        (inst_reg[4]) || les        (inst_reg[4])
    ));

    reg [19:0] ram_rd_addr_signal;

    always @(*) begin
        if (~rst)
            ram_rd_addr_signal = 'b0;
        else if ((first_byte[3] && is_mem_mod(inst_reg[2]) && (
            mov_r_rm_b (inst_reg[3]) || mov_r_rm_w (inst_reg[3]) ||
            push_rm    (inst_reg[3]) ||
            xchg_r_rm_b(inst_reg[3]) || xchg_r_rm_w(inst_reg[3])
        )) || (first_byte[3] && (
            mov_a_m_b  (inst_reg[3]) || mov_a_m_w  (inst_reg[3]) ||
        )))
            ram_rd_addr_signal = {`DS, 4'b0} + addr_reg;
        else if (first_byte[3] && (
            pop_rm     (inst_reg[3]) ||
            pop_r      (inst_reg[3]) ||
            pop_sr     (inst_reg[3]) ||
            popf       (inst_reg[3])
        ))
            ram_rd_addr_signal = {`SS, 4'b0} + `SP;
        else if (first_byte[3] && xlat(inst_reg[3]))
            ram_rd_addr_signal = `BX + {8'b0, `AL};
        else if (first_byte[3] && lds(inst_reg[3]))
            ram_rd_addr_signal = {`DS, 4'b0} + addr_reg;
        else if (first_byte[3] && les(inst_reg[3]))
            ram_rd_addr_signal = {`ES, 4'b0} + addr_reg;
        else if (first_byte[4] && lds(inst_reg[4]))
            ram_rd_addr_signal = {`DS, 4'b0} + addr_reg + 'h2;
        else if (first_byte[4] && les(inst_reg[4]))
            ram_rd_addr_signal = {`ES, 4'b0} + addr_reg + 'h2;
        else
            ram_rd_addr_signal = 'b0;
    end

    assign ram_rd_addr = ram_rd_addr_signal;

    assign ram_wr_en = (first_byte[4] && is_mem_mod(inst_reg[3]) && (
        mov_rm_r_b (inst_reg[4]) || mov_rm_r_w (inst_reg[4]) ||
        mov_rm_i_b (inst_reg[4]) || mov_rm_i_w (inst_reg[4]) ||
        xchg_r_rm_b(inst_reg[4]) || xchg_r_rm_w(inst_reg[4])
    )) || (first_byte[4] && (
        mov_m_a_b  (inst_reg[4]) || mov_m_a_w  (inst_reg[4]) ||
        push_rm    (inst_reg[4]) ||
        push_r     (inst_reg[4]) ||
        push_sr    (inst_reg[4]) ||
        pushf      (inst_reg[4])
    ));
    
    assign ram_wr_we = (first_byte[4] && is_mem_mod(inst_reg[3]) && (
        mov_rm_r_w (inst_reg[4]) || mov_rm_i_w (inst_reg[4]) ||
        xchg_r_rm_w(inst_reg[4])
    )) || (first_byte[4] && (
        mov_m_a_w  (inst_reg[4]) ||
        push_rm    (inst_reg[4]) ||
        push_r     (inst_reg[4]) ||
        push_sr    (inst_reg[4]) ||
        pushf      (inst_reg[4])
    ));

    reg [19:0] ram_wr_addr_signal;

    always @(*) begin
        if (~rst)
            ram_wr_addr_signal = 'b0;
        else if ((first_byte[4] && is_mem_mod(inst_reg[3]) && (
            mov_rm_r_b (inst_reg[4]) || mov_rm_r_w (inst_reg[4]) ||
            mov_rm_i_b (inst_reg[4]) || mov_rm_i_w (inst_reg[4]) ||
            xchg_r_rm_b(inst_reg[4]) || xchg_r_rm_w(inst_reg[4])
        )) || (first_byte[4] && (
            mov_m_a_b  (inst_reg[4]) || mov_m_a_w  (inst_reg[4])
        )))
            ram_wr_addr_signal = {`DS, 4'b0} + addr_reg;
        else if (first_byte[4] && (
            push_rm    (inst_reg[4]) ||
            push_r     (inst_reg[4]) ||
            push_sr    (inst_reg[4]) ||
            pushf      (inst_reg[4])
        ))
            ram_wr_addr_signal = {`SS, 4'b0} + `SP - 'h2;
    end

    assign ram_wr_addr = ram_wr_addr_signal;

    reg [15:0] ram_wr_data_signal;

    always @(*) begin
        if (~rst)
            ram_wr_data_signal = 'b0;
        else if (first_byte[4] && is_mem_mod(inst_reg[3] && (
            mov_rm_r_b (inst_reg[4]) || mov_rm_r_w (inst_reg[4])
        )) || (first_byte[4] && (
            mov_m_a_b  (inst_reg[4]) || mov_m_a_w  (inst_reg[4]) ||
            push_rm    (inst_reg[4]) ||
            push_r     (inst_reg[4]) ||
            push_sr    (inst_reg[4]) ||
            pushf      (inst_reg[4])
        )))
            ram_wr_data_signal = data_reg;
        else if ((first_byte[4] && is_mem_mod(inst_reg[3]) && (
            mov_rm_i_b(inst_reg[4])
        )) || (first_byte[4] && (

        )))
            ram_wr_data_signal = {8'b0, 
                disp0(inst_reg[3]) ? inst_reg[2] :
                disp1(inst_reg[3]) ? inst_reg[1] :
                disp2(inst_reg[3]) ? inst_reg[0] :
                'b0
            };
        else if ((first_byte[4] && is_mem_mod(inst_reg[3]) && (
            mov_rm_i_w(inst_reg[4])
        )) || (first_byte[4] && (

        )))
            ram_wr_data_signal = 
                disp0(inst_reg[3]) ? {inst_reg[1], inst_reg[2]} :
                disp1(inst_reg[3]) ? {inst_reg[0], inst_reg[1]} :
                disp2(inst_reg[3]) ? {rom_data,    inst_reg[0]} :
                'b0;
        else if ((first_byte[4] && is_mem_mod(inst_reg[3]) && (
            xchg_r_rm_b(inst_reg[4])
        )) || (first_byte[4] && (

        )))
            ram_wr_data_signal = {8'b0, register[field_reg(inst_reg[3])]};
        else if ((first_byte[4] && is_mem_mod(inst_reg[3]) && (
            xchg_r_rm_w(inst_reg[4])
        )) || (first_byte[4] && (

        )))
            ram_wr_data_signal = {register[reg_w_hi(field_reg(inst_reg[3]))], register[reg_w_lo(field_reg(inst_reg[3]))]};
    end

    assign ram_wr_data = ram_wr_data_signal;

endmodule