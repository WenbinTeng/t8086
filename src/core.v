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
        if (~rst)                                                       disp_sel = 'b0;
        else if (field_mod(inst_reg[1]) == 2'b00)                       disp_sel = 'b0;
        else if (field_mod(inst_reg[1]) == 2'b01)                       disp_sel = {8{inst_reg[0][7]}, inst_reg[0]};
        else if (field_mod(inst_reg[1]) == 2'b10)                       disp_sel = {  rom_data,        inst_reg[0]};
        else                                                            disp_sel = 'b0;
    end

    reg [15:0] addr_reg;

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            addr_reg <= 'b0;
        end
        else if (first_byte[2] && (
            mov_rm_r_b  (inst_reg[2]) || mov_r_rm_b (inst_reg[2]) ||
            mov_rm_r_w  (inst_reg[2]) || mov_r_rm_w (inst_reg[2]) ||
            mov_rm_sr   (inst_reg[2]) || mov_sr_rm  (inst_reg[2]) ||
            push_rm     (inst_reg[2]) || pop_rm     (inst_reg[2]) ||
            xchg_r_rm_b (inst_reg[2]) || xchg_r_rm_w(inst_reg[2]) ||
            add_rm_r_b  (inst_reg[2]) || add_r_rm_b (inst_reg[2]) ||
            add_rm_r_w  (inst_reg[2]) || add_r_rm_w (inst_reg[2]) ||
            adc_rm_r_b  (inst_reg[2]) || adc_r_rm_b (inst_reg[2]) ||
            adc_rm_r_w  (inst_reg[2]) || adc_r_rm_w (inst_reg[2]) ||
            sub_rm_r_b  (inst_reg[2]) || sub_r_rm_b (inst_reg[2]) ||
            sub_rm_r_w  (inst_reg[2]) || sub_r_rm_w (inst_reg[2]) ||
            sbb_rm_r_b  (inst_reg[2]) || sbb_r_rm_b (inst_reg[2]) ||
            sbb_rm_r_w  (inst_reg[2]) || sbb_r_rm_w (inst_reg[2]) ||
            cmp_rm_r_b  (inst_reg[2]) || cmp_r_rm_b (inst_reg[2]) ||
            cmp_rm_r_w  (inst_reg[2]) || cmp_r_rm_w (inst_reg[2]) ||
            lea         (inst_reg[2]) ||
            lds         (inst_reg[2]) ||
            les         (inst_reg[2]) ||
            mov_rm_i_b  (inst_reg[2], inst_reg[1]) ||
            mov_rm_i_w  (inst_reg[2], inst_reg[1]) ||
            add_rm_i_b  (inst_reg[2], inst_reg[1]) ||
            add_rm_zi_w (inst_reg[2], inst_reg[1]) ||
            add_rm_si_w (inst_reg[2], inst_reg[1]) ||
            adc_rm_i_b  (inst_reg[2], inst_reg[1]) ||
            adc_rm_zi_w (inst_reg[2], inst_reg[1]) ||
            adc_rm_si_w (inst_reg[2], inst_reg[1]) ||
            sub_rm_i_b  (inst_reg[2], inst_reg[1]) ||
            sub_rm_zi_w (inst_reg[2], inst_reg[1]) ||
            sub_rm_si_w (inst_reg[2], inst_reg[1]) ||
            sbb_rm_i_b  (inst_reg[2], inst_reg[1]) ||
            sbb_rm_zi_w (inst_reg[2], inst_reg[1]) ||
            sbb_rm_si_w (inst_reg[2], inst_reg[1]) ||
            cmp_rm_i_b  (inst_reg[2], inst_reg[1]) ||
            cmp_rm_zi_w (inst_reg[2], inst_reg[1]) ||
            cmp_rm_si_w (inst_reg[2], inst_reg[1]) ||
            inc_rm_b    (inst_reg[2], inst_reg[1]) ||
            inc_rm_w    (inst_reg[2], inst_reg[1]) ||
            dec_rm_b    (inst_reg[2], inst_reg[1]) ||
            dec_rm_w    (inst_reg[2], inst_reg[1]) ||
            neg_rm_b    (inst_reg[2], inst_reg[1]) ||
            neg_rm_w    (inst_reg[2], inst_reg[1])
        )) begin
            if (
                field_mod(inst_reg[1]) == 2'b00 &&
                field_r_m(inst_reg[1]) == 3'b110
            )
                                                                        addr_reg <= {rom_data, inst_reg[0]};
            else begin
                case (field_r_m(inst_reg[1]))
                    3'b000:                                             addr_reg <= `BX + `SI + disp_sel;
                    3'b001:                                             addr_reg <= `BX + `DI + disp_sel;
                    3'b010:                                             addr_reg <= `BP + `SI + disp_sel;
                    3'b011:                                             addr_reg <= `BP + `DI + disp_sel;
                    3'b100:                                             addr_reg <= `SI + disp_sel;
                    3'b101:                                             addr_reg <= `DI + disp_sel;
                    3'b110:                                             addr_reg <= `BP + disp_sel;
                    3'b111:                                             addr_reg <= `BX + disp_sel;
                    default:                                            addr_reg <= 'b0;
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
        if (~rst)                                                       data_reg <= 'b0;
        else if (first_byte[3] && is_reg_mod(inst_reg[2])) begin
            if      (
                mov_r_rm_b  (inst_reg[3]) ||
                add_rm_r_b  (inst_reg[3]) ||
                add_r_rm_b  (inst_reg[3]) ||
                adc_rm_r_b  (inst_reg[3]) ||
                adc_r_rm_b  (inst_reg[3]) ||
                sub_rm_r_b  (inst_reg[3]) ||
                sub_r_rm_b  (inst_reg[3]) ||
                sbb_rm_r_b  (inst_reg[3]) ||
                sbb_r_rm_b  (inst_reg[3]) ||
                cmp_rm_r_b  (inst_reg[3]) ||
                cmp_r_rm_b  (inst_reg[3]) ||
                add_rm_i_b  (inst_reg[3], inst_reg[2]) ||
                adc_rm_i_b  (inst_reg[3], inst_reg[2]) ||
                sub_rm_i_b  (inst_reg[3], inst_reg[2]) ||
                sbb_rm_i_b  (inst_reg[3], inst_reg[2]) ||
                cmp_rm_i_b  (inst_reg[3], inst_reg[2]) ||
                inc_rm_b    (inst_reg[3], inst_reg[2]) ||
                dec_rm_b    (inst_reg[3], inst_reg[2]) ||
                neg_rm_b    (inst_reg[3], inst_reg[2])
            )                                                           data_reg <= register[reg_b(field_r_m(inst_reg[2])) +:  8];
            else if (
                mov_r_rm_w  (inst_reg[3]) ||
                mov_sr_rm   (inst_reg[3]) ||
                push_rm     (inst_reg[3]) ||
                add_rm_r_w  (inst_reg[3]) ||
                add_r_rm_w  (inst_reg[3]) ||
                adc_rm_r_w  (inst_reg[3]) ||
                adc_r_rm_w  (inst_reg[3]) ||
                sub_rm_r_w  (inst_reg[3]) ||
                sub_r_rm_w  (inst_reg[3]) ||
                sbb_rm_r_w  (inst_reg[3]) ||
                sbb_r_rm_w  (inst_reg[3]) ||
                cmp_rm_r_w  (inst_reg[3]) ||
                cmp_r_rm_w  (inst_reg[3]) ||
                add_rm_zi_w (inst_reg[3], inst_reg[2]) ||
                add_rm_si_w (inst_reg[3], inst_reg[2]) ||
                adc_rm_zi_w (inst_reg[3], inst_reg[2]) ||
                adc_rm_si_w (inst_reg[3], inst_reg[2]) ||
                sub_rm_zi_w (inst_reg[3], inst_reg[2]) ||
                sub_rm_si_w (inst_reg[3], inst_reg[2]) ||
                sbb_rm_zi_w (inst_reg[3], inst_reg[2]) ||
                sbb_rm_si_w (inst_reg[3], inst_reg[2]) ||
                cmp_rm_zi_w (inst_reg[3], inst_reg[2]) ||
                cmp_rm_si_w (inst_reg[3], inst_reg[2]) ||
                inc_rm_w    (inst_reg[3], inst_reg[2]) ||
                dec_rm_w    (inst_reg[3], inst_reg[2]) ||
                neg_rm_w    (inst_reg[3], inst_reg[2])
            )                                                           data_reg <= register[reg_w(field_r_m(inst_reg[2])) +: 16];
        end
        else if (first_byte[3]) begin
            if      (mov_rm_r_b (inst_reg[3]))                          data_reg <= register[reg_b(field_reg(inst_reg[2])) +:  8];
            else if (mov_rm_r_w (inst_reg[3]))                          data_reg <= register[reg_w(field_reg(inst_reg[2])) +: 16];
            else if (mov_rm_sr  (inst_reg[3]))                          data_reg <= segment_register[field_reg(inst_reg[2])[1:0]];
            else if (push_sr    (inst_reg[3]))                          data_reg <= segment_register[field_reg(inst_reg[2])[1:0]];
            else if (push_r     (inst_reg[3]))                          data_reg <= register[reg_w(field_r_m(inst_reg[3])) +: 16];
            else if (pushf      (inst_reg[3]))                          data_reg <= flags;
            else if (lahf       (inst_reg[3]))                          data_reg <= flags;
            else if (sahf       (inst_reg[3]))                          data_reg <= `AH;
            else if (mov_m_a_b  (inst_reg[3]))                          data_reg <= `AL;
            else if (mov_m_a_w  (inst_reg[3]))                          data_reg <= `AX;
            else if (mov_rm_i_b (inst_reg[3], inst_reg[2]))             data_reg <= {       8'b0, inst_reg[1]};
            else if (mov_rm_i_w (inst_reg[3], inst_reg[2]))             data_reg <= {inst_reg[0], inst_reg[1]};
            else if (
                mov_r_i_b   (inst_reg[3]) ||
                add_a_i_b   (inst_reg[3]) ||
                adc_a_i_b   (inst_reg[3]) ||
                sub_a_i_b   (inst_reg[3]) ||
                sbb_a_i_b   (inst_reg[3]) ||
                cmp_a_i_b   (inst_reg[3]) 
            )                                                           data_reg <= {       8'b0, inst_reg[2]};
            else if (
                mov_r_i_w   (inst_reg[3]) ||
                add_a_i_w   (inst_reg[3]) ||
                adc_a_i_w   (inst_reg[3]) ||
                sub_a_i_w   (inst_reg[3]) ||
                sbb_a_i_w   (inst_reg[3]) ||
                cmp_a_i_w   (inst_reg[3])
            )                                                           data_reg <= {inst_reg[1], inst_reg[2]};
            else if (
                mov_r_rm_b (inst_reg[3]) ||
                mov_r_rm_w (inst_reg[3]) ||
                mov_a_m_b  (inst_reg[3]) ||
                mov_a_m_w  (inst_reg[3]) ||
                push_rm    (inst_reg[3]) ||
                pop_rm     (inst_reg[3]) ||
                pop_r      (inst_reg[3]) ||
                pop_sr     (inst_reg[3]) ||
                xchg_r_rm_b(inst_reg[3]) ||
                xchg_r_rm_w(inst_reg[3]) ||
                xlat       (inst_reg[3]) ||
                lds        (inst_reg[3]) ||
                les        (inst_reg[3]) ||
                popf       (inst_reg[3]) ||
                add_rm_r_b (inst_reg[3]) ||
                add_r_rm_b (inst_reg[3]) ||
                add_rm_r_w (inst_reg[3]) ||
                add_r_rm_w (inst_reg[3]) ||
                adc_rm_r_b (inst_reg[3]) ||
                adc_r_rm_b (inst_reg[3]) ||
                adc_rm_r_w (inst_reg[3]) ||
                adc_r_rm_w (inst_reg[3]) ||
                sub_rm_r_b (inst_reg[3]) ||
                sub_r_rm_b (inst_reg[3]) ||
                sub_rm_r_w (inst_reg[3]) ||
                sub_r_rm_w (inst_reg[3]) ||
                sbb_rm_r_b (inst_reg[3]) ||
                sbb_r_rm_b (inst_reg[3]) ||
                sbb_rm_r_w (inst_reg[3]) ||
                sbb_r_rm_w (inst_reg[3]) ||
                cmp_rm_r_b (inst_reg[3]) ||
                cmp_r_rm_b (inst_reg[3]) ||
                cmp_rm_r_w (inst_reg[3]) ||
                cmp_r_rm_w (inst_reg[3]) ||
                add_rm_i_b (inst_reg[3], inst_reg[2]) ||
                add_rm_zi_w(inst_reg[3], inst_reg[2]) ||
                add_rm_si_w(inst_reg[3], inst_reg[2]) ||
                adc_rm_i_b (inst_reg[3], inst_reg[2]) ||
                adc_rm_zi_w(inst_reg[3], inst_reg[2]) ||
                adc_rm_si_w(inst_reg[3], inst_reg[2]) ||
                sub_rm_i_b (inst_reg[3], inst_reg[2]) ||
                sub_rm_zi_w(inst_reg[3], inst_reg[2]) ||
                sub_rm_si_w(inst_reg[3], inst_reg[2]) ||
                sbb_rm_i_b (inst_reg[3], inst_reg[2]) ||
                sbb_rm_zi_w(inst_reg[3], inst_reg[2]) ||
                sbb_rm_si_w(inst_reg[3], inst_reg[2]) ||
                cmp_rm_i_b (inst_reg[3], inst_reg[2]) ||
                cmp_rm_zi_w(inst_reg[3], inst_reg[2]) ||
                cmp_rm_si_w(inst_reg[3], inst_reg[2]) ||
                inc_rm_b   (inst_reg[3], inst_reg[2]) ||
                inc_rm_w   (inst_reg[3], inst_reg[2]) ||
                dec_rm_b   (inst_reg[3], inst_reg[2]) ||
                dec_rm_w   (inst_reg[3], inst_reg[2]) ||
                neg_rm_b   (inst_reg[3], inst_reg[2]) ||
                neg_rm_w   (inst_reg[3], inst_reg[2]) 
            )
                                                                        data_reg <= ram_rd_data;
        end
    end

    reg [15:0] a;
    reg [15:0] b;
    reg [15:0] r;
    
    always @(*) begin
        if (~rst) begin
            a = 'b0;
            b = 'b0;
            r = 'b0;
        end
        else if (first_byte[4]) begin
            if      (add_rm_r_b (inst_reg[4]))                          begin a = data_reg; b = register[reg_b(field_reg(inst_reg[3])) +:  8]; r = a + b; end
            else if (add_r_rm_b (inst_reg[4]))                          begin a = register[reg_b(field_reg(inst_reg[3])) +:  8]; b = data_reg; r = a + b; end
            else if (add_rm_r_w (inst_reg[4]))                          begin a = data_reg; b = register[reg_w(field_reg(inst_reg[3])) +: 16]; r = a + b; end
            else if (add_r_rm_w (inst_reg[4]))                          begin a = register[reg_w(field_reg(inst_reg[3])) +: 16]; b = data_reg; r = a + b; end
            else if (add_rm_i_b (inst_reg[4], inst_reg[3]))             begin a = data_reg; b =                     inst_reg[2] ; r = a + b; end
            else if (add_rm_zi_w(inst_reg[4], inst_reg[3]))             begin a = data_reg; b = {inst_reg[1],       inst_reg[2]}; r = a + b; end
            else if (add_rm_si_w(inst_reg[4], inst_reg[3]))             begin a = data_reg; b = {8{inst_reg[2][7]}, inst_reg[2]}; r = a + b; end
            else if (add_a_i_b  (inst_reg[4]))                          begin a = `AL; b = data_reg; r = a + b; end
            else if (add_a_i_w  (inst_reg[4]))                          begin a = `AX; b = data_reg; r = a + b; end
            else if (adc_rm_r_b (inst_reg[4]))                          begin a = data_reg; b = register[reg_b(field_reg(inst_reg[3])) +:  8]; r = a + b + `CF; end
            else if (adc_r_rm_b (inst_reg[4]))                          begin a = register[reg_b(field_reg(inst_reg[3])) +:  8]; b = data_reg; r = a + b + `CF; end
            else if (adc_rm_r_w (inst_reg[4]))                          begin a = data_reg; b = register[reg_w(field_reg(inst_reg[3])) +: 16]; r = a + b + `CF; end
            else if (adc_r_rm_w (inst_reg[4]))                          begin a = register[reg_w(field_reg(inst_reg[3])) +: 16]; b = data_reg; r = a + b + `CF; end
            else if (adc_rm_i_b (inst_reg[4], inst_reg[3]))             begin a = data_reg; b =                     inst_reg[2] ; r = a + b + `CF;  end
            else if (adc_rm_zi_w(inst_reg[4], inst_reg[3]))             begin a = data_reg; b = {inst_reg[1],       inst_reg[2]}; r = a + b + `CF; end
            else if (adc_rm_si_w(inst_reg[4], inst_reg[3]))             begin a = data_reg; b = {8{inst_reg[2][7]}, inst_reg[2]}; r = a + b + `CF; end
            else if (adc_a_i_b  (inst_reg[4]))                          begin a = `AL; b = data_reg; r = a + b + `CF; end
            else if (adc_a_i_w  (inst_reg[4]))                          begin a = `AX; b = data_reg; r = a + b + `CF; end
            else if (sub_rm_r_b (inst_reg[4]))                          begin a = data_reg; b = register[reg_b(field_reg(inst_reg[3])) +:  8]; r = a - b; end
            else if (sub_r_rm_b (inst_reg[4]))                          begin a = register[reg_b(field_reg(inst_reg[3])) +:  8]; b = data_reg; r = a - b; end
            else if (sub_rm_r_w (inst_reg[4]))                          begin a = data_reg; b = register[reg_w(field_reg(inst_reg[3])) +: 16]; r = a - b; end
            else if (sub_r_rm_w (inst_reg[4]))                          begin a = register[reg_w(field_reg(inst_reg[3])) +: 16]; b = data_reg; r = a - b; end
            else if (sub_rm_i_b (inst_reg[4], inst_reg[3]))             begin a = data_reg; b =                     inst_reg[2] ; r = a - b; end
            else if (sub_rm_zi_w(inst_reg[4], inst_reg[3]))             begin a = data_reg; b = {inst_reg[1],       inst_reg[2]}; r = a - b; end
            else if (sub_rm_si_w(inst_reg[4], inst_reg[3]))             begin a = data_reg; b = {8{inst_reg[2][7]}, inst_reg[2]}; r = a - b; end
            else if (sub_a_i_b  (inst_reg[4]))                          begin a = `AL; b = data_reg; r = a - b; end
            else if (sub_a_i_w  (inst_reg[4]))                          begin a = `AX; b = data_reg; r = a - b; end
            else if (sbb_rm_r_b (inst_reg[4]))                          begin a = data_reg; b = register[reg_b(field_reg(inst_reg[3])) +:  8]; r = a - b - `CF; end
            else if (sbb_r_rm_b (inst_reg[4]))                          begin a = register[reg_b(field_reg(inst_reg[3])) +:  8]; b = data_reg; r = a - b - `CF; end
            else if (sbb_rm_r_w (inst_reg[4]))                          begin a = data_reg; b = register[reg_w(field_reg(inst_reg[3])) +: 16]; r = a - b - `CF; end
            else if (sbb_r_rm_w (inst_reg[4]))                          begin a = register[reg_w(field_reg(inst_reg[3])) +: 16]; b = data_reg; r = a - b - `CF; end
            else if (sbb_rm_i_b (inst_reg[4], inst_reg[3]))             begin a = data_reg; b =                     inst_reg[2] ; r = a - b - `CF;  end
            else if (sbb_rm_zi_w(inst_reg[4], inst_reg[3]))             begin a = data_reg; b = {inst_reg[1],       inst_reg[2]}; r = a - b - `CF; end
            else if (sbb_rm_si_w(inst_reg[4], inst_reg[3]))             begin a = data_reg; b = {8{inst_reg[2][7]}, inst_reg[2]}; r = a - b - `CF; end
            else if (sbb_a_i_b  (inst_reg[4]))                          begin a = `AL; b = data_reg; r = a - b - `CF; end
            else if (sbb_a_i_w  (inst_reg[4]))                          begin a = `AX; b = data_reg; r = a - b - `CF; end
            else if (cmp_rm_r_b (inst_reg[4]))                          begin a = data_reg; b = register[reg_b(field_reg(inst_reg[3])) +:  8]; r = a - b; end
            else if (cmp_r_rm_b (inst_reg[4]))                          begin a = register[reg_b(field_reg(inst_reg[3])) +:  8]; b = data_reg; r = a - b; end
            else if (cmp_rm_r_w (inst_reg[4]))                          begin a = data_reg; b = register[reg_w(field_reg(inst_reg[3])) +: 16]; r = a - b; end
            else if (cmp_r_rm_w (inst_reg[4]))                          begin a = register[reg_w(field_reg(inst_reg[3])) +: 16]; b = data_reg; r = a - b; end
            else if (cmp_rm_i_b (inst_reg[4], inst_reg[3]))             begin a = data_reg; b =                     inst_reg[2] ; r = a - b;  end
            else if (cmp_rm_zi_w(inst_reg[4], inst_reg[3]))             begin a = data_reg; b = {inst_reg[1],       inst_reg[2]}; r = a - b; end
            else if (cmp_rm_si_w(inst_reg[4], inst_reg[3]))             begin a = data_reg; b = {8{inst_reg[2][7]}, inst_reg[2]}; r = a - b; end
            else if (cmp_a_i_b  (inst_reg[4]))                          begin a = `AL; b = data_reg; r = a - b; end
            else if (cmp_a_i_w  (inst_reg[4]))                          begin a = `AX; b = data_reg; r = a - b; end
            else if (inc_rm_b   (inst_reg[4], inst_reg[3]))             begin a = data_reg; b = 16'b1; r = a + b; end
            else if (inc_rm_w   (inst_reg[4], inst_reg[3]))             begin a = data_reg; b = 16'b1; r = a + b; end
            else if (inc_r      (inst_reg[4], inst_reg[3]))             begin a = register[reg_w(field_r_m(inst_reg[4])) +: 16]; b = 16'b1; r = a + b; end
            else if (dec_rm_b   (inst_reg[4], inst_reg[3]))             begin a = data_reg; b = 16'b1; r = a - b; end
            else if (dec_rm_w   (inst_reg[4], inst_reg[3]))             begin a = data_reg; b = 16'b1; r = a - b; end
            else if (dec_r      (inst_reg[4], inst_reg[3]))             begin a = register[reg_w(field_r_m(inst_reg[4])) +: 16]; b = 16'b1; r = a - b; end
            else if (neg_rm_b   (inst_reg[4], inst_reg[3]))             begin a = 'b0; b = data_reg; r = a - b; end
            else if (neg_rm_w   (inst_reg[4], inst_reg[3]))             begin a = 'b0; b = data_reg; r = a - b; end
            else if (neg_r      (inst_reg[4], inst_reg[3]))             begin a = 'b0; b = register[reg_w(field_r_m(inst_reg[4])) +: 16]; r = a - b; end
            else                                                        begin a = 'b0; b = 'b0; r = 'b0; end
        end
    end

    reg [127:0] register;

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            for (i = 0; i < 16; i = i + 1) begin
                register <= 'b0;
            end
        end
        else if (first_byte[4] && is_reg_mod(inst_reg[3])) begin
            if      (
                mov_rm_r_b  (inst_reg[4]) ||
                mov_rm_i_b  (inst_reg[4], inst_reg[3])
            )                                                           register[reg_b(field_r_m(inst_reg[3])) +:  8] <= data_reg[7:0];
            else if (
                mov_rm_r_w  (inst_reg[4]) ||
                mov_rm_sr   (inst_reg[4]) ||
                mov_rm_i_w  (inst_reg[4], inst_reg[3])
            )                                                           register[reg_w(field_r_m(inst_reg[3])) +: 16] <= data_reg;
            else if (
                add_rm_r_b  (inst_reg[4]) ||
                adc_rm_r_b  (inst_reg[4]) ||
                sub_rm_r_b  (inst_reg[4]) ||
                sbb_rm_r_b  (inst_reg[4]) ||
                add_rm_i_b  (inst_reg[4], inst_reg[3]) ||
                adc_rm_i_b  (inst_reg[4], inst_reg[3]) ||
                sub_rm_i_b  (inst_reg[4], inst_reg[3]) ||
                sbb_rm_i_b  (inst_reg[4], inst_reg[3]) ||
                inc_rm_b    (inst_reg[4], inst_reg[3]) ||
                dec_rm_b    (inst_reg[4], inst_reg[3]) ||
                neg_rm_b    (inst_reg[4], inst_reg[3])
            )                                                           register[reg_b(field_r_m(inst_reg[3])) +:  8] <= r[7:0];
            else if (
                add_rm_r_w  (inst_reg[4]) ||
                adc_rm_r_w  (inst_reg[4]) ||
                sub_rm_r_w  (inst_reg[4]) ||
                sbb_rm_r_w  (inst_reg[4]) ||
                add_rm_zi_w (inst_reg[4], inst_reg[3]) ||
                add_rm_si_w (inst_reg[4], inst_reg[3]) ||
                adc_rm_zi_w (inst_reg[4], inst_reg[3]) ||
                adc_rm_si_w (inst_reg[4], inst_reg[3]) ||
                sub_rm_zi_w (inst_reg[4], inst_reg[3]) ||
                sub_rm_si_w (inst_reg[4], inst_reg[3]) ||
                sbb_rm_zi_w (inst_reg[4], inst_reg[3]) ||
                sbb_rm_si_w (inst_reg[4], inst_reg[3]) ||
                inc_rm_w    (inst_reg[4], inst_reg[3]) ||
                dec_rm_w    (inst_reg[4], inst_reg[3]) ||
                neg_rm_w    (inst_reg[4], inst_reg[3])
            )                                                           register[reg_w(field_r_m(inst_reg[3])) +: 16] <= r;
            else if (
                pop_rm      (inst_reg[4])
            )                                                           begin register[reg_w(field_r_m(inst_reg[3])) +: 16] <= data_reg; `SP <= `SP + 'h2; end
            else if (xchg_r_rm_b(inst_reg[4]))                          {register[reg_b(field_reg(inst_reg[3])) +:  8], register[reg_b(field_r_m(inst_reg[3])) +:  8]} <= {register[reg_b(field_r_m(inst_reg[3])) +:  8], register[reg_b(field_reg(inst_reg[3])) +:  8]};
            else if (xchg_r_rm_w(inst_reg[4]))                          {register[reg_w(field_reg(inst_reg[3])) +: 16], register[reg_w(field_r_m(inst_reg[3])) +: 16]} <= {register[reg_w(field_r_m(inst_reg[3])) +: 16], register[reg_w(field_reg(inst_reg[3])) +: 16]};

        end
        else if (first_byte[4]) begin
            if      (
                mov_r_rm_b  (inst_reg[4]) ||
                xchg_r_rm_b (inst_reg[4])
            )                                                           register[reg_b(field_reg(inst_reg[3])) +:  8] <= data_reg[7:0];
            else if (
                mov_r_rm_w  (inst_reg[4]) ||
                xchg_r_rm_w (inst_reg[4]) ||
                lds         (inst_reg[4]) ||
                les         (inst_reg[4])
            )                                                           register[reg_w(field_reg(inst_reg[3])) +: 16] <= data_reg;
            else if (
                mov_r_i_b   (inst_reg[4])
            )                                                           register[reg_b(field_r_m(inst_reg[3])) +:  8] <= data_reg[7:0];
            else if (
                mov_r_i_w   (inst_reg[4])
            )                                                           register[reg_w(field_r_m(inst_reg[3])) +: 16] <= data_reg;
            else if (
                mov_a_m_b   (inst_reg[4]) ||
                xlat        (inst_reg[4])
            )                                                           `AL <= data_reg[7:0];
            else if (
                lahf        (inst_reg[4])
            )                                                           `AH <= data_reg[7:0];
            else if (
                mov_a_m_w   (inst_reg[4])
            )                                                           `AX <= data_reg;
            else if (
                push_rm     (inst_reg[4]) ||
                push_r      (inst_reg[4]) ||
                push_sr     (inst_reg[4]) ||
                pushf       (inst_reg[4])
            )                                                           `SP <= `SP - 'h2;
            else if (pop_r      (inst_reg[4]))                          begin register[reg_w(field_r_m(inst_reg[4])) +: 16] <= data_reg; `SP <= `SP + 'h2; end
            else if (pop_sr     (inst_reg[4]))                          begin segment_register[field_reg(inst_reg[4])[1:0]] <= data_reg; `SP <= `SP + 'h2; end
            else if (popf       (inst_reg[4]))                          `SP <= `SP + 'h2;
            else if (
                add_r_rm_b  (inst_reg[4]) ||
                adc_r_rm_b  (inst_reg[4]) ||
                sub_r_rm_b  (inst_reg[4]) ||
                sbb_r_rm_b  (inst_reg[4]) 
            )                                                           register[reg_b(field_reg(inst_reg[3])) +:  8] <= r[7:0];
            else if (
                add_r_rm_w  (inst_reg[4]) ||
                adc_r_rm_w  (inst_reg[4]) ||
                sub_r_rm_w  (inst_reg[4]) ||
                sbb_r_rm_w  (inst_reg[4]) 
            )                                                           register[reg_w(field_reg(inst_reg[3])) +: 16] <= r;
            else if (
                add_a_i_b   (inst_reg[4]) ||
                adc_a_i_b   (inst_reg[4]) ||
                sub_a_i_b   (inst_reg[4]) ||
                sbb_a_i_b   (inst_reg[4]) 
            )                                                           `AL <= r[7:0];
            else if (
                add_a_i_w   (inst_reg[4]) ||
                adc_a_i_w   (inst_reg[4]) ||
                sub_a_i_w   (inst_reg[4]) ||
                sbb_a_i_w   (inst_reg[4]) 
            )                                                           `AX <= r;
            else if (
                inc_r       (inst_reg[4], inst_reg[3]) ||
                dec_r       (inst_reg[4], inst_reg[3]) ||
            )                                                           register[reg_w(field_r_m(inst_reg[4])) +: 16] <= r;
            else if (lea        (inst_reg[4]))                          register[reg_w(field_reg(inst_reg[3])) +: 16] <= addr_reg;
            else if (aaa        (inst_reg[4]))                          {`AH, `AL} <= `AL & 8'h0f > 8'h09 | `AF ? {`AH + 8'h1, `AL + 8'h6} : {`AH, `AL};
            else if (daa        (inst_reg[4]))                          `AL <= `AL + (`AL & 8'h0f > 8'h09 | `AF ? 8'h6 : 8'h0) + (`AL > 8'h9f | `CF ? 8'h60 : 8'h00);
            else if (aas        (inst_reg[4]))                          {`AH, `AL} <= `AL & 8'h0f > 8'h09 | `AF ? {`AH - 8'h1, `AL - 8'h6} : {`AH, `AL};
            else if (das        (inst_reg[4]))                          `AL <= `AL - (`AL & 8'h0f > 8'h09 | `AF ? 8'h6 : 8'h0) - (`AL > 8'h9f | `CF ? 8'h60 : 8'h00);
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
            if      (mov_sr_rm  (inst_reg[4]))                  segment_register[field_reg(inst_reg[3])[1:0]] <= data_reg;
            else if (lds        (inst_reg[4]))                  `DS <= ram_rd_data;
            else if (les        (inst_reg[4]))                  `ES <= ram_rd_data;
        end
    end

    reg [15:0] flags;

    always @(posedge clk or negedge rst) begin
        if (~rst)
            flags <= 'b0;
        else if (first_byte[4]) begin
            if      (sahf       (inst_reg[4]))                  flags[ 7:0] <= data_reg[ 7:0];
            else if (popf       (inst_reg[4]))                  flags[15:0] <= data_reg[15:0];
            else if (
                add_rm_r_b  (inst_reg[4]) ||
                add_r_rm_b  (inst_reg[4]) ||
                add_a_i_b   (inst_reg[4]) ||
                adc_rm_r_b  (inst_reg[4]) ||
                adc_r_rm_b  (inst_reg[4]) ||
                adc_a_i_b   (inst_reg[4]) ||
                add_rm_i_b  (inst_reg[4], inst_reg[3]) ||
                adc_rm_i_b  (inst_reg[4], inst_reg[3]) ||
                inc_rm_b    (inst_reg[4], inst_reg[3])
            )                                                   begin `OF <= of_b(a,b,r); `SF <= sf_b(r); `ZF <= zf_b(r); `AF <= af_b(a,b,'d0); `PF <= pf_b(r); `CF <= cf_b(a,b,'d0) end
            else if (
                add_rm_r_w  (inst_reg[4]) ||
                add_r_rm_w  (inst_reg[4]) ||
                add_a_i_w   (inst_reg[4]) ||
                adc_rm_r_w  (inst_reg[4]) ||
                adc_r_rm_w  (inst_reg[4]) ||
                adc_a_i_w   (inst_reg[4]) ||
                add_rm_zi_w (inst_reg[4], inst_reg[3]) ||
                add_rm_si_w (inst_reg[4], inst_reg[3]) ||
                adc_rm_zi_w (inst_reg[4], inst_reg[3]) ||
                adc_rm_si_w (inst_reg[4], inst_reg[3]) ||
                inc_rm_w    (inst_reg[4], inst_reg[3]) ||
                inc_r       (inst_reg[4], inst_reg[3])
            )                                                   begin `OF <= of_w(a,b,r); `SF <= sf_w(r); `ZF <= zf_w(r); `AF <= af_w(a,b,'d1); `PF <= pf_w(r); `CF <= cf_w(a,b,'d1) end
            else if (
                sub_rm_r_b  (inst_reg[4]) ||
                sub_r_rm_b  (inst_reg[4]) ||
                sub_a_i_b   (inst_reg[4]) ||
                sbb_rm_r_b  (inst_reg[4]) ||
                sbb_r_rm_b  (inst_reg[4]) ||
                sbb_a_i_b   (inst_reg[4]) ||
                cmp_rm_r_b  (inst_reg[4]) ||
                cmp_r_rm_b  (inst_reg[4]) ||
                cmp_a_i_b   (inst_reg[4]) ||
                sub_rm_i_b  (inst_reg[4], inst_reg[3]) ||
                sbb_rm_i_b  (inst_reg[4], inst_reg[3]) ||
                cmp_rm_b    (inst_reg[4], inst_reg[3]) ||
                dec_rm_b    (inst_reg[4], inst_reg[3]) ||
                neg_rm_b    (inst_reg[4], inst_reg[3]) 
            )                                                   begin `OF <= of_b(a,-b,r); `SF <= sf_b(r); `ZF <= zf_b(r); `AF <= af_b(a,-b,'d0); `PF <= pf_b(r); `CF <= cf_b(a,-b,'d0) end
            else if (
                sub_rm_r_w  (inst_reg[4]) ||
                sub_r_rm_w  (inst_reg[4]) ||
                sub_a_i_w   (inst_reg[4]) ||
                sbb_rm_r_w  (inst_reg[4]) ||
                sbb_r_rm_w  (inst_reg[4]) ||
                sbb_a_i_w   (inst_reg[4]) ||
                cmp_rm_r_w  (inst_reg[4]) ||
                cmp_r_rm_w  (inst_reg[4]) ||
                cmp_a_i_w   (inst_reg[4]) ||
                sub_rm_zi_w (inst_reg[4], inst_reg[3]) ||
                sub_rm_si_w (inst_reg[4], inst_reg[3]) ||
                sbb_rm_zi_w (inst_reg[4], inst_reg[3]) ||
                sbb_rm_si_w (inst_reg[4], inst_reg[3]) ||
                cmp_rm_zi_w (inst_reg[4], inst_reg[3]) ||
                cmp_rm_si_w (inst_reg[4], inst_reg[3]) ||
                dec_rm_w    (inst_reg[4], inst_reg[3]) ||
                dec_r       (inst_reg[4], inst_reg[3]) ||
                neg_rm_w    (inst_reg[4], inst_reg[3]) 
            )                                                   begin `OF <= of_w(a,-b,r); `SF <= sf_w(r); `ZF <= zf_w(r); `AF <= af_w(a,-b,-'d1); `PF <= pf_w(r); `CF <= cf_w(a,-b,-'d1) end
            else if (aaa        (inst_reg[4]))                  {`AF, `CF} <= {2{`AL & 8'h0f > 8'h9 | `AF}};
            else if (daa        (inst_reg[4]))                  {`AF, `CF} <= {`AL & 8'h0f > 8'h9 | `AF, `AL > 8'h9f | `CF};
            else if (aas        (inst_reg[4]))                  {`AF, `CF} <= {2{`AL & 8'h0f > 8'h9 | `AF}};
            else if (das        (inst_reg[4]))                  {`AF, `CF} <= {`AL & 8'h0f > 8'h9 | `AF, `AL > 8'h9f | `CF};
        end
    end

    assign ram_rd_en = (first_byte[3] && is_mem_mod(inst_reg[2]) && (
        mov_r_rm_b (inst_reg[3]) || mov_r_rm_w (inst_reg[3]) ||
        xchg_r_rm_b(inst_reg[3]) || xchg_r_rm_w(inst_reg[3]) ||
        add_rm_r_b (inst_reg[3]) || add_r_rm_b (inst_reg[3]) ||
        add_rm_r_w (inst_reg[3]) || add_r_rm_w (inst_reg[3]) ||
        adc_rm_r_b (inst_reg[3]) || adc_r_rm_b (inst_reg[3]) ||
        adc_rm_r_w (inst_reg[3]) || adc_r_rm_w (inst_reg[3]) ||
        sub_rm_r_b (inst_reg[3]) || sub_r_rm_b (inst_reg[3]) ||
        sub_rm_r_w (inst_reg[3]) || sub_r_rm_w (inst_reg[3]) ||
        sbb_rm_r_b (inst_reg[3]) || sbb_r_rm_b (inst_reg[3]) ||
        sbb_rm_r_w (inst_reg[3]) || sbb_r_rm_w (inst_reg[3]) ||
        cmp_rm_r_b (inst_reg[3]) || cmp_r_rm_b (inst_reg[3]) ||
        cmp_rm_r_w (inst_reg[3]) || cmp_r_rm_w (inst_reg[3]) ||
        push_rm    (inst_reg[3]) ||
        add_rm_i_b (inst_reg[3], inst_reg[2]) ||
        add_rm_zi_w(inst_reg[3], inst_reg[2]) ||
        add_rm_si_w(inst_reg[3], inst_reg[2]) ||
        adc_rm_i_b (inst_reg[3], inst_reg[2]) ||
        adc_rm_zi_w(inst_reg[3], inst_reg[2]) ||
        adc_rm_si_w(inst_reg[3], inst_reg[2]) ||
        sub_rm_i_b (inst_reg[3], inst_reg[2]) ||
        sub_rm_zi_w(inst_reg[3], inst_reg[2]) ||
        sub_rm_si_w(inst_reg[3], inst_reg[2]) ||
        sbb_rm_i_b (inst_reg[3], inst_reg[2]) ||
        sbb_rm_zi_w(inst_reg[3], inst_reg[2]) ||
        sbb_rm_si_w(inst_reg[3], inst_reg[2]) ||
        cmp_rm_i_b (inst_reg[3], inst_reg[2]) ||
        cmp_rm_zi_w(inst_reg[3], inst_reg[2]) ||
        cmp_rm_si_w(inst_reg[3], inst_reg[2]) ||
        inc_rm_b   (inst_reg[3], inst_reg[2]) ||
        inc_rm_w   (inst_reg[3], inst_reg[2]) ||
        dec_rm_b   (inst_reg[3], inst_reg[2]) ||
        dec_rm_w   (inst_reg[3], inst_reg[2]) ||
        neg_rm_b   (inst_reg[3], inst_reg[2]) ||
        neg_rm_w   (inst_reg[3], inst_reg[2]) 
    )) || (first_byte[3] && (
        mov_a_m_b  (inst_reg[3]) ||
        mov_a_m_w  (inst_reg[3]) ||
        pop_rm     (inst_reg[3]) ||
        pop_r      (inst_reg[3]) ||
        pop_sr     (inst_reg[3]) ||
        popf       (inst_reg[3]) ||
        xlat       (inst_reg[3]) ||
        lds        (inst_reg[3]) ||
        les        (inst_reg[3])
    )) || (first_byte[4] && (
        lds        (inst_reg[4]) ||
        les        (inst_reg[4])
    ));

    assign ram_rd_we = (first_byte[3] && is_mem_mod(inst_reg[2]) && (
        mov_r_rm_w (inst_reg[3]) ||
        push_rm    (inst_reg[3]) ||
        xchg_r_rm_w(inst_reg[3]) ||
        add_rm_r_w (inst_reg[3]) ||
        add_r_rm_w (inst_reg[3]) ||
        adc_rm_r_w (inst_reg[3]) ||
        adc_r_rm_w (inst_reg[3]) ||
        sub_rm_r_w (inst_reg[3]) ||
        sub_r_rm_w (inst_reg[3]) ||
        sbb_rm_r_w (inst_reg[3]) ||
        sbb_r_rm_w (inst_reg[3]) ||
        cmp_rm_r_w (inst_reg[3]) ||
        cmp_r_rm_w (inst_reg[3]) ||
        add_rm_zi_w(inst_reg[3], inst_reg[2]) ||
        add_rm_si_w(inst_reg[3], inst_reg[2]) ||
        adc_rm_zi_w(inst_reg[3], inst_reg[2]) ||
        adc_rm_si_w(inst_reg[3], inst_reg[2]) ||
        sub_rm_zi_w(inst_reg[3], inst_reg[2]) ||
        sub_rm_si_w(inst_reg[3], inst_reg[2]) ||
        sbb_rm_zi_w(inst_reg[3], inst_reg[2]) ||
        sbb_rm_si_w(inst_reg[3], inst_reg[2]) ||
        cmp_rm_zi_w(inst_reg[3], inst_reg[2]) ||
        cmp_rm_si_w(inst_reg[3], inst_reg[2]) ||
        inc_rm_w   (inst_reg[3], inst_reg[2]) ||
        dec_rm_w   (inst_reg[3], inst_reg[2]) ||
        neg_rm_w   (inst_reg[3], inst_reg[2])
    )) || (first_byte[3] && (
        mov_a_m_w  (inst_reg[3]) ||
        pop_rm     (inst_reg[3]) ||
        pop_r      (inst_reg[3]) ||
        pop_sr     (inst_reg[3]) ||
        lds        (inst_reg[3]) ||
        les        (inst_reg[3]) ||
        popf       (inst_reg[3])
    )) || (first_byte[4] && (
        lds        (inst_reg[4]) ||
        les        (inst_reg[4])
    ));

    reg [19:0] ram_rd_addr_signal;

    always @(*) begin
        if (~rst)
            ram_rd_addr_signal = 'b0;
        else if ((first_byte[3] && is_mem_mod(inst_reg[2]) && (
            mov_r_rm_b (inst_reg[3]) || mov_r_rm_w (inst_reg[3]) ||
            xchg_r_rm_b(inst_reg[3]) || xchg_r_rm_w(inst_reg[3]) ||
            add_rm_r_b (inst_reg[3]) || add_r_rm_b (inst_reg[3]) ||
            add_rm_r_w (inst_reg[3]) || add_r_rm_w (inst_reg[3]) ||
            adc_rm_r_b (inst_reg[3]) || adc_r_rm_b (inst_reg[3]) ||
            adc_rm_r_w (inst_reg[3]) || adc_r_rm_w (inst_reg[3]) ||
            sub_rm_r_b (inst_reg[3]) || sub_r_rm_b (inst_reg[3]) ||
            sub_rm_r_w (inst_reg[3]) || sub_r_rm_w (inst_reg[3]) ||
            sbb_rm_r_b (inst_reg[3]) || sbb_r_rm_b (inst_reg[3]) ||
            sbb_rm_r_w (inst_reg[3]) || sbb_r_rm_w (inst_reg[3]) ||
            cmp_rm_r_b (inst_reg[3]) || cmp_r_rm_b (inst_reg[3]) ||
            cmp_rm_r_w (inst_reg[3]) || cmp_r_rm_w (inst_reg[3]) ||
            push_rm    (inst_reg[3]) ||
            add_rm_i_b (inst_reg[3], inst_reg[2]) ||
            add_rm_zi_w(inst_reg[3], inst_reg[2]) ||
            add_rm_si_w(inst_reg[3], inst_reg[2]) ||
            adc_rm_i_b (inst_reg[3], inst_reg[2]) ||
            adc_rm_zi_w(inst_reg[3], inst_reg[2]) ||
            adc_rm_si_w(inst_reg[3], inst_reg[2]) ||
            sub_rm_i_b (inst_reg[3], inst_reg[2]) ||
            sub_rm_zi_w(inst_reg[3], inst_reg[2]) ||
            sub_rm_si_w(inst_reg[3], inst_reg[2]) ||
            sbb_rm_i_b (inst_reg[3], inst_reg[2]) ||
            sbb_rm_zi_w(inst_reg[3], inst_reg[2]) ||
            sbb_rm_si_w(inst_reg[3], inst_reg[2]) ||
            cmp_rm_i_b (inst_reg[3], inst_reg[2]) ||
            cmp_rm_zi_w(inst_reg[3], inst_reg[2]) ||
            cmp_rm_si_w(inst_reg[3], inst_reg[2]) ||
            inc_rm_b   (inst_reg[3], inst_reg[2]) ||
            inc_rm_w   (inst_reg[3], inst_reg[2]) ||
            dec_rm_b   (inst_reg[3], inst_reg[2]) ||
            dec_rm_w   (inst_reg[3], inst_reg[2]) ||
            neg_rm_b   (inst_reg[3], inst_reg[2]) ||
            neg_rm_w   (inst_reg[3], inst_reg[2])
        )) || (first_byte[3] && (
            mov_a_m_b  (inst_reg[3]) ||
            mov_a_m_w  (inst_reg[3])
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
        xchg_r_rm_b(inst_reg[4]) || xchg_r_rm_w(inst_reg[4]) ||
        add_rm_r_b (inst_reg[4]) || add_rm_r_w (inst_reg[4]) ||
        adc_rm_r_b (inst_reg[4]) || adc_rm_r_w (inst_reg[4]) ||
        sub_rm_r_b (inst_reg[4]) || sub_rm_r_w (inst_reg[4]) ||
        sbb_rm_r_b (inst_reg[4]) || sbb_rm_r_w (inst_reg[4]) ||
        mov_rm_i_b (inst_reg[4], inst_reg[3]) ||
        mov_rm_i_w (inst_reg[4], inst_reg[3]) ||
        add_rm_i_b (inst_reg[4], inst_reg[3]) ||
        add_rm_zi_w(inst_reg[4], inst_reg[3]) ||
        add_rm_si_w(inst_reg[4], inst_reg[3]) ||
        adc_rm_i_b (inst_reg[4], inst_reg[3]) ||
        adc_rm_zi_w(inst_reg[4], inst_reg[3]) ||
        adc_rm_si_w(inst_reg[4], inst_reg[3]) ||
        sub_rm_i_b (inst_reg[4], inst_reg[3]) ||
        sub_rm_zi_w(inst_reg[4], inst_reg[3]) ||
        sub_rm_si_w(inst_reg[4], inst_reg[3]) ||
        sbb_rm_i_b (inst_reg[4], inst_reg[3]) ||
        sbb_rm_zi_w(inst_reg[4], inst_reg[3]) ||
        sbb_rm_si_w(inst_reg[4], inst_reg[3]) ||
        inc_rm_b   (inst_reg[4], inst_reg[3]) ||
        inc_rm_w   (inst_reg[4], inst_reg[3]) ||
        dec_rm_b   (inst_reg[4], inst_reg[3]) ||
        dec_rm_w   (inst_reg[4], inst_reg[3]) ||
        neg_rm_b   (inst_reg[4], inst_reg[3]) ||
        neg_rm_w   (inst_reg[4], inst_reg[3]) 
    )) || (first_byte[4] && (
        mov_m_a_b  (inst_reg[4]) ||
        mov_m_a_w  (inst_reg[4]) ||
        push_rm    (inst_reg[4]) ||
        push_r     (inst_reg[4]) ||
        push_sr    (inst_reg[4]) ||
        pushf      (inst_reg[4])
    ));
    
    assign ram_wr_we = (first_byte[4] && is_mem_mod(inst_reg[3]) && (
        mov_rm_r_w (inst_reg[4]) ||
        mov_rm_i_w (inst_reg[4]) ||
        xchg_r_rm_w(inst_reg[4]) ||
        add_rm_r_w (inst_reg[4]) ||
        adc_rm_r_w (inst_reg[4]) ||
        sub_rm_r_w (inst_reg[4]) ||
        sbb_rm_r_w (inst_reg[4]) ||
        add_rm_zi_w(inst_reg[4], inst_reg[3]) ||
        add_rm_si_w(inst_reg[4], inst_reg[3]) ||
        adc_rm_zi_w(inst_reg[4], inst_reg[3]) ||
        adc_rm_si_w(inst_reg[4], inst_reg[3]) ||
        sub_rm_zi_w(inst_reg[4], inst_reg[3]) ||
        sub_rm_si_w(inst_reg[4], inst_reg[3]) ||
        sbb_rm_zi_w(inst_reg[4], inst_reg[3]) ||
        sbb_rm_si_w(inst_reg[4], inst_reg[3]) ||
        inc_rm_w   (inst_reg[4], inst_reg[3]) ||
        dec_rm_w   (inst_reg[4], inst_reg[3]) ||
        neg_rm_w   (inst_reg[4], inst_reg[3]) 
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
            xchg_r_rm_b(inst_reg[4]) || xchg_r_rm_w(inst_reg[4]) ||
            add_rm_r_b (inst_reg[4]) || add_rm_r_w (inst_reg[4]) ||
            adc_rm_r_b (inst_reg[4]) || adc_rm_r_w (inst_reg[4]) ||
            sub_rm_r_b (inst_reg[4]) || sub_rm_r_w (inst_reg[4]) ||
            sbb_rm_r_b (inst_reg[4]) || sbb_rm_r_w (inst_reg[4]) ||
            mov_rm_i_b (inst_reg[4], inst_reg[3]) ||
            mov_rm_i_w (inst_reg[4], inst_reg[3]) ||
            add_rm_i_b (inst_reg[4], inst_reg[3]) ||
            add_rm_zi_w(inst_reg[4], inst_reg[3]) ||
            add_rm_si_w(inst_reg[4], inst_reg[3]) ||
            adc_rm_i_b (inst_reg[4], inst_reg[3]) ||
            adc_rm_zi_w(inst_reg[4], inst_reg[3]) ||
            adc_rm_si_w(inst_reg[4], inst_reg[3]) ||
            sub_rm_i_b (inst_reg[4], inst_reg[3]) ||
            sub_rm_zi_w(inst_reg[4], inst_reg[3]) ||
            sub_rm_si_w(inst_reg[4], inst_reg[3]) ||
            sbb_rm_i_b (inst_reg[4], inst_reg[3]) ||
            sbb_rm_zi_w(inst_reg[4], inst_reg[3]) ||
            sbb_rm_si_w(inst_reg[4], inst_reg[3]) ||
            inc_rm_b   (inst_reg[4], inst_reg[3]) ||
            inc_rm_w   (inst_reg[4], inst_reg[3]) ||
            dec_rm_b   (inst_reg[4], inst_reg[3]) ||
            dec_rm_w   (inst_reg[4], inst_reg[3]) ||
            neg_rm_b   (inst_reg[4], inst_reg[3]) ||
            neg_rm_w   (inst_reg[4], inst_reg[3]) 
        )) || (first_byte[4] && (
            mov_m_a_b  (inst_reg[4]) ||
            mov_m_a_w  (inst_reg[4])
        )))
            ram_wr_addr_signal = {`DS, 4'b0} + addr_reg;
        else if (first_byte[4] && (
            push_rm    (inst_reg[4]) ||
            push_r     (inst_reg[4]) ||
            push_sr    (inst_reg[4]) ||
            pushf      (inst_reg[4])
        ))
            ram_wr_addr_signal = {`SS, 4'b0} + `SP - 'h2;
        else
            ram_wr_addr_signal = 'b0;
    end

    assign ram_wr_addr = ram_wr_addr_signal;

    reg [15:0] ram_wr_data_signal;

    always @(*) begin
        if (~rst)
            ram_wr_data_signal = 'b0;
        else if (first_byte[4] && is_mem_mod(inst_reg[3] && (
            mov_rm_r_b (inst_reg[4]) ||
            mov_rm_r_w (inst_reg[4])
        )) || (first_byte[4] && (
            mov_m_a_b  (inst_reg[4]) ||
            mov_m_a_w  (inst_reg[4]) ||
            push_rm    (inst_reg[4]) ||
            push_r     (inst_reg[4]) ||
            push_sr    (inst_reg[4]) ||
            pushf      (inst_reg[4])
        )))
            ram_wr_data_signal = data_reg;
        else if ((first_byte[4] && is_mem_mod(inst_reg[3]) && mov_rm_i_b(inst_reg[4], inst_reg[3]))
            ram_wr_data_signal = {8'b0, 
                disp0(inst_reg[3]) ? inst_reg[2] :
                disp1(inst_reg[3]) ? inst_reg[1] :
                disp2(inst_reg[3]) ? inst_reg[0] :
                'b0
            };
        else if ((first_byte[4] && is_mem_mod(inst_reg[3]) && mov_rm_i_w(inst_reg[4], inst_reg[3]))
            ram_wr_data_signal = 
                disp0(inst_reg[3]) ? {inst_reg[1], inst_reg[2]} :
                disp1(inst_reg[3]) ? {inst_reg[0], inst_reg[1]} :
                disp2(inst_reg[3]) ? {rom_data,    inst_reg[0]} :
                'b0;
        else if ((first_byte[4] && is_mem_mod(inst_reg[3]) && xchg_r_rm_b(inst_reg[4]))
            ram_wr_data_signal = register[reg_b(field_reg(inst_reg[3])) +:  8];
        else if ((first_byte[4] && is_mem_mod(inst_reg[3]) && xchg_r_rm_w(inst_reg[4]))
            ram_wr_data_signal = register[reg_w(field_reg(inst_reg[3])) +: 16];
        else if ((first_byte[4] && is_mem_mod(inst_reg[3]) && (
            add_rm_r_b (inst_reg[4]) || add_rm_r_w (inst_reg[4]) ||
            adc_rm_r_b (inst_reg[4]) || adc_rm_r_w (inst_reg[4]) ||
            sub_rm_r_b (inst_reg[4]) || sub_rm_r_w (inst_reg[4]) ||
            sbb_rm_r_b (inst_reg[4]) || sbb_rm_r_w (inst_reg[4]) ||
            add_rm_i_b (inst_reg[4], inst_reg[3]) ||
            add_rm_zi_w(inst_reg[4], inst_reg[3]) ||
            add_rm_si_w(inst_reg[4], inst_reg[3]) ||
            adc_rm_i_b (inst_reg[4], inst_reg[3]) ||
            adc_rm_zi_w(inst_reg[4], inst_reg[3]) ||
            adc_rm_si_w(inst_reg[4], inst_reg[3]) ||
            sub_rm_i_b (inst_reg[4], inst_reg[3]) ||
            sub_rm_zi_w(inst_reg[4], inst_reg[3]) ||
            sub_rm_si_w(inst_reg[4], inst_reg[3]) ||
            sbb_rm_i_b (inst_reg[4], inst_reg[3]) ||
            sbb_rm_zi_w(inst_reg[4], inst_reg[3]) ||
            sbb_rm_si_w(inst_reg[4], inst_reg[3]) ||
            inc_rm_b   (inst_reg[4], inst_reg[3]) ||
            inc_rm_w   (inst_reg[4], inst_reg[3]) ||
            dec_rm_b   (inst_reg[4], inst_reg[3]) ||
            dec_rm_w   (inst_reg[4], inst_reg[3]) ||
            neg_rm_b   (inst_reg[4], inst_reg[3]) ||
            neg_rm_w   (inst_reg[4], inst_reg[3]) 
        )))
            ram_wr_data_signal = r;
        else
            ram_wr_data_signal = 'b0;
    end

    assign ram_wr_data = ram_wr_data_signal;

endmodule