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
    output          ram_rd_de,
    output  [19:0]  ram_rd_addr,
    input   [31:0]  ram_rd_data,

    output          ram_wr_en,
    output          ram_wr_we,
    output          ram_wr_de,
    output  [19:0]  ram_wr_addr,
    output  [31:0]  ram_wr_data
);

    `include "def.v"

    integer i;

    reg [15:0] ip;

    always @(posedge clk or negedge rst) begin
        if (~rst) ip <= 'b0;
        else if (first_byte[4] && (
            call_rm_dir (ir[4], ir[3]) ||
            call_rm_ptr (ir[4], ir[3]) ||
            jmp_rm_dir  (ir[4], ir[3]) ||
            jmp_rm_ptr  (ir[4], ir[3]) ||
            ret         (ir[4], ir[3]) ||
            ret_i       (ir[4], ir[3]) ||
            retf        (ir[4], ir[3]) ||
            retf_i      (ir[4], ir[3])              
        )) ip <= data_reg;
        else if (first_byte[4] && call_i_dir  (ir[4], ir[3])) ip <= ip + {ir[2], ir[3]};
        else if (first_byte[4] && call_i_ptr  (ir[4], ir[3])) ip <=      {ir[3], ir[4]};
        else if (first_byte[4] && jmp_i_dir_b (ir[4], ir[3])) ip <= ip + {8'h00, ir[3]};
        else if (first_byte[4] && jmp_i_dir_w (ir[4], ir[3])) ip <= ip + {ir[2], ir[3]};
        else if (first_byte[4] && jmp_i_ptr   (ir[4], ir[3])) ip <=      {ir[2], ir[3]};
        else if (first_byte[0] && (
            cmps_b(ir[0], rom_data) ||
            cmps_w(ir[0], rom_data)
        ) || (
            rep_z (pr) && ~`CX &&  `ZF ||
            rep_nz(pr) && ~`CX && ~`ZF
        )) begin end
        else ip <= ip + 'b1;
    end

    reg [7:0] ir [4:0];

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            for (i = 0; i < 5; i = i + 1) begin
                ir[i] <= 'b0;
            end
        end
        else if (
            rep_z   (pr) && ~`CX &&  `ZF ||
            rep_nz  (pr) && ~`CX && ~`ZF
        ) begin
            
        end
        else begin
            for (i = 1; i < 5; i = i + 1) begin
                ir[i] <= (i == 0) ? rom_data : ir[i-1];
            end
        end
    end

    reg [7:0] pr;

    always @(posedge clk or negedge rst) begin
        if (~rst)
            pr <= 'b0;
        else if (first_byte[4] && (
            rep_z       (ir[4], ir[3]) && ~`CX &&  `ZF ||
            rep_nz      (ir[4], ir[3]) && ~`CX && ~`ZF ||
        ))
            pr <= ir[4];
        else if (
            rep_z       (pr,    ir[4]) && ~`CX &&  `ZF ||
            rep_nz      (pr,    ir[4]) && ~`CX && ~`ZF
        )
            pr <= pr;
        else
            pr <= 'b0;
    end

    reg [4:0] clear_byte;

    always @(*) begin
        if (~rst)
            clear_byte = 5'b11111;
        else if (first_byte[4] && (
            call_i_dir  (ir[4], ir[3]) ||
            call_i_ptr  (ir[4], ir[3]) ||
            call_rm_dir (ir[4], ir[3]) ||
            call_rm_ptr (ir[4], ir[3]) ||
            jmp_i_dir_b (ir[4], ir[3]) ||
            jmp_i_dir_w (ir[4], ir[3]) ||
            jmp_i_ptr   (ir[4], ir[3]) ||
            jmp_rm_dir  (ir[4], ir[3]) ||
            jmp_rm_ptr  (ir[4], ir[3]) ||
            ret         (ir[4], ir[3]) ||
            ret_i       (ir[4], ir[3]) ||
            retf        (ir[4], ir[3]) ||
            retf_i      (ir[4], ir[3]) 
        ))
            clear_byte = 5'b01111;
        else
            clear_byte = 5'b00000;
    end

    reg [4:0] first_byte;

    always @(posedge clk or negedge rst) begin
        if (~rst)
            first_byte <= 'b0;
        else
            first_byte <= {first_byte[3:0],  ~clear_byte[0] && ~(
                first_byte[4] && length6(ir[4], ir[3]) ||
                first_byte[3] && length5(ir[3], ir[2]) ||
                first_byte[2] && length4(ir[2], ir[1]) ||
                first_byte[1] && length3(ir[1], ir[0]) ||
                first_byte[0] && length2(ir[0], rom_data)
            )};
    end

    reg [15:0] disp_sel;

    always @(*) begin
        if (~rst) disp_sel = 'b0;
        else if (field_mod(ir[1]) == 2'b00) disp_sel = 'b0;
        else if (field_mod(ir[1]) == 2'b01) disp_sel = {8{ir[0][7]}, ir[0]};
        else if (field_mod(ir[1]) == 2'b10) disp_sel = {   rom_data, ir[0]};
        else disp_sel = 'b0;
    end

    reg [15:0] addr_reg;

    always @(posedge clk or negedge rst) begin
        if (~rst) addr_reg <= 'b0;
        else if (first_byte[2] && (
            mov_rm_r_b  (ir[2], ir[1]) || mov_r_rm_b  (ir[2], ir[1]) || mov_rm_r_w  (ir[2], ir[1]) || mov_r_rm_w  (ir[2], ir[1]) ||
            mov_rm_sr   (ir[2], ir[1]) || mov_sr_rm   (ir[2], ir[1]) ||
            push_rm     (ir[2], ir[1]) ||
            pop_rm      (ir[2], ir[1]) ||
            lea         (ir[2], ir[1]) ||
            lds         (ir[2], ir[1]) ||
            les         (ir[2], ir[1]) ||
            xchg_r_rm_b (ir[2], ir[1]) || xchg_r_rm_w (ir[2], ir[1]) ||
            add_rm_r_b  (ir[2], ir[1]) || add_r_rm_b  (ir[2], ir[1]) || add_rm_r_w  (ir[2], ir[1]) || add_r_rm_w  (ir[2], ir[1]) ||
            adc_rm_r_b  (ir[2], ir[1]) || adc_r_rm_b  (ir[2], ir[1]) || adc_rm_r_w  (ir[2], ir[1]) || adc_r_rm_w  (ir[2], ir[1]) ||
            sub_rm_r_b  (ir[2], ir[1]) || sub_r_rm_b  (ir[2], ir[1]) || sub_rm_r_w  (ir[2], ir[1]) || sub_r_rm_w  (ir[2], ir[1]) ||
            sbb_rm_r_b  (ir[2], ir[1]) || sbb_r_rm_b  (ir[2], ir[1]) || sbb_rm_r_w  (ir[2], ir[1]) || sbb_r_rm_w  (ir[2], ir[1]) ||
            cmp_rm_r_b  (ir[2], ir[1]) || cmp_r_rm_b  (ir[2], ir[1]) || cmp_rm_r_w  (ir[2], ir[1]) || cmp_r_rm_w  (ir[2], ir[1]) ||
            mov_rm_i_b  (ir[2], ir[1]) || mov_rm_i_w  (ir[2], ir[1]) ||
            add_rm_i_b  (ir[2], ir[1]) || add_rm_zi_w (ir[2], ir[1]) || add_rm_si_w (ir[2], ir[1]) ||
            adc_rm_i_b  (ir[2], ir[1]) || adc_rm_zi_w (ir[2], ir[1]) || adc_rm_si_w (ir[2], ir[1]) ||
            sub_rm_i_b  (ir[2], ir[1]) || sub_rm_zi_w (ir[2], ir[1]) || sub_rm_si_w (ir[2], ir[1]) ||
            sbb_rm_i_b  (ir[2], ir[1]) || sbb_rm_zi_w (ir[2], ir[1]) || sbb_rm_si_w (ir[2], ir[1]) ||
            cmp_rm_i_b  (ir[2], ir[1]) || cmp_rm_zi_w (ir[2], ir[1]) || cmp_rm_si_w (ir[2], ir[1]) ||
            inc_rm_b    (ir[2], ir[1]) || inc_rm_w    (ir[2], ir[1]) ||
            dec_rm_b    (ir[2], ir[1]) || dec_rm_w    (ir[2], ir[1]) ||
            neg_rm_b    (ir[2], ir[1]) || neg_rm_w    (ir[2], ir[1]) ||
            mul_r_rm_b  (ir[2], ir[1]) || mul_r_rm_w  (ir[2], ir[1]) ||
            imul_r_rm_b (ir[2], ir[1]) || imul_r_rm_w (ir[2], ir[1]) ||
            div_r_rm_b  (ir[2], ir[1]) || div_r_rm_w  (ir[2], ir[1]) ||
            idiv_r_rm_b (ir[2], ir[1]) || idiv_r_rm_w (ir[2], ir[1]) ||
            shl_rm_1_b  (ir[2], ir[1]) || shl_rm_1_w  (ir[2], ir[1]) || shl_rm_c_b  (ir[2], ir[1]) || shl_rm_c_w  (ir[2], ir[1]) ||
            shr_rm_1_b  (ir[2], ir[1]) || shr_rm_1_w  (ir[2], ir[1]) || shr_rm_c_b  (ir[2], ir[1]) || shr_rm_c_w  (ir[2], ir[1]) ||
            sar_rm_1_b  (ir[2], ir[1]) || sar_rm_1_w  (ir[2], ir[1]) || sar_rm_c_b  (ir[2], ir[1]) || sar_rm_c_w  (ir[2], ir[1]) ||
            rol_rm_1_b  (ir[2], ir[1]) || rol_rm_1_w  (ir[2], ir[1]) || rol_rm_c_b  (ir[2], ir[1]) || rol_rm_c_w  (ir[2], ir[1]) ||
            ror_rm_1_b  (ir[2], ir[1]) || ror_rm_1_w  (ir[2], ir[1]) || ror_rm_c_b  (ir[2], ir[1]) || ror_rm_c_w  (ir[2], ir[1]) ||
            rcl_rm_1_b  (ir[2], ir[1]) || rcl_rm_1_w  (ir[2], ir[1]) || rcl_rm_c_b  (ir[2], ir[1]) || rcl_rm_c_w  (ir[2], ir[1]) ||
            rcr_rm_1_b  (ir[2], ir[1]) || rcr_rm_1_w  (ir[2], ir[1]) || rcr_rm_c_b  (ir[2], ir[1]) || rcr_rm_c_w  (ir[2], ir[1]) ||
            and_rm_r_b  (ir[2], ir[1]) || and_r_rm_b  (ir[2], ir[1]) || and_rm_r_w  (ir[2], ir[1]) || and_r_rm_w  (ir[2], ir[1]) ||
            test_rm_r_b (ir[2], ir[1]) || test_r_rm_b (ir[2], ir[1]) || test_rm_r_w (ir[2], ir[1]) || test_r_rm_w (ir[2], ir[1]) ||
            or_rm_r_b   (ir[2], ir[1]) || or_r_rm_b   (ir[2], ir[1]) || or_rm_r_w   (ir[2], ir[1]) || or_r_rm_w   (ir[2], ir[1]) ||
            xor_rm_r_b  (ir[2], ir[1]) || xor_r_rm_b  (ir[2], ir[1]) || xor_rm_r_w  (ir[2], ir[1]) || xor_r_rm_w  (ir[2], ir[1]) ||
            not_rm_b    (ir[2], ir[1]) || not_rm_w    (ir[2], ir[1]) ||
            and_rm_i_b  (ir[2], ir[1]) || and_rm_i_w  (ir[2], ir[1]) ||
            test_rm_i_b (ir[2], ir[1]) || test_rm_i_w (ir[2], ir[1]) ||
            or_rm_i_b   (ir[2], ir[1]) || or_rm_i_w   (ir[2], ir[1]) ||
            xor_rm_i_b  (ir[2], ir[1]) || xor_rm_i_w  (ir[2], ir[1]) 
        ))
            if (field_mod(ir[1]) == 2'b00 && field_r_m(ir[1]) == 3'b110)
                addr_reg <= {rom_data, ir[0]};
            else 
                case (field_r_m(ir[1]))
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
        else if (first_byte[2] && (
            mov_a_m_b(ir[2], ir[1]) || mov_a_m_w(ir[2], ir[1]) ||
            mov_m_a_b(ir[2], ir[1]) || mov_m_a_w(ir[2], ir[1])
        )) 
            addr_reg <= {ir[0], ir[1]};
    end

    reg [15:0] data_reg;

    always @(posedge clk or negedge rst) begin
        if (~rst) data_reg <= 'b0;
        else if (first_byte[3] && is_reg_mod(ir[2], ir[1])) begin
            if      (
                mov_r_rm_b  (ir[3], ir[2]) ||
                add_rm_r_b  (ir[3], ir[2]) || add_r_rm_b  (ir[3], ir[2]) ||
                adc_rm_r_b  (ir[3], ir[2]) || adc_r_rm_b  (ir[3], ir[2]) ||
                sub_rm_r_b  (ir[3], ir[2]) || sub_r_rm_b  (ir[3], ir[2]) ||
                sbb_rm_r_b  (ir[3], ir[2]) || sbb_r_rm_b  (ir[3], ir[2]) ||
                cmp_rm_r_b  (ir[3], ir[2]) || cmp_r_rm_b  (ir[3], ir[2]) ||
                add_rm_i_b  (ir[3], ir[2]) ||
                adc_rm_i_b  (ir[3], ir[2]) ||
                sub_rm_i_b  (ir[3], ir[2]) ||
                sbb_rm_i_b  (ir[3], ir[2]) ||
                cmp_rm_i_b  (ir[3], ir[2]) ||
                inc_rm_b    (ir[3], ir[2]) ||
                dec_rm_b    (ir[3], ir[2]) ||
                neg_rm_b    (ir[3], ir[2]) ||
                mul_r_rm_b  (ir[3], ir[2]) ||
                imul_r_rm_b (ir[3], ir[2]) ||
                div_r_rm_b  (ir[3], ir[2]) ||
                idiv_r_rm_b (ir[3], ir[2]) ||
                shl_rm_1_b  (ir[3], ir[2]) || shl_rm_c_b  (ir[3], ir[2]) ||
                shr_rm_1_b  (ir[3], ir[2]) || shr_rm_c_b  (ir[3], ir[2]) ||
                sar_rm_1_b  (ir[3], ir[2]) || sar_rm_c_b  (ir[3], ir[2]) ||
                rol_rm_1_b  (ir[3], ir[2]) || rol_rm_c_b  (ir[3], ir[2]) ||
                ror_rm_1_b  (ir[3], ir[2]) || ror_rm_c_b  (ir[3], ir[2]) ||
                rcl_rm_1_b  (ir[3], ir[2]) || rcl_rm_c_b  (ir[3], ir[2]) ||
                rcr_rm_1_b  (ir[3], ir[2]) || rcr_rm_c_b  (ir[3], ir[2]) ||
                and_rm_r_b  (ir[3], ir[2]) || and_r_rm_b  (ir[3], ir[2]) ||
                test_rm_r_b (ir[3], ir[2]) || test_r_rm_b (ir[3], ir[2]) ||
                or_rm_r_b   (ir[3], ir[2]) || or_r_rm_b   (ir[3], ir[2]) ||
                xor_rm_r_b  (ir[3], ir[2]) || xor_r_rm_b  (ir[3], ir[2]) ||
                not_rm_b    (ir[3], ir[2]) ||
                and_rm_i_b  (ir[3], ir[2]) ||
                test_rm_i_b (ir[3], ir[2]) ||
                or_rm_i_b   (ir[3], ir[2]) ||
                xor_rm_i_b  (ir[3], ir[2]) 
            )
                data_reg <= register[reg_b(field_r_m(ir[2], ir[1])) +:  8];
            else if (
                mov_r_rm_w  (ir[3], ir[2]) || mov_sr_rm   (ir[3], ir[2]) ||
                add_rm_r_w  (ir[3], ir[2]) || add_r_rm_w  (ir[3], ir[2]) ||
                adc_rm_r_w  (ir[3], ir[2]) || adc_r_rm_w  (ir[3], ir[2]) ||
                sub_rm_r_w  (ir[3], ir[2]) || sub_r_rm_w  (ir[3], ir[2]) ||
                sbb_rm_r_w  (ir[3], ir[2]) || sbb_r_rm_w  (ir[3], ir[2]) ||
                cmp_rm_r_w  (ir[3], ir[2]) || cmp_r_rm_w  (ir[3], ir[2]) ||
                push_rm     (ir[3], ir[2]) ||
                add_rm_zi_w (ir[3], ir[2]) || add_rm_si_w (ir[3], ir[2]) ||
                adc_rm_zi_w (ir[3], ir[2]) || adc_rm_si_w (ir[3], ir[2]) ||
                sub_rm_zi_w (ir[3], ir[2]) || sub_rm_si_w (ir[3], ir[2]) ||
                sbb_rm_zi_w (ir[3], ir[2]) || sbb_rm_si_w (ir[3], ir[2]) ||
                cmp_rm_zi_w (ir[3], ir[2]) || cmp_rm_si_w (ir[3], ir[2]) ||
                inc_rm_w    (ir[3], ir[2]) ||
                dec_rm_w    (ir[3], ir[2]) ||
                neg_rm_w    (ir[3], ir[2]) ||
                mul_r_rm_w  (ir[3], ir[2]) ||
                imul_r_rm_w (ir[3], ir[2]) ||
                div_r_rm_w  (ir[3], ir[2]) ||
                idiv_r_rm_w (ir[3], ir[2]) ||
                shl_rm_1_w  (ir[3], ir[2]) || shl_rm_c_w  (ir[3], ir[2]) ||
                shr_rm_1_w  (ir[3], ir[2]) || shr_rm_c_w  (ir[3], ir[2]) ||
                sar_rm_1_w  (ir[3], ir[2]) || sar_rm_c_w  (ir[3], ir[2]) ||
                rol_rm_1_w  (ir[3], ir[2]) || rol_rm_c_w  (ir[3], ir[2]) ||
                ror_rm_1_w  (ir[3], ir[2]) || ror_rm_c_w  (ir[3], ir[2]) ||
                rcl_rm_1_w  (ir[3], ir[2]) || rcl_rm_c_w  (ir[3], ir[2]) ||
                rcr_rm_1_w  (ir[3], ir[2]) || rcr_rm_c_w  (ir[3], ir[2]) ||
                and_rm_r_w  (ir[3], ir[2]) || and_r_rm_w  (ir[3], ir[2]) ||
                test_rm_r_w (ir[3], ir[2]) || test_r_rm_w (ir[3], ir[2]) ||
                or_rm_r_w   (ir[3], ir[2]) || or_r_rm_w   (ir[3], ir[2]) ||
                xor_rm_r_w  (ir[3], ir[2]) || xor_r_rm_w  (ir[3], ir[2]) ||
                not_rm_w    (ir[3], ir[2]) ||
                and_rm_i_w  (ir[3], ir[2]) ||
                test_rm_i_w (ir[3], ir[2]) ||
                or_rm_i_w   (ir[3], ir[2]) ||
                xor_rm_i_w  (ir[3], ir[2]) ||
                call_rm_dir (ir[3], ir[2]) || call_rm_ptr (ir[3], ir[2]) ||
                jmp_rm_dir  (ir[3], ir[2]) || jmp_rm_ptr  (ir[3], ir[2]) ||
            )
                data_reg <= register[reg_w(field_r_m(ir[2], ir[1])) +: 16];
        end
        else if (first_byte[3]) begin
            if      (mov_rm_r_b (ir[3], ir[2])) data_reg <= register[reg_b(field_reg(ir[2], ir[1])) +:  8];
            else if (mov_rm_r_w (ir[3], ir[2])) data_reg <= register[reg_w(field_reg(ir[2], ir[1])) +: 16];
            else if (mov_rm_sr  (ir[3], ir[2])) data_reg <= segment_register[field_reg(ir[2], ir[1])[1:0]];
            else if (push_sr    (ir[3], ir[2])) data_reg <= segment_register[field_reg(ir[2], ir[1])[1:0]];
            else if (push_r     (ir[3], ir[2])) data_reg <= register[reg_w(field_r_m(ir[3], ir[2])) +: 16];
            else if (pushf      (ir[3], ir[2])) data_reg <= flags;
            else if (lahf       (ir[3], ir[2])) data_reg <= flags;
            else if (sahf       (ir[3], ir[2])) data_reg <= `AH;
            else if (mov_m_a_b  (ir[3], ir[2])) data_reg <= `AL;
            else if (mov_m_a_w  (ir[3], ir[2])) data_reg <= `AX;
            else if (mov_rm_i_b (ir[3], ir[2])) data_reg <= { 8'b0, ir[1]};
            else if (mov_rm_i_w (ir[3], ir[2])) data_reg <= {ir[0], ir[1]};
            else if (
                mov_r_i_b   (ir[3], ir[2]) ||
                add_a_i_b   (ir[3], ir[2]) ||
                adc_a_i_b   (ir[3], ir[2]) ||
                sub_a_i_b   (ir[3], ir[2]) ||
                sbb_a_i_b   (ir[3], ir[2]) ||
                cmp_a_i_b   (ir[3], ir[2]) 
            )
                data_reg <= {       8'b0, ir[2]};
            else if (
                mov_r_i_w   (ir[3], ir[2]) ||
                add_a_i_w   (ir[3], ir[2]) ||
                adc_a_i_w   (ir[3], ir[2]) ||
                sub_a_i_w   (ir[3], ir[2]) ||
                sbb_a_i_w   (ir[3], ir[2]) ||
                cmp_a_i_w   (ir[3], ir[2])
            )
                data_reg <= {ir[1], ir[2]};
            else if (
                mov_r_rm_b  (ir[3], ir[2]) || mov_r_rm_w  (ir[3], ir[2]) ||
                mov_a_m_b   (ir[3], ir[2]) || mov_a_m_w   (ir[3], ir[2]) ||
                push_rm     (ir[3], ir[2]) ||
                pop_rm      (ir[3], ir[2]) ||
                pop_r       (ir[3], ir[2]) ||
                pop_sr      (ir[3], ir[2]) ||
                popf        (ir[3], ir[2]) ||
                xlat        (ir[3], ir[2]) ||
                lds         (ir[3], ir[2]) ||
                les         (ir[3], ir[2]) ||
                xchg_r_rm_b (ir[3], ir[2]) || xchg_r_rm_w (ir[3], ir[2]) ||
                add_rm_r_b  (ir[3], ir[2]) || add_r_rm_b  (ir[3], ir[2]) || add_rm_r_w  (ir[3], ir[2]) || add_r_rm_w  (ir[3], ir[2]) ||
                adc_rm_r_b  (ir[3], ir[2]) || adc_r_rm_b  (ir[3], ir[2]) || adc_rm_r_w  (ir[3], ir[2]) || adc_r_rm_w  (ir[3], ir[2]) ||
                sub_rm_r_b  (ir[3], ir[2]) || sub_r_rm_b  (ir[3], ir[2]) || sub_rm_r_w  (ir[3], ir[2]) || sub_r_rm_w  (ir[3], ir[2]) ||
                sbb_rm_r_b  (ir[3], ir[2]) || sbb_r_rm_b  (ir[3], ir[2]) || sbb_rm_r_w  (ir[3], ir[2]) || sbb_r_rm_w  (ir[3], ir[2]) ||
                cmp_rm_r_b  (ir[3], ir[2]) || cmp_r_rm_b  (ir[3], ir[2]) || cmp_rm_r_w  (ir[3], ir[2]) || cmp_r_rm_w  (ir[3], ir[2]) ||
                add_rm_i_b  (ir[3], ir[2]) || add_rm_zi_w (ir[3], ir[2]) || add_rm_si_w (ir[3], ir[2]) ||
                adc_rm_i_b  (ir[3], ir[2]) || adc_rm_zi_w (ir[3], ir[2]) || adc_rm_si_w (ir[3], ir[2]) ||
                sub_rm_i_b  (ir[3], ir[2]) || sub_rm_zi_w (ir[3], ir[2]) || sub_rm_si_w (ir[3], ir[2]) ||
                sbb_rm_i_b  (ir[3], ir[2]) || sbb_rm_zi_w (ir[3], ir[2]) || sbb_rm_si_w (ir[3], ir[2]) ||
                cmp_rm_i_b  (ir[3], ir[2]) || cmp_rm_zi_w (ir[3], ir[2]) || cmp_rm_si_w (ir[3], ir[2]) ||
                inc_rm_b    (ir[3], ir[2]) || inc_rm_w    (ir[3], ir[2]) ||
                dec_rm_b    (ir[3], ir[2]) || dec_rm_w    (ir[3], ir[2]) ||
                neg_rm_b    (ir[3], ir[2]) || neg_rm_w    (ir[3], ir[2]) ||
                mul_r_rm_b  (ir[3], ir[2]) || mul_r_rm_w  (ir[3], ir[2]) ||
                imul_r_rm_b (ir[3], ir[2]) || imul_r_rm_w (ir[3], ir[2]) ||
                div_r_rm_b  (ir[3], ir[2]) || div_r_rm_w  (ir[3], ir[2]) ||
                idiv_r_rm_b (ir[3], ir[2]) || idiv_r_rm_w (ir[3], ir[2]) ||
                shl_rm_1_b  (ir[3], ir[2]) || shl_rm_c_b  (ir[3], ir[2]) || shl_rm_1_w  (ir[3], ir[2]) || shl_rm_c_w  (ir[3], ir[2]) ||
                shr_rm_1_b  (ir[3], ir[2]) || shr_rm_c_b  (ir[3], ir[2]) || shr_rm_1_w  (ir[3], ir[2]) || shr_rm_c_w  (ir[3], ir[2]) ||
                sar_rm_1_b  (ir[3], ir[2]) || sar_rm_c_b  (ir[3], ir[2]) || sar_rm_1_w  (ir[3], ir[2]) || sar_rm_c_w  (ir[3], ir[2]) ||
                rol_rm_1_b  (ir[3], ir[2]) || rol_rm_c_b  (ir[3], ir[2]) || rol_rm_1_w  (ir[3], ir[2]) || rol_rm_c_w  (ir[3], ir[2]) ||
                ror_rm_1_b  (ir[3], ir[2]) || ror_rm_c_b  (ir[3], ir[2]) || ror_rm_1_w  (ir[3], ir[2]) || ror_rm_c_w  (ir[3], ir[2]) ||
                rcl_rm_1_b  (ir[3], ir[2]) || rcl_rm_c_b  (ir[3], ir[2]) || rcl_rm_1_w  (ir[3], ir[2]) || rcl_rm_c_w  (ir[3], ir[2]) ||
                rcr_rm_1_b  (ir[3], ir[2]) || rcr_rm_c_b  (ir[3], ir[2]) || rcr_rm_1_w  (ir[3], ir[2]) || rcr_rm_c_w  (ir[3], ir[2]) ||
                and_rm_r_b  (ir[3], ir[2]) || and_r_rm_b  (ir[3], ir[2]) || and_rm_r_w  (ir[3], ir[2]) || and_r_rm_w  (ir[3], ir[2]) ||
                test_rm_r_b (ir[3], ir[2]) || test_r_rm_b (ir[3], ir[2]) || test_rm_r_w (ir[3], ir[2]) || test_r_rm_w (ir[3], ir[2]) ||
                or_rm_r_b   (ir[3], ir[2]) || or_r_rm_b   (ir[3], ir[2]) || or_rm_r_w   (ir[3], ir[2]) || or_r_rm_w   (ir[3], ir[2]) ||
                xor_rm_r_b  (ir[3], ir[2]) || xor_r_rm_b  (ir[3], ir[2]) || xor_rm_r_w  (ir[3], ir[2]) || xor_r_rm_w  (ir[3], ir[2]) ||
                not_rm_b    (ir[3], ir[2]) || not_rm_w    (ir[3], ir[2]) ||
                and_rm_i_b  (ir[3], ir[2]) || and_rm_i_w  (ir[3], ir[2]) ||
                test_rm_i_b (ir[3], ir[2]) || test_rm_i_w (ir[3], ir[2]) ||
                or_rm_i_b   (ir[3], ir[2]) || or_rm_i_w   (ir[3], ir[2]) ||
                xor_rm_i_b  (ir[3], ir[2]) || xor_rm_i_w  (ir[3], ir[2]) ||
                movs_b      (ir[3], ir[2]) || movs_w      (ir[3], ir[2]) ||
                cmps_b      (ir[3], ir[2]) || cmps_w      (ir[3], ir[2]) ||
                scas_b      (ir[3], ir[2]) || scas_w      (ir[3], ir[2]) ||
                lods_b      (ir[3], ir[2]) || lods_w      (ir[3], ir[2]) ||
                call_rm_dir (ir[3], ir[2]) || call_rm_ptr (ir[3], ir[2]) ||
                jmp_rm_dir  (ir[3], ir[2]) || jmp_rm_ptr  (ir[3], ir[2]) ||
                ret         (ir[3], ir[2]) || ret_i       (ir[3], ir[2]) ||
                retf        (ir[3], ir[2]) || retf_i      (ir[3], ir[2])
            )
                data_reg <= ram_rd_data;
        end
    end

    reg [15:0] extd_reg;

    always @(posedge clk or negedge rst) begin
        if (~rst) extd_reg <= 'b0;
        else if (first_byte[4]) begin
            if      (
                call_rm_ptr (ir[4], ir[3]) ||
                jmp_rm_ptr  (ir[4], ir[3]) ||
                retf        (ir[3], ir[2]) ||
                retf_i      (ir[3], ir[2])
            )
                extd_reg <= ram_rd_data[31:16];
        end
    end

    reg [15:0] a;
    reg [15:0] b;
    reg [15:0] r;
    reg [15:0] s;
    
    always @(*) begin
        if (~rst) begin
            a = 'b0;
            b = 'b0;
            r = 'b0;
            s = 'b0;
        end
        else if (first_byte[4]) begin
            if      (add_rm_r_b  (ir[4], ir[3])) begin a = data_reg; b = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; r = a + b; s = 0; end
            else if (add_r_rm_b  (ir[4], ir[3])) begin a = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; b = data_reg; r = a + b; s = 0; end
            else if (add_rm_r_w  (ir[4], ir[3])) begin a = data_reg; b = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; r = a + b; s = 0; end
            else if (add_r_rm_w  (ir[4], ir[3])) begin a = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; b = data_reg; r = a + b; s = 0; end
            else if (add_rm_i_b  (ir[4], ir[3])) begin a = data_reg; b =               ir[2] ; r = a + b; s = 0; end
            else if (add_rm_zi_w (ir[4], ir[3])) begin a = data_reg; b = {ir[1],       ir[2]}; r = a + b; s = 0; end
            else if (add_rm_si_w (ir[4], ir[3])) begin a = data_reg; b = {8{ir[2][7]}, ir[2]}; r = a + b; s = 0; end
            else if (add_a_i_b   (ir[4], ir[3])) begin a = `AL; b = data_reg; r = a + b; s = 0; end
            else if (add_a_i_w   (ir[4], ir[3])) begin a = `AX; b = data_reg; r = a + b; s = 0; end
            else if (adc_rm_r_b  (ir[4], ir[3])) begin a = data_reg; b = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; r = a + b + `CF; s = 0; end
            else if (adc_r_rm_b  (ir[4], ir[3])) begin a = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; b = data_reg; r = a + b + `CF; s = 0; end
            else if (adc_rm_r_w  (ir[4], ir[3])) begin a = data_reg; b = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; r = a + b + `CF; s = 0; end
            else if (adc_r_rm_w  (ir[4], ir[3])) begin a = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; b = data_reg; r = a + b + `CF; s = 0; end
            else if (adc_rm_i_b  (ir[4], ir[3])) begin a = data_reg; b =               ir[2] ; r = a + b + `CF; s = 0;  end
            else if (adc_rm_zi_w (ir[4], ir[3])) begin a = data_reg; b = {ir[1],       ir[2]}; r = a + b + `CF; s = 0; end
            else if (adc_rm_si_w (ir[4], ir[3])) begin a = data_reg; b = {8{ir[2][7]}, ir[2]}; r = a + b + `CF; s = 0; end
            else if (adc_a_i_b   (ir[4], ir[3])) begin a = `AL; b = data_reg; r = a + b + `CF; s = 0; end
            else if (adc_a_i_w   (ir[4], ir[3])) begin a = `AX; b = data_reg; r = a + b + `CF; s = 0; end
            else if (sub_rm_r_b  (ir[4], ir[3])) begin a = data_reg; b = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; r = a - b; s = 0; end
            else if (sub_r_rm_b  (ir[4], ir[3])) begin a = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; b = data_reg; r = a - b; s = 0; end
            else if (sub_rm_r_w  (ir[4], ir[3])) begin a = data_reg; b = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; r = a - b; s = 0; end
            else if (sub_r_rm_w  (ir[4], ir[3])) begin a = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; b = data_reg; r = a - b; s = 0; end
            else if (sub_rm_i_b  (ir[4], ir[3])) begin a = data_reg; b =               ir[2] ; r = a - b; s = 0; end
            else if (sub_rm_zi_w (ir[4], ir[3])) begin a = data_reg; b = {ir[1],       ir[2]}; r = a - b; s = 0; end
            else if (sub_rm_si_w (ir[4], ir[3])) begin a = data_reg; b = {8{ir[2][7]}, ir[2]}; r = a - b; s = 0; end
            else if (sub_a_i_b   (ir[4], ir[3])) begin a = `AL; b = data_reg; r = a - b; s = 0; end
            else if (sub_a_i_w   (ir[4], ir[3])) begin a = `AX; b = data_reg; r = a - b; s = 0; end
            else if (sbb_rm_r_b  (ir[4], ir[3])) begin a = data_reg; b = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; r = a - b - `CF; s = 0; end
            else if (sbb_r_rm_b  (ir[4], ir[3])) begin a = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; b = data_reg; r = a - b - `CF; s = 0; end
            else if (sbb_rm_r_w  (ir[4], ir[3])) begin a = data_reg; b = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; r = a - b - `CF; s = 0; end
            else if (sbb_r_rm_w  (ir[4], ir[3])) begin a = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; b = data_reg; r = a - b - `CF; s = 0; end
            else if (sbb_rm_i_b  (ir[4], ir[3])) begin a = data_reg; b =               ir[2] ; r = a - b - `CF; s = 0; end
            else if (sbb_rm_zi_w (ir[4], ir[3])) begin a = data_reg; b = {ir[1],       ir[2]}; r = a - b - `CF; s = 0; end
            else if (sbb_rm_si_w (ir[4], ir[3])) begin a = data_reg; b = {8{ir[2][7]}, ir[2]}; r = a - b - `CF; s = 0; end
            else if (sbb_a_i_b   (ir[4], ir[3])) begin a = `AL; b = data_reg; r = a - b - `CF; s = 0; end
            else if (sbb_a_i_w   (ir[4], ir[3])) begin a = `AX; b = data_reg; r = a - b - `CF; s = 0; end
            else if (cmp_rm_r_b  (ir[4], ir[3])) begin a = data_reg; b = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; r = a - b; s = 0; end
            else if (cmp_r_rm_b  (ir[4], ir[3])) begin a = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; b = data_reg; r = a - b; s = 0; end
            else if (cmp_rm_r_w  (ir[4], ir[3])) begin a = data_reg; b = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; r = a - b; s = 0; end
            else if (cmp_r_rm_w  (ir[4], ir[3])) begin a = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; b = data_reg; r = a - b; s = 0; end
            else if (cmp_rm_i_b  (ir[4], ir[3])) begin a = data_reg; b =               ir[2] ; r = a - b; s = 0; end
            else if (cmp_rm_zi_w (ir[4], ir[3])) begin a = data_reg; b = {ir[1],       ir[2]}; r = a - b; s = 0; end
            else if (cmp_rm_si_w (ir[4], ir[3])) begin a = data_reg; b = {8{ir[2][7]}, ir[2]}; r = a - b; s = 0; end
            else if (cmp_a_i_b   (ir[4], ir[3])) begin a = `AL; b = data_reg; r = a - b; s = 0; end
            else if (cmp_a_i_w   (ir[4], ir[3])) begin a = `AX; b = data_reg; r = a - b; s = 0; end
            else if (inc_rm_b    (ir[4], ir[3])) begin a = data_reg; b = 16'b1; r = a + b; s = 0; end
            else if (inc_rm_w    (ir[4], ir[3])) begin a = data_reg; b = 16'b1; r = a + b; s = 0; end
            else if (inc_r       (ir[4], ir[3])) begin a = register[reg_w(field_r_m(ir[4], ir[3])) +: 16]; b = 16'b1; r = a + b; s = 0; end
            else if (dec_rm_b    (ir[4], ir[3])) begin a = data_reg; b = 16'b1; r = a - b; s = 0; end
            else if (dec_rm_w    (ir[4], ir[3])) begin a = data_reg; b = 16'b1; r = a - b; s = 0; end
            else if (dec_r       (ir[4], ir[3])) begin a = register[reg_w(field_r_m(ir[4], ir[3])) +: 16]; b = 16'b1; r = a - b; s = 0; end
            else if (neg_rm_b    (ir[4], ir[3])) begin a = 'b0; b = data_reg; r = a - b; s = 0; end
            else if (neg_rm_w    (ir[4], ir[3])) begin a = 'b0; b = data_reg; r = a - b; s = 0; end
            else if (neg_r       (ir[4], ir[3])) begin a = 'b0; b = register[reg_w(field_r_m(ir[4], ir[3])) +: 16]; r = a - b; s = 0; end
            else if (mul_r_rm_b  (ir[4], ir[3])) begin a = `AL; b = data_reg; r = fmul_b(a,b); s = 0; end
            else if (mul_r_rm_w  (ir[4], ir[3])) begin a = `AX; b = data_reg; {s,r} = fmul_w(a,b); end
            else if (imul_r_rm_b (ir[4], ir[3])) begin a = `AL; b = data_reg; r = fmul_b(a,b); s = 0; end
            else if (imul_r_rm_w (ir[4], ir[3])) begin a = `AX; b = data_reg; {s,r} = fmul_w(a,b); end
            else if (div_r_rm_b  (ir[4], ir[3])) begin a = `AL; b = data_reg; r = fdiv_b(a,b); s = 0; end
            else if (div_r_rm_w  (ir[4], ir[3])) begin a = `AX; b = data_reg; {s,r} = fdiv_w(a,b); end
            else if (idiv_r_rm_b (ir[4], ir[3])) begin a = `AL; b = data_reg; r = fdiv_b(a,b); s = 0; end
            else if (idiv_r_rm_w (ir[4], ir[3])) begin a = `AX; b = data_reg; {s,r} = fdiv_w(a,b); end
            else if (shl_rm_1_b  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = a << b; s = a[ 7]; end
            else if (shl_rm_1_w  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = a << b; s = a[15]; end
            else if (shl_rm_c_b  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = a << b; s = {a << (b > 0 ? b - 1 : 0)}[ 7]; end
            else if (shl_rm_c_w  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = a << b; s = {a << (b > 0 ? b - 1 : 0)}[15]; end
            else if (shr_rm_1_b  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = a >> b; s = a[0]; end
            else if (shr_rm_1_w  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = a >> b; s = a[0]; end
            else if (shr_rm_c_b  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = a >> b; s = {a >> (b > 0 ? b - 1 : 0)}[0]; end
            else if (shr_rm_c_w  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = a >> b; s = {a >> (b > 0 ? b - 1 : 0)}[0]; end
            else if (sar_rm_1_b  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = a[ 7:0] >>> b; s = a[0]; end
            else if (sar_rm_1_w  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = a[15:0] >>> b; s = a[0]; end
            else if (sar_rm_c_b  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = a[ 7:0] >>> b; s = {a >> (b > 0 ? b - 1 : 0)}[0]; end
            else if (sar_rm_c_w  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = a[15:0] >>> b; s = {a >> (b > 0 ? b - 1 : 0)}[0]; end
            else if (rol_rm_1_b  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = {a[ 6:0], a[ 7]}; s = r[0]; end
            else if (rol_rm_1_w  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = {a[14:0], a[15]}; s = r[0]; end
            else if (rol_rm_c_b  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = {(a[ 7:0] << b) | (a[ 7:0] >> ('d8  - b))}; s = r[0]; end
            else if (rol_rm_c_w  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = {(a[15:0] << b) | (a[15:0] >> ('d16 - b))}; s = r[0]; end
            else if (ror_rm_1_b  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = {a[0], a[ 7:1]}; s = r[15]; end
            else if (ror_rm_1_w  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = {a[0], a[15:1]}; s = r[15]; end
            else if (ror_rm_c_b  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = {(a[ 7:0] >> b) | (a[ 7:0] << ('d8  - b))}; s = r[15]; end
            else if (ror_rm_c_w  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = {(a[15:0] >> b) | (a[15:0] << ('d16 - b))}; s = r[15]; end
            else if (rcl_rm_1_b  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = {a[ 6:0], `CF}; s = a[ 7]; end
            else if (rcl_rm_1_w  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = {a[14:0], `CF}; s = a[15]; end
            else if (rcl_rm_c_b  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = b > 0 ? {(a[ 7:0] << b) | ({`CF, a[ 7:1]} >> ('d7  - b))} : a; s = r[0]; end
            else if (rcl_rm_c_w  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = b > 0 ? {(a[15:0] << b) | ({`CF, a[15:1]} >> ('d15 - b))} : a; s = r[0]; end
            else if (rcr_rm_1_b  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = {`CF, a[ 7:1]}; s = a[0]; end
            else if (rcr_rm_1_w  (ir[4], ir[3])) begin a = data_reg; b = 'b1; r = {`CF, a[15:1]}; s = a[0]; end
            else if (rcr_rm_c_b  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = {(a[ 7:0] >> b) | (a[ 7:0] << ('d8  - b))}; s = r[15]; end
            else if (rcr_rm_c_w  (ir[4], ir[3])) begin a = data_reg; b = `CL; r = {(a[15:0] >> b) | (a[15:0] << ('d16 - b))}; s = r[15]; end
            else if (not_rm_b    (ir[4], ir[3])) begin a = data_reg; b = 'b0; r = ~a[ 7:0]; s = 0; end
            else if (not_rm_w    (ir[4], ir[3])) begin a = data_reg; b = 'b0; r = ~a[15:0]; s = 0; end
            else if (and_rm_r_b  (ir[4], ir[3])) begin a = data_reg; b = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; r = a & b; s = 0; end
            else if (and_r_rm_b  (ir[4], ir[3])) begin a = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; b = data_reg; r = a & b; s = 0; end
            else if (and_rm_r_w  (ir[4], ir[3])) begin a = data_reg; b = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; r = a & b; s = 0; end
            else if (and_r_rm_w  (ir[4], ir[3])) begin a = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; b = data_reg; r = a & b; s = 0; end
            else if (and_rm_i_b  (ir[4], ir[3])) begin a = data_reg; b =         ir[2] ; r = a & b; s = 0; end
            else if (and_rm_i_w  (ir[4], ir[3])) begin a = data_reg; b = {ir[1], ir[2]}; r = a & b; s = 0; end
            else if (and_a_i_b   (ir[4], ir[3])) begin a = `AL; b = data_reg; r = a & b; s = 0; end
            else if (and_a_i_w   (ir[4], ir[3])) begin a = `AX; b = data_reg; r = a & b; s = 0; end
            else if (test_rm_r_b (ir[4], ir[3])) begin a = data_reg; b = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; r = a & b; s = 0; end
            else if (test_r_rm_b (ir[4], ir[3])) begin a = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; b = data_reg; r = a & b; s = 0; end
            else if (test_rm_r_w (ir[4], ir[3])) begin a = data_reg; b = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; r = a & b; s = 0; end
            else if (test_r_rm_w (ir[4], ir[3])) begin a = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; b = data_reg; r = a & b; s = 0; end
            else if (test_rm_i_b (ir[4], ir[3])) begin a = data_reg; b =         ir[2] ; r = a & b; s = 0; end
            else if (test_rm_i_w (ir[4], ir[3])) begin a = data_reg; b = {ir[1], ir[2]}; r = a & b; s = 0; end
            else if (test_a_i_b  (ir[4], ir[3])) begin a = `AL; b = data_reg; r = a & b; s = 0; end
            else if (test_a_i_w  (ir[4], ir[3])) begin a = `AX; b = data_reg; r = a & b; s = 0; end
            else if (or_rm_r_b   (ir[4], ir[3])) begin a = data_reg; b = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; r = a | b; s = 0; end
            else if (or_r_rm_b   (ir[4], ir[3])) begin a = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; b = data_reg; r = a | b; s = 0; end
            else if (or_rm_r_w   (ir[4], ir[3])) begin a = data_reg; b = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; r = a | b; s = 0; end
            else if (or_r_rm_w   (ir[4], ir[3])) begin a = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; b = data_reg; r = a | b; s = 0; end
            else if (or_rm_i_b   (ir[4], ir[3])) begin a = data_reg; b =         ir[2] ; r = a | b; s = 0; end
            else if (or_rm_i_w   (ir[4], ir[3])) begin a = data_reg; b = {ir[1], ir[2]}; r = a | b; s = 0; end
            else if (or_a_i_b    (ir[4], ir[3])) begin a = `AL; b = data_reg; r = a | b; s = 0; end
            else if (or_a_i_w    (ir[4], ir[3])) begin a = `AX; b = data_reg; r = a | b; s = 0; end
            else if (xor_rm_r_b  (ir[4], ir[3])) begin a = data_reg; b = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; r = a ^ b; s = 0; end
            else if (xor_r_rm_b  (ir[4], ir[3])) begin a = register[reg_b(field_reg(ir[3], ir[2])) +:  8]; b = data_reg; r = a ^ b; s = 0; end
            else if (xor_rm_r_w  (ir[4], ir[3])) begin a = data_reg; b = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; r = a ^ b; s = 0; end
            else if (xor_r_rm_w  (ir[4], ir[3])) begin a = register[reg_w(field_reg(ir[3], ir[2])) +: 16]; b = data_reg; r = a ^ b; s = 0; end
            else if (xor_rm_i_b  (ir[4], ir[3])) begin a = data_reg; b =         ir[2] ; r = a ^ b; s = 0; end
            else if (xor_rm_i_w  (ir[4], ir[3])) begin a = data_reg; b = {ir[1], ir[2]}; r = a ^ b; s = 0; end
            else if (xor_a_i_b   (ir[4], ir[3])) begin a = `AL; b = data_reg; r = a ^ b; s = 0; end
            else if (xor_a_i_w   (ir[4], ir[3])) begin a = `AX; b = data_reg; r = a ^ b; s = 0; end
            else if (cmps_b      (ir[4], ir[3])) begin a = data_reg; b = ram_rd_data; r = a - b; s = 0; end
            else if (cmps_w      (ir[4], ir[3])) begin a = data_reg; b = ram_rd_data; r = a - b; s = 0; end
            else if (scas_b      (ir[4], ir[3])) begin a = `AL ; b = data_reg; r = a - b; s = 0; end
            else if (scas_w      (ir[4], ir[3])) begin a = `AX ; b = data_reg; r = a - b; s = 0; end
            else                                 begin a = 'b0; b = 'b0; r = 'b0; end
        end
    end

    reg [127:0] register;

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            for (i = 0; i < 16; i = i + 1) begin
                register <= 'b0;
            end
        end
        else if (first_byte[4] && is_reg_mod(ir[3], ir[2])) begin
            if      (
                mov_rm_r_b  (ir[4], ir[3]) ||
                mov_rm_i_b  (ir[4], ir[3])
            )
                register[reg_b(field_r_m(ir[3], ir[2])) +:  8] <= data_reg[7:0];
            else if (
                mov_rm_r_w  (ir[4], ir[3]) ||
                mov_rm_sr   (ir[4], ir[3]) ||
                mov_rm_i_w  (ir[4], ir[3])
            )
                register[reg_w(field_r_m(ir[3], ir[2])) +: 16] <= data_reg;
            else if (
                add_rm_r_b  (ir[4], ir[3]) ||
                adc_rm_r_b  (ir[4], ir[3]) ||
                sub_rm_r_b  (ir[4], ir[3]) ||
                sbb_rm_r_b  (ir[4], ir[3]) ||
                add_rm_i_b  (ir[4], ir[3]) ||
                adc_rm_i_b  (ir[4], ir[3]) ||
                sub_rm_i_b  (ir[4], ir[3]) ||
                sbb_rm_i_b  (ir[4], ir[3]) ||
                inc_rm_b    (ir[4], ir[3]) ||
                dec_rm_b    (ir[4], ir[3]) ||
                neg_rm_b    (ir[4], ir[3]) ||
                shl_rm_1_b  (ir[4], ir[3]) || shl_rm_c_b  (ir[4], ir[3]) ||
                shr_rm_1_b  (ir[4], ir[3]) || shr_rm_c_b  (ir[4], ir[3]) ||
                sar_rm_1_b  (ir[4], ir[3]) || sar_rm_c_b  (ir[4], ir[3]) ||
                rol_rm_1_b  (ir[4], ir[3]) || rol_rm_c_b  (ir[4], ir[3]) ||
                ror_rm_1_b  (ir[4], ir[3]) || ror_rm_c_b  (ir[4], ir[3]) ||
                rcl_rm_1_b  (ir[4], ir[3]) || rcl_rm_c_b  (ir[4], ir[3]) ||
                rcr_rm_1_b  (ir[4], ir[3]) || rcr_rm_c_b  (ir[4], ir[3]) ||
                not_rm_b    (ir[4], ir[3]) ||
                and_rm_r_b  (ir[4], ir[3]) ||
                or_rm_r_b   (ir[4], ir[3]) ||
                xor_rm_r_b  (ir[4], ir[3]) ||
                and_rm_i_b  (ir[4], ir[3]) ||
                or_rm_i_b   (ir[4], ir[3]) ||
                xor_rm_i_b  (ir[4], ir[3]) 
            )
                register[reg_b(field_r_m(ir[3], ir[2])) +:  8] <= r[7:0];
            else if (
                add_rm_r_w  (ir[4], ir[3]) ||
                adc_rm_r_w  (ir[4], ir[3]) ||
                sub_rm_r_w  (ir[4], ir[3]) ||
                sbb_rm_r_w  (ir[4], ir[3]) ||
                add_rm_zi_w (ir[4], ir[3]) || add_rm_si_w (ir[4], ir[3]) ||
                adc_rm_zi_w (ir[4], ir[3]) || adc_rm_si_w (ir[4], ir[3]) ||
                sub_rm_zi_w (ir[4], ir[3]) || sub_rm_si_w (ir[4], ir[3]) ||
                sbb_rm_zi_w (ir[4], ir[3]) || sbb_rm_si_w (ir[4], ir[3]) ||
                inc_rm_w    (ir[4], ir[3]) ||
                dec_rm_w    (ir[4], ir[3]) ||
                neg_rm_w    (ir[4], ir[3]) ||
                shl_rm_1_w  (ir[4], ir[3]) || shl_rm_c_w  (ir[4], ir[3]) ||
                shr_rm_1_w  (ir[4], ir[3]) || shr_rm_c_w  (ir[4], ir[3]) ||
                sar_rm_1_w  (ir[4], ir[3]) || sar_rm_c_w  (ir[4], ir[3]) ||
                rol_rm_1_w  (ir[4], ir[3]) || rol_rm_c_w  (ir[4], ir[3]) ||
                ror_rm_1_w  (ir[4], ir[3]) || ror_rm_c_w  (ir[4], ir[3]) ||
                rcl_rm_1_w  (ir[4], ir[3]) || rcl_rm_c_w  (ir[4], ir[3]) ||
                rcr_rm_1_w  (ir[4], ir[3]) || rcr_rm_c_w  (ir[4], ir[3]) ||
                not_rm_w    (ir[4], ir[3]) ||
                and_rm_r_w  (ir[4], ir[3]) ||
                or_rm_r_w   (ir[4], ir[3]) ||
                xor_rm_r_w  (ir[4], ir[3]) ||
                and_rm_i_w  (ir[4], ir[3]) ||
                or_rm_i_w   (ir[4], ir[3]) ||
                xor_rm_i_w  (ir[4], ir[3]) 
            )
                register[reg_w(field_r_m(ir[3], ir[2])) +: 16] <= r;
            else if (pop_rm     (ir[4], ir[3])) begin register[reg_w(field_r_m(ir[3], ir[2])) +: 16] <= data_reg; `SP <= `SP + 'h2; end
            else if (xchg_r_rm_b(ir[4], ir[3])) {register[reg_b(field_reg(ir[3], ir[2])) +:  8], register[reg_b(field_r_m(ir[3], ir[2])) +:  8]} <= {register[reg_b(field_r_m(ir[3], ir[2])) +:  8], register[reg_b(field_reg(ir[3], ir[2])) +:  8]};
            else if (xchg_r_rm_w(ir[4], ir[3])) {register[reg_w(field_reg(ir[3], ir[2])) +: 16], register[reg_w(field_r_m(ir[3], ir[2])) +: 16]} <= {register[reg_w(field_r_m(ir[3], ir[2])) +: 16], register[reg_w(field_reg(ir[3], ir[2])) +: 16]};

        end
        else if (first_byte[4]) begin
            if      (
                mov_r_rm_b  (ir[4], ir[3]) ||
                xchg_r_rm_b (ir[4], ir[3]) 
            )
                register[reg_b(field_reg(ir[3], ir[2])) +:  8] <= data_reg[7:0];
            else if (
                mov_r_rm_w  (ir[4], ir[3]) ||
                xchg_r_rm_w (ir[4], ir[3]) ||
                lds         (ir[4], ir[3]) ||
                les         (ir[4], ir[3]) 
            )
                register[reg_w(field_reg(ir[3], ir[2])) +: 16] <= data_reg;
            else if (
                mov_r_i_b   (ir[4], ir[3])
            )
                register[reg_b(field_r_m(ir[3], ir[2])) +:  8] <= data_reg[7:0];
            else if (
                mov_r_i_w   (ir[4], ir[3])
            )
                register[reg_w(field_r_m(ir[3], ir[2])) +: 16] <= data_reg;
            else if (
                mov_a_m_b   (ir[4], ir[3]) ||
                xlat        (ir[4], ir[3]) ||
                lods_b      (ir[4], ir[3])
            )
                `AL <= data_reg[7:0];
            else if (
                lahf        (ir[4], ir[3]) 
            )
                `AH <= data_reg[7:0];
            else if (
                mov_a_m_w   (ir[4], ir[3]) ||
                lods_w      (ir[4], ir[3])
            )
                `AX <= data_reg;
            else if (
                push_rm     (ir[4], ir[3]) ||
                push_r      (ir[4], ir[3]) ||
                push_sr     (ir[4], ir[3]) ||
                pushf       (ir[4], ir[3]) ||
            )
                `SP <= `SP - 'h2;
            else if (pop_r  (ir[4], ir[3]))
                begin register[reg_w(field_r_m(ir[4], ir[3])) +: 16] <= data_reg; `SP <= `SP + 'h2; end
            else if (pop_sr (ir[4], ir[3]))
                begin segment_register[field_reg(ir[4], ir[3])[1:0]] <= data_reg; `SP <= `SP + 'h2; end
            else if (popf   (ir[4], ir[3]))
                `SP <= `SP + 'h2;
            else if (call_i_dir (ir[4], ir[3]) || call_rm_dir (ir[4], ir[3]))
                `SP <= `SP - 'h2;
            else if (call_i_ptr (ir[4], ir[3]) || call_rm_ptr (ir[4], ir[3]))
                `SP <= `SP - 'h4;
            else if (ret        (ir[4], ir[3]))
                `SP <= `SP + 'h2;
            else if (ret_i      (ir[4], ir[3]))
                `SP <= `SP + 'h2 + {ir[1], ir[2]};
            else if (retf       (ir[4], ir[3]))
                `SP <= `SP + 'h4;
            else if (retf_i     (ir[4], ir[3]))
                `SP <= `SP + 'h4 + {ir[1], ir[2]};
            else if (
                add_r_rm_b  (ir[4], ir[3]) ||
                adc_r_rm_b  (ir[4], ir[3]) ||
                sub_r_rm_b  (ir[4], ir[3]) ||
                sbb_r_rm_b  (ir[4], ir[3]) ||
                not_rm_b    (ir[4], ir[3]) ||
                and_r_rm_b  (ir[4], ir[3]) ||
                or_r_rm_b   (ir[4], ir[3]) ||
                xor_r_rm_b  (ir[4], ir[3]) 
            )
                register[reg_b(field_reg(ir[3], ir[2])) +:  8] <= r[7:0];
            else if (
                add_r_rm_w  (ir[4], ir[3]) ||
                adc_r_rm_w  (ir[4], ir[3]) ||
                sub_r_rm_w  (ir[4], ir[3]) ||
                sbb_r_rm_w  (ir[4], ir[3]) ||
                not_rm_w    (ir[4], ir[3]) ||
                and_r_rm_w  (ir[4], ir[3]) ||
                or_r_rm_w   (ir[4], ir[3]) ||
                xor_r_rm_w  (ir[4], ir[3]) 
            )
                register[reg_w(field_reg(ir[3], ir[2])) +: 16] <= r;
            else if (
                add_a_i_b   (ir[4], ir[3]) ||
                adc_a_i_b   (ir[4], ir[3]) ||
                sub_a_i_b   (ir[4], ir[3]) ||
                sbb_a_i_b   (ir[4], ir[3]) ||
                and_a_i_b   (ir[4], ir[3]) ||
                or_a_i_b    (ir[4], ir[3]) ||
                xor_a_i_b   (ir[4], ir[3]) 
            )
                `AL <= r[7:0];
            else if (
                add_a_i_w   (ir[4], ir[3]) ||
                adc_a_i_w   (ir[4], ir[3]) ||
                sub_a_i_w   (ir[4], ir[3]) ||
                sbb_a_i_w   (ir[4], ir[3]) ||
                mul_r_rm_b  (ir[4], ir[3]) ||
                imul_r_rm_b (ir[4], ir[3]) ||
                div_r_rm_b  (ir[4], ir[3]) ||
                idiv_r_rm_b (ir[4], ir[3]) ||
                and_a_i_w   (ir[4], ir[3]) ||
                or_a_i_w    (ir[4], ir[3]) ||
                xor_a_i_w   (ir[4], ir[3]) 
            )
                `AX <= r;               
            else if (
                inc_r       (ir[4], ir[3]) ||
                dec_r       (ir[4], ir[3]) ||
            )
                register[reg_w(field_r_m(ir[4], ir[3])) +: 16] <= r;                                         
            else if (
                mul_r_rm_w  (ir[4], ir[3]) ||
                imul_r_rm_w (ir[4], ir[3]) ||
                div_r_rm_w  (ir[4], ir[3]) ||
                idiv_r_rm_w (ir[4], ir[3]) 
            )
                {`DX, `AX} <= {s, r};
            else if (
                rep_z (pr) ||
                rep_nz(pr)
            )
                `CX <= `CX - 'b1;
            else if (
                movs_b      (ir[4], ir[3]) ||
                cmps_b      (ir[4], ir[3])
            ) begin 
                `DF ? (`SI <= `SI - 'h1; `DI <= `DI - 'h1) : (`SI <= `SI + 'h1; `DI <= `DI + 'h1);
            end
            else if (
                movs_w      (ir[4], ir[3]) ||
                cmps_w      (ir[4], ir[3])
            ) begin
                `DF ? (`SI <= `SI - 'h2; `DI <= `DI - 'h2) : (`SI <= `SI + 'h2; `DI <= `DI + 'h2);
            end
            else if (
                scas_b      (ir[4], ir[3]) ||
                lods_b      (ir[4], ir[3]) ||
                stos_b      (ir[4], ir[3])
            ) begin
                `DF ? `DI <= `DI - 'h1 : `DI <= `DI + 'h1;
            end
            else if (
                scas_w      (ir[4], ir[3]) ||
                lods_w      (ir[4], ir[3]) ||
                stos_w      (ir[4], ir[3])
            ) begin
                `DF ? `DI <= `DI - 'h2 : `DI <= `DI + 'h2;
            end
            else if (
                lea         (ir[4], ir[3])
            )
                register[reg_w(field_reg(ir[3], ir[2])) +: 16] <= addr_reg;
            else if (aaa    (ir[4], ir[3])) {`AH, `AL} <= `AL & 8'h0f > 8'h09 | `AF ? {`AH + 8'h1, `AL + 8'h6} : {`AH, `AL};
            else if (daa    (ir[4], ir[3])) `AL <= `AL + (`AL & 8'h0f > 8'h09 | `AF ? 8'h6 : 8'h0) + (`AL > 8'h9f | `CF ? 8'h60 : 8'h00);
            else if (aas    (ir[4], ir[3])) {`AH, `AL} <= `AL & 8'h0f > 8'h09 | `AF ? {`AH - 8'h1, `AL - 8'h6} : {`AH, `AL};
            else if (das    (ir[4], ir[3])) `AL <= `AL - (`AL & 8'h0f > 8'h09 | `AF ? 8'h6 : 8'h0) - (`AL > 8'h9f | `CF ? 8'h60 : 8'h00);
            else if (aam    (ir[4], ir[3])) {`AH, `AL} <= {`AL / 8'h0a, `AL % 8'h0a};
            else if (aad    (ir[4], ir[3])) {`AH, `AL} <= {8'h00, `AH * 8'h0a + `AL};
            else if (cbw    (ir[4], ir[3])) `AX <= {8{`AL}, `AL};
            else if (cwd    (ir[4], ir[3])) {`DX, `AX} <= {8{`AX}, `AX};
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
            if      (mov_sr_rm  (ir[4], ir[3])) segment_register[field_reg(ir[3], ir[2])[1:0]] <= data_reg;
            else if (lds        (ir[4], ir[3])) `DS <= extd_reg;
            else if (les        (ir[4], ir[3])) `ES <= extd_reg;
            else if (call_i_ptr (ir[4], ir[3])) `CS <= {ir[0], ir[1]};
            else if (call_rm_ptr(ir[4], ir[3])) `CS <= extd_reg;
            else if (jmp_i_ptr  (ir[4], ir[3])) `CS <= {ir[0], ir[1]};
            else if (jmp_rm_ptr (ir[4], ir[3])) `CS <= extd_reg;
            else if (retf       (ir[4], ir[3])) `CS <= extd_reg;
            else if (retf_i     (ir[4], ir[3])) `CS <= extd_reg;
        end
    end

    reg [15:0] flags;

    always @(posedge clk or negedge rst) begin
        if (~rst)
            flags <= 'b0;
        else if (first_byte[4]) begin
            if (
                add_rm_r_b  (ir[4], ir[3]) || add_r_rm_b  (ir[4], ir[3]) || add_a_i_b   (ir[4], ir[3]) ||
                add_rm_i_b  (ir[4], ir[3]) ||
                inc_rm_b    (ir[4], ir[3])
            ) begin
                `OF <= of_b(a,b,r); `SF <= sf_b(r); `ZF <= zf_b(r); `AF <= af_b(a,b,'d0); `PF <= pf_b(r); `CF <= cf_b(a,b,'d0);
            end
            else if (
                adc_rm_r_b  (ir[4], ir[3]) || adc_r_rm_b  (ir[4], ir[3]) || adc_a_i_b   (ir[4], ir[3]) ||
                adc_rm_i_b  (ir[4], ir[3])
            ) begin
                `OF <= of_b(a,b,r); `SF <= sf_b(r); `ZF <= zf_b(r); `AF <= af_b(a,b,`CF); `PF <= pf_b(r); `CF <= cf_b(a,b,`CF);
            end
            else if (
                add_rm_r_w  (ir[4], ir[3]) || add_r_rm_w  (ir[4], ir[3]) || add_a_i_w   (ir[4], ir[3]) ||
                add_rm_zi_w (ir[4], ir[3]) ||
                add_rm_si_w (ir[4], ir[3]) ||
                inc_rm_w    (ir[4], ir[3]) ||
                inc_r       (ir[4], ir[3])
            ) begin
                `OF <= of_w(a,b,r); `SF <= sf_w(r); `ZF <= zf_w(r); `AF <= af_w(a,b,'d0); `PF <= pf_w(r); `CF <= cf_w(a,b,'d0);
            end
            else if (
                adc_rm_r_w  (ir[4], ir[3]) || adc_r_rm_w  (ir[4], ir[3]) || adc_a_i_w   (ir[4], ir[3]) ||
                adc_rm_zi_w (ir[4], ir[3]) ||
                adc_rm_si_w (ir[4], ir[3])
            ) begin
                `OF <= of_w(a,b,r); `SF <= sf_w(r); `ZF <= zf_w(r); `AF <= af_w(a,b,`CF); `PF <= pf_w(r); `CF <= cf_w(a,b,`CF);
            end
            else if (
                sub_rm_r_b  (ir[4], ir[3]) || sub_r_rm_b  (ir[4], ir[3]) || sub_a_i_b   (ir[4], ir[3]) ||
                cmp_rm_r_b  (ir[4], ir[3]) || cmp_r_rm_b  (ir[4], ir[3]) || cmp_a_i_b   (ir[4], ir[3]) ||
                sub_rm_i_b  (ir[4], ir[3]) ||
                cmp_rm_b    (ir[4], ir[3]) ||
                dec_rm_b    (ir[4], ir[3]) ||
                neg_rm_b    (ir[4], ir[3]) ||
                cmps_b      (ir[4], ir[3]) ||
                scas_b      (ir[4], ir[3])
            ) begin
                `OF <= of_b(a,-b,r); `SF <= sf_b(r); `ZF <= zf_b(r); `AF <= af_b(a,-b,'d0); `PF <= pf_b(r); `CF <= cf_b(a,-b,'d0);
            end
            else if (
                sbb_rm_r_b  (ir[4], ir[3]) || sbb_r_rm_b  (ir[4], ir[3]) || sbb_a_i_b   (ir[4], ir[3]) ||
                sbb_rm_i_b  (ir[4], ir[3]) 
            ) begin
                `OF <= of_b(a,-b,r); `SF <= sf_b(r); `ZF <= zf_b(r); `AF <= af_b(a,-b,-`CF); `PF <= pf_b(r); `CF <= cf_b(a,-b,-`CF);
            end
            else if (
                sub_rm_r_w  (ir[4], ir[3]) || sub_r_rm_w  (ir[4], ir[3]) || sub_a_i_w   (ir[4], ir[3]) ||
                cmp_rm_r_w  (ir[4], ir[3]) || cmp_r_rm_w  (ir[4], ir[3]) || cmp_a_i_w   (ir[4], ir[3]) ||
                sub_rm_zi_w (ir[4], ir[3]) || sub_rm_si_w (ir[4], ir[3]) ||
                cmp_rm_zi_w (ir[4], ir[3]) || cmp_rm_si_w (ir[4], ir[3]) ||
                dec_rm_w    (ir[4], ir[3]) ||
                dec_r       (ir[4], ir[3]) ||
                neg_rm_w    (ir[4], ir[3]) ||
                cmps_w      (ir[4], ir[3]) ||
                scas_w      (ir[4], ir[3])
            ) begin
                `OF <= of_w(a,-b,r); `SF <= sf_w(r); `ZF <= zf_w(r); `AF <= af_w(a,-b,'d0); `PF <= pf_w(r); `CF <= cf_w(a,-b,'d0);
            end
            else if (
                sbb_rm_r_w  (ir[4], ir[3]) || sbb_r_rm_w  (ir[4], ir[3]) || sbb_a_i_w   (ir[4], ir[3]) ||
                sbb_rm_zi_w (ir[4], ir[3]) ||
                sbb_rm_si_w (ir[4], ir[3]) 
            ) begin
                `OF <= of_w(a,-b,r); `SF <= sf_w(r); `ZF <= zf_w(r); `AF <= af_w(a,-b,-`CF); `PF <= pf_w(r); `CF <= cf_w(a,-b,-`CF);
            end
            else if (
                shl_rm_1_b  (ir[4], ir[3]) || shl_rm_c_b  (ir[4], ir[3]) || shl_rm_1_w  (ir[4], ir[3]) || shl_rm_c_w  (ir[4], ir[3]) ||
                shr_rm_1_b  (ir[4], ir[3]) || shr_rm_c_b  (ir[4], ir[3]) || shr_rm_1_w  (ir[4], ir[3]) || shr_rm_c_w  (ir[4], ir[3]) ||
                sar_rm_1_b  (ir[4], ir[3]) || sar_rm_c_b  (ir[4], ir[3]) || sar_rm_1_w  (ir[4], ir[3]) || sar_rm_c_w  (ir[4], ir[3]) ||
                rol_rm_1_b  (ir[4], ir[3]) || rol_rm_c_b  (ir[4], ir[3]) || rol_rm_1_w  (ir[4], ir[3]) || rol_rm_c_w  (ir[4], ir[3]) ||
                ror_rm_1_b  (ir[4], ir[3]) || ror_rm_c_b  (ir[4], ir[3]) || ror_rm_1_w  (ir[4], ir[3]) || ror_rm_c_w  (ir[4], ir[3]) ||
                rcl_rm_1_b  (ir[4], ir[3]) || rcl_rm_c_b  (ir[4], ir[3]) || rcl_rm_1_w  (ir[4], ir[3]) || rcl_rm_c_w  (ir[4], ir[3]) ||
                rcr_rm_1_b  (ir[4], ir[3]) || rcr_rm_c_b  (ir[4], ir[3]) || rcr_rm_1_w  (ir[4], ir[3]) || rcr_rm_c_w  (ir[4], ir[3]) 
            ) begin
                `OF <= of_b(a,b,r); `CF <= s[0];
            end
            else if (
                and_rm_r_b  (ir[4], ir[3]) || and_r_rm_b  (ir[4], ir[3]) ||
                test_rm_r_b (ir[4], ir[3]) || test_r_rm_b (ir[4], ir[3]) ||
                or_rm_r_b   (ir[4], ir[3]) || or_r_rm_b   (ir[4], ir[3]) ||
                xor_rm_r_b  (ir[4], ir[3]) || xor_r_rm_b  (ir[4], ir[3]) ||
                not_rm_b    (ir[4], ir[3]) ||
                and_rm_i_b  (ir[4], ir[3]) ||
                test_rm_i_b (ir[4], ir[3]) ||
                or_rm_i_b   (ir[4], ir[3]) ||
                xor_rm_i_b  (ir[4], ir[3]) ||
            ) begin
                `OF <= 0; `SF <= sf_b(r); `ZF <= zf_b(r); `PF <= pf_b(r); `CF <= 0;
            end
            else if (
                and_rm_r_w  (ir[4], ir[3]) || and_r_rm_w  (ir[4], ir[3]) ||
                test_rm_r_w (ir[4], ir[3]) || test_r_rm_w (ir[4], ir[3]) ||
                or_rm_r_w   (ir[4], ir[3]) || or_r_rm_w   (ir[4], ir[3]) ||
                xor_rm_r_w  (ir[4], ir[3]) || xor_r_rm_w  (ir[4], ir[3]) ||
                not_rm_w    (ir[4], ir[3]) ||
                and_rm_i_w  (ir[4], ir[3]) ||
                test_rm_i_w (ir[4], ir[3]) ||
                or_rm_i_w   (ir[4], ir[3]) ||
                xor_rm_i_w  (ir[4], ir[3]) ||
            ) begin
                `OF <= 0; `SF <= sf_w(r); `ZF <= zf_w(r); `PF <= pf_w(r); `CF <= 0;
            end
            else if (
                mul_r_rm_b  (ir[4], ir[3]) || mul_r_rm_w  (ir[4], ir[3]) ||
                imul_r_rm_b (ir[4], ir[3]) || imul_r_rm_w (ir[4], ir[3]) ||
                div_r_rm_b  (ir[4], ir[3]) || div_r_rm_w  (ir[4], ir[3]) ||
                idiv_r_rm_b (ir[4], ir[3]) || idiv_r_rm_w (ir[4], ir[3]) ||
            )  begin 
                // TODO
            end
            else if (sahf   (ir[4], ir[3])) flags[ 7:0] <= data_reg[ 7:0];
            else if (popf   (ir[4], ir[3])) flags[15:0] <= data_reg[15:0];
            else if (aaa    (ir[4], ir[3])) {`AF, `CF} <= {2{`AL & 8'h0f > 8'h9 | `AF}};
            else if (daa    (ir[4], ir[3])) {`AF, `CF} <= {`AL & 8'h0f > 8'h9 | `AF, `AL > 8'h9f | `CF};
            else if (aas    (ir[4], ir[3])) {`AF, `CF} <= {2{`AL & 8'h0f > 8'h9 | `AF}};
            else if (das    (ir[4], ir[3])) {`AF, `CF} <= {`AL & 8'h0f > 8'h9 | `AF, `AL > 8'h9f | `CF};
        end
    end

    assign ram_rd_en = (first_byte[3] && is_mem_mod(ir[2], ir[1]) && (
        mov_r_rm_b  (ir[3], ir[2]) || mov_r_rm_w (ir[3], ir[2]) ||
        xchg_r_rm_b (ir[3], ir[2]) || xchg_r_rm_w(ir[3], ir[2]) ||
        add_rm_r_b  (ir[3], ir[2]) || add_r_rm_b (ir[3], ir[2]) ||
        add_rm_r_w  (ir[3], ir[2]) || add_r_rm_w (ir[3], ir[2]) ||
        adc_rm_r_b  (ir[3], ir[2]) || adc_r_rm_b (ir[3], ir[2]) ||
        adc_rm_r_w  (ir[3], ir[2]) || adc_r_rm_w (ir[3], ir[2]) ||
        sub_rm_r_b  (ir[3], ir[2]) || sub_r_rm_b (ir[3], ir[2]) ||
        sub_rm_r_w  (ir[3], ir[2]) || sub_r_rm_w (ir[3], ir[2]) ||
        sbb_rm_r_b  (ir[3], ir[2]) || sbb_r_rm_b (ir[3], ir[2]) ||
        sbb_rm_r_w  (ir[3], ir[2]) || sbb_r_rm_w (ir[3], ir[2]) ||
        cmp_rm_r_b  (ir[3], ir[2]) || cmp_r_rm_b (ir[3], ir[2]) ||
        cmp_rm_r_w  (ir[3], ir[2]) || cmp_r_rm_w (ir[3], ir[2]) ||
        push_rm     (ir[3], ir[2]) ||
        add_rm_i_b  (ir[3], ir[2]) || add_rm_zi_w (ir[3], ir[2]) || add_rm_si_w (ir[3], ir[2]) ||
        adc_rm_i_b  (ir[3], ir[2]) || adc_rm_zi_w (ir[3], ir[2]) || adc_rm_si_w (ir[3], ir[2]) ||
        sub_rm_i_b  (ir[3], ir[2]) || sub_rm_zi_w (ir[3], ir[2]) || sub_rm_si_w (ir[3], ir[2]) ||
        sbb_rm_i_b  (ir[3], ir[2]) || sbb_rm_zi_w (ir[3], ir[2]) || sbb_rm_si_w (ir[3], ir[2]) ||
        cmp_rm_i_b  (ir[3], ir[2]) || cmp_rm_zi_w (ir[3], ir[2]) || cmp_rm_si_w (ir[3], ir[2]) ||
        inc_rm_b    (ir[3], ir[2]) || inc_rm_w    (ir[3], ir[2]) ||
        dec_rm_b    (ir[3], ir[2]) || dec_rm_w    (ir[3], ir[2]) ||
        neg_rm_b    (ir[3], ir[2]) || neg_rm_w    (ir[3], ir[2]) ||
        mul_r_rm_b  (ir[3], ir[2]) || mul_r_rm_w  (ir[3], ir[2]) ||
        imul_r_rm_b (ir[3], ir[2]) || imul_r_rm_w (ir[3], ir[2]) ||
        div_r_rm_b  (ir[3], ir[2]) || div_r_rm_w  (ir[3], ir[2]) ||
        idiv_r_rm_b (ir[3], ir[2]) || idiv_r_rm_w (ir[3], ir[2]) ||
        shl_rm_1_b  (ir[3], ir[2]) || shl_rm_c_b  (ir[3], ir[2]) || shl_rm_1_w  (ir[3], ir[2]) || shl_rm_c_w  (ir[3], ir[2]) ||
        shr_rm_1_b  (ir[3], ir[2]) || shr_rm_c_b  (ir[3], ir[2]) || shr_rm_1_w  (ir[3], ir[2]) || shr_rm_c_w  (ir[3], ir[2]) ||
        sar_rm_1_b  (ir[3], ir[2]) || sar_rm_c_b  (ir[3], ir[2]) || sar_rm_1_w  (ir[3], ir[2]) || sar_rm_c_w  (ir[3], ir[2]) ||
        rol_rm_1_b  (ir[3], ir[2]) || rol_rm_c_b  (ir[3], ir[2]) || rol_rm_1_w  (ir[3], ir[2]) || rol_rm_c_w  (ir[3], ir[2]) ||
        ror_rm_1_b  (ir[3], ir[2]) || ror_rm_c_b  (ir[3], ir[2]) || ror_rm_1_w  (ir[3], ir[2]) || ror_rm_c_w  (ir[3], ir[2]) ||
        rcl_rm_1_b  (ir[3], ir[2]) || rcl_rm_c_b  (ir[3], ir[2]) || rcl_rm_1_w  (ir[3], ir[2]) || rcl_rm_c_w  (ir[3], ir[2]) ||
        rcr_rm_1_b  (ir[3], ir[2]) || rcr_rm_c_b  (ir[3], ir[2]) || rcr_rm_1_w  (ir[3], ir[2]) || rcr_rm_c_w  (ir[3], ir[2]) ||
        and_rm_r_b  (ir[3], ir[2]) || and_r_rm_b  (ir[3], ir[2]) || and_rm_r_w  (ir[3], ir[2]) || and_r_rm_w  (ir[3], ir[2]) ||
        test_rm_r_b (ir[3], ir[2]) || test_r_rm_b (ir[3], ir[2]) || test_rm_r_w (ir[3], ir[2]) || test_r_rm_w (ir[3], ir[2]) ||
        or_rm_r_b   (ir[3], ir[2]) || or_r_rm_b   (ir[3], ir[2]) || or_rm_r_w   (ir[3], ir[2]) || or_r_rm_w   (ir[3], ir[2]) ||
        xor_rm_r_b  (ir[3], ir[2]) || xor_r_rm_b  (ir[3], ir[2]) || xor_rm_r_w  (ir[3], ir[2]) || xor_r_rm_w  (ir[3], ir[2]) ||
        not_rm_b    (ir[3], ir[2]) || not_rm_w    (ir[3], ir[2]) ||
        and_rm_i_b  (ir[3], ir[2]) || and_rm_i_w  (ir[3], ir[2]) ||
        test_rm_i_b (ir[3], ir[2]) || test_rm_i_w (ir[3], ir[2]) ||
        or_rm_i_b   (ir[3], ir[2]) || or_rm_i_w   (ir[3], ir[2]) ||
        xor_rm_i_b  (ir[3], ir[2]) || xor_rm_i_w  (ir[3], ir[2]) ||
        call_rm_dir (ir[3], ir[2]) || call_rm_ptr (ir[3], ir[2]) ||
        jmp_rm_dir  (ir[3], ir[2]) || jmp_rm_ptr  (ir[3], ir[2]) ||
    )) || (first_byte[3] && (
        mov_a_m_b   (ir[3], ir[2]) || mov_a_m_w   (ir[3], ir[2]) ||
        pop_rm      (ir[3], ir[2]) ||
        pop_r       (ir[3], ir[2]) ||
        pop_sr      (ir[3], ir[2]) ||
        popf        (ir[3], ir[2]) ||
        xlat        (ir[3], ir[2]) ||
        lds         (ir[3], ir[2]) ||
        les         (ir[3], ir[2]) ||
        movs_b      (ir[3], ir[2]) || movs_w      (ir[3], ir[2]) ||
        cmps_b      (ir[3], ir[2]) || cmps_w      (ir[3], ir[2]) ||
        scas_b      (ir[3], ir[2]) || scas_w      (ir[3], ir[2]) ||
        lods_b      (ir[3], ir[2]) || lods_w      (ir[3], ir[2]) ||
        ret         (ir[3], ir[2]) || ret_i       (ir[3], ir[2]) ||
        retf        (ir[3], ir[2]) || retf_i      (ir[3], ir[2])
    )) || (first_byte[4] && (
        cmps_b      (ir[4], ir[3]) ||
        cmps_w      (ir[4], ir[3]) 
    ));

    assign ram_rd_we = (first_byte[3] && is_mem_mod(ir[2], ir[1]) && (
        mov_r_rm_w  (ir[3], ir[2]) ||
        push_rm     (ir[3], ir[2]) ||
        xchg_r_rm_w (ir[3], ir[2]) ||
        add_rm_r_w  (ir[3], ir[2]) || add_r_rm_w  (ir[3], ir[2]) ||
        adc_rm_r_w  (ir[3], ir[2]) || adc_r_rm_w  (ir[3], ir[2]) ||
        sub_rm_r_w  (ir[3], ir[2]) || sub_r_rm_w  (ir[3], ir[2]) ||
        sbb_rm_r_w  (ir[3], ir[2]) || sbb_r_rm_w  (ir[3], ir[2]) ||
        cmp_rm_r_w  (ir[3], ir[2]) || cmp_r_rm_w  (ir[3], ir[2]) ||
        add_rm_zi_w (ir[3], ir[2]) || add_rm_si_w (ir[3], ir[2]) ||
        adc_rm_zi_w (ir[3], ir[2]) || adc_rm_si_w (ir[3], ir[2]) ||
        sub_rm_zi_w (ir[3], ir[2]) || sub_rm_si_w (ir[3], ir[2]) ||
        sbb_rm_zi_w (ir[3], ir[2]) || sbb_rm_si_w (ir[3], ir[2]) ||
        cmp_rm_zi_w (ir[3], ir[2]) || cmp_rm_si_w (ir[3], ir[2]) ||
        inc_rm_w    (ir[3], ir[2]) ||
        dec_rm_w    (ir[3], ir[2]) ||
        neg_rm_w    (ir[3], ir[2]) ||
        mul_r_rm_w  (ir[3], ir[2]) ||
        imul_r_rm_w (ir[3], ir[2]) ||
        div_r_rm_w  (ir[3], ir[2]) ||
        idiv_r_rm_w (ir[3], ir[2]) ||
        shl_rm_1_w  (ir[3], ir[2]) || shl_rm_c_w  (ir[3], ir[2]) ||
        shr_rm_1_w  (ir[3], ir[2]) || shr_rm_c_w  (ir[3], ir[2]) ||
        sar_rm_1_w  (ir[3], ir[2]) || sar_rm_c_w  (ir[3], ir[2]) ||
        rol_rm_1_w  (ir[3], ir[2]) || rol_rm_c_w  (ir[3], ir[2]) ||
        ror_rm_1_w  (ir[3], ir[2]) || ror_rm_c_w  (ir[3], ir[2]) ||
        rcl_rm_1_w  (ir[3], ir[2]) || rcl_rm_c_w  (ir[3], ir[2]) ||
        rcr_rm_1_w  (ir[3], ir[2]) || rcr_rm_c_w  (ir[3], ir[2]) ||
        and_rm_r_w  (ir[3], ir[2]) || and_r_rm_w  (ir[3], ir[2]) ||
        test_rm_r_w (ir[3], ir[2]) || test_r_rm_w (ir[3], ir[2]) ||
        or_rm_r_w   (ir[3], ir[2]) || or_r_rm_w   (ir[3], ir[2]) ||
        xor_rm_r_w  (ir[3], ir[2]) || xor_r_rm_w  (ir[3], ir[2]) ||
        not_rm_w    (ir[3], ir[2]) ||
        and_rm_i_w  (ir[3], ir[2]) ||
        test_rm_i_w (ir[3], ir[2]) ||
        or_rm_i_w   (ir[3], ir[2]) ||
        xor_rm_i_w  (ir[3], ir[2]) ||
        call_rm_dir (ir[3], ir[2]) || call_rm_ptr (ir[3], ir[2]) ||
        jmp_rm_dir  (ir[3], ir[2]) || jmp_rm_ptr  (ir[3], ir[2])
    )) || (first_byte[3] && (
        mov_a_m_w   (ir[3], ir[2]) ||
        pop_rm      (ir[3], ir[2]) ||
        pop_r       (ir[3], ir[2]) ||
        pop_sr      (ir[3], ir[2]) ||
        popf        (ir[3], ir[2]) ||
        lds         (ir[3], ir[2]) ||
        les         (ir[3], ir[2]) ||
        movs_w      (ir[3], ir[2]) ||
        cmps_w      (ir[3], ir[2]) ||
        scas_w      (ir[3], ir[2]) ||
        lods_w      (ir[3], ir[2]) ||
        ret         (ir[3], ir[2]) || ret_i       (ir[3], ir[2]) ||
        retf        (ir[3], ir[2]) || retf_i      (ir[3], ir[2])
    )) || (first_byte[4] && (
        cmps_w      (ir[4], ir[3]) 
    ));

    assign ram_rd_de = (first_byte[3] && is_mem_mod(ir[2], ir[1]) && (
        call_rm_ptr (ir[3], ir[2]) ||
        jmp_rm_ptr  (ir[3], ir[2]) 
    )) || (first_byte[3] && (
        lds         (ir[3], ir[2]) ||
        les         (ir[3], ir[2]) ||
        retf        (ir[3], ir[2]) ||
        retf_i      (ir[3], ir[2])
    ));

    reg [19:0] ram_rd_addr_signal;

    always @(*) begin
        if (~rst)
            ram_rd_addr_signal = 'b0;
        else if ((first_byte[3] && is_mem_mod(ir[2], ir[1]) && (
            mov_r_rm_b  (ir[3], ir[2]) || mov_r_rm_w (ir[3], ir[2]) ||
            xchg_r_rm_b (ir[3], ir[2]) || xchg_r_rm_w(ir[3], ir[2]) ||
            add_rm_r_b  (ir[3], ir[2]) || add_r_rm_b (ir[3], ir[2]) ||
            add_rm_r_w  (ir[3], ir[2]) || add_r_rm_w (ir[3], ir[2]) ||
            adc_rm_r_b  (ir[3], ir[2]) || adc_r_rm_b (ir[3], ir[2]) ||
            adc_rm_r_w  (ir[3], ir[2]) || adc_r_rm_w (ir[3], ir[2]) ||
            sub_rm_r_b  (ir[3], ir[2]) || sub_r_rm_b (ir[3], ir[2]) ||
            sub_rm_r_w  (ir[3], ir[2]) || sub_r_rm_w (ir[3], ir[2]) ||
            sbb_rm_r_b  (ir[3], ir[2]) || sbb_r_rm_b (ir[3], ir[2]) ||
            sbb_rm_r_w  (ir[3], ir[2]) || sbb_r_rm_w (ir[3], ir[2]) ||
            cmp_rm_r_b  (ir[3], ir[2]) || cmp_r_rm_b (ir[3], ir[2]) ||
            cmp_rm_r_w  (ir[3], ir[2]) || cmp_r_rm_w (ir[3], ir[2]) ||
            push_rm     (ir[3], ir[2]) ||
            add_rm_i_b  (ir[3], ir[2]) || add_rm_zi_w (ir[3], ir[2]) || add_rm_si_w (ir[3], ir[2]) ||
            adc_rm_i_b  (ir[3], ir[2]) || adc_rm_zi_w (ir[3], ir[2]) || adc_rm_si_w (ir[3], ir[2]) ||
            sub_rm_i_b  (ir[3], ir[2]) || sub_rm_zi_w (ir[3], ir[2]) || sub_rm_si_w (ir[3], ir[2]) ||
            sbb_rm_i_b  (ir[3], ir[2]) || sbb_rm_zi_w (ir[3], ir[2]) || sbb_rm_si_w (ir[3], ir[2]) ||
            cmp_rm_i_b  (ir[3], ir[2]) || cmp_rm_zi_w (ir[3], ir[2]) || cmp_rm_si_w (ir[3], ir[2]) ||
            inc_rm_b    (ir[3], ir[2]) || inc_rm_w    (ir[3], ir[2]) ||
            dec_rm_b    (ir[3], ir[2]) || dec_rm_w    (ir[3], ir[2]) ||
            neg_rm_b    (ir[3], ir[2]) || neg_rm_w    (ir[3], ir[2]) ||
            mul_r_rm_b  (ir[3], ir[2]) || mul_r_rm_w  (ir[3], ir[2]) ||
            imul_r_rm_b (ir[3], ir[2]) || imul_r_rm_w (ir[3], ir[2]) ||
            div_r_rm_b  (ir[3], ir[2]) || div_r_rm_w  (ir[3], ir[2]) ||
            idiv_r_rm_b (ir[3], ir[2]) || idiv_r_rm_w (ir[3], ir[2]) ||
            shl_rm_1_b  (ir[3], ir[2]) || shl_rm_c_b  (ir[3], ir[2]) || shl_rm_1_w  (ir[3], ir[2]) || shl_rm_c_w  (ir[3], ir[2]) ||
            shr_rm_1_b  (ir[3], ir[2]) || shr_rm_c_b  (ir[3], ir[2]) || shr_rm_1_w  (ir[3], ir[2]) || shr_rm_c_w  (ir[3], ir[2]) ||
            sar_rm_1_b  (ir[3], ir[2]) || sar_rm_c_b  (ir[3], ir[2]) || sar_rm_1_w  (ir[3], ir[2]) || sar_rm_c_w  (ir[3], ir[2]) ||
            rol_rm_1_b  (ir[3], ir[2]) || rol_rm_c_b  (ir[3], ir[2]) || rol_rm_1_w  (ir[3], ir[2]) || rol_rm_c_w  (ir[3], ir[2]) ||
            ror_rm_1_b  (ir[3], ir[2]) || ror_rm_c_b  (ir[3], ir[2]) || ror_rm_1_w  (ir[3], ir[2]) || ror_rm_c_w  (ir[3], ir[2]) ||
            rcl_rm_1_b  (ir[3], ir[2]) || rcl_rm_c_b  (ir[3], ir[2]) || rcl_rm_1_w  (ir[3], ir[2]) || rcl_rm_c_w  (ir[3], ir[2]) ||
            rcr_rm_1_b  (ir[3], ir[2]) || rcr_rm_c_b  (ir[3], ir[2]) || rcr_rm_1_w  (ir[3], ir[2]) || rcr_rm_c_w  (ir[3], ir[2]) ||
            and_rm_r_b  (ir[3], ir[2]) || and_r_rm_b  (ir[3], ir[2]) || and_rm_r_w  (ir[3], ir[2]) || and_r_rm_w  (ir[3], ir[2]) ||
            test_rm_r_b (ir[3], ir[2]) || test_r_rm_b (ir[3], ir[2]) || test_rm_r_w (ir[3], ir[2]) || test_r_rm_w (ir[3], ir[2]) ||
            or_rm_r_b   (ir[3], ir[2]) || or_r_rm_b   (ir[3], ir[2]) || or_rm_r_w   (ir[3], ir[2]) || or_r_rm_w   (ir[3], ir[2]) ||
            xor_rm_r_b  (ir[3], ir[2]) || xor_r_rm_b  (ir[3], ir[2]) || xor_rm_r_w  (ir[3], ir[2]) || xor_r_rm_w  (ir[3], ir[2]) ||
            not_rm_b    (ir[3], ir[2]) || not_rm_w    (ir[3], ir[2]) ||
            and_rm_i_b  (ir[3], ir[2]) || and_rm_i_w  (ir[3], ir[2]) ||
            test_rm_i_b (ir[3], ir[2]) || test_rm_i_w (ir[3], ir[2]) ||
            or_rm_i_b   (ir[3], ir[2]) || or_rm_i_w   (ir[3], ir[2]) ||
            xor_rm_i_b  (ir[3], ir[2]) || xor_rm_i_w  (ir[3], ir[2]) ||
            call_rm_dir (ir[3], ir[2]) || call_rm_ptr (ir[3], ir[2]) ||
            jmp_rm_dir  (ir[3], ir[2]) || jmp_rm_ptr  (ir[3], ir[2])
        )) || (first_byte[3] && (
            mov_a_m_b   (ir[3], ir[2]) || mov_a_m_w   (ir[3], ir[2]) ||
            lds         (ir[3], ir[2]) ||
            les         (ir[3], ir[2])
        )))
            ram_rd_addr_signal = {`DS, 4'b0} + addr_reg;
        else if (first_byte[3] && (
            pop_rm      (ir[3], ir[2]) ||
            pop_r       (ir[3], ir[2]) ||
            pop_sr      (ir[3], ir[2]) ||
            popf        (ir[3], ir[2]) ||
            ret         (ir[3], ir[2]) || ret_i       (ir[3], ir[2]) ||
            retf        (ir[3], ir[2]) || retf_i      (ir[3], ir[2])
        ))
            ram_rd_addr_signal = {`SS, 4'b0} + `SP;
        else if (first_byte[3] && xlat(ir[3], ir[2]))
            ram_rd_addr_signal = `BX + {8'b0, `AL};
        else if (first_byte[3] && (
            movs_b      (ir[3], ir[2]) || movs_w      (ir[3], ir[2]) ||
            cmps_b      (ir[3], ir[2]) || cmps_w      (ir[3], ir[2]) ||
            lods_b      (ir[3], ir[2]) || lods_w      (ir[3], ir[2])
        ))
            ram_rd_addr_signal = {`DS, 4'b0} + `SI;
        else if (first_byte[3] && (scas_b(ir[3], ir[2]) || scas_w(ir[3], ir[2])))
            ram_rd_addr_signal = {`ES, 4'b0} + `DI;
        else if (first_byte[4] && (cmps_b(ir[4], ir[3]) || cmps_w(ir[4], ir[3])))
            ram_rd_addr_signal = {`ES, 4'b0} + `DI;
        else
            ram_rd_addr_signal = 'b0;
    end

    assign ram_rd_addr = ram_rd_addr_signal;

    assign ram_wr_en = (first_byte[4] && is_mem_mod(ir[3], ir[2]) && (
        mov_rm_r_b  (ir[4], ir[3]) || mov_rm_r_w  (ir[4], ir[3]) ||
        xchg_r_rm_b (ir[4], ir[3]) || xchg_r_rm_w (ir[4], ir[3]) ||
        add_rm_r_b  (ir[4], ir[3]) || add_rm_r_w  (ir[4], ir[3]) ||
        adc_rm_r_b  (ir[4], ir[3]) || adc_rm_r_w  (ir[4], ir[3]) ||
        sub_rm_r_b  (ir[4], ir[3]) || sub_rm_r_w  (ir[4], ir[3]) ||
        sbb_rm_r_b  (ir[4], ir[3]) || sbb_rm_r_w  (ir[4], ir[3]) ||
        mov_rm_i_b  (ir[4], ir[3]) || mov_rm_i_w  (ir[4], ir[3]) ||
        add_rm_i_b  (ir[4], ir[3]) || add_rm_zi_w (ir[4], ir[3]) || add_rm_si_w (ir[4], ir[3]) ||
        adc_rm_i_b  (ir[4], ir[3]) || adc_rm_zi_w (ir[4], ir[3]) || adc_rm_si_w (ir[4], ir[3]) ||
        sub_rm_i_b  (ir[4], ir[3]) || sub_rm_zi_w (ir[4], ir[3]) || sub_rm_si_w (ir[4], ir[3]) ||
        sbb_rm_i_b  (ir[4], ir[3]) || sbb_rm_zi_w (ir[4], ir[3]) || sbb_rm_si_w (ir[4], ir[3]) ||
        inc_rm_b    (ir[4], ir[3]) || inc_rm_w    (ir[4], ir[3]) ||
        dec_rm_b    (ir[4], ir[3]) || dec_rm_w    (ir[4], ir[3]) ||
        neg_rm_b    (ir[4], ir[3]) || neg_rm_w    (ir[4], ir[3]) ||
        shl_rm_1_b  (ir[4], ir[3]) || shl_rm_c_b  (ir[4], ir[3]) || shl_rm_1_w  (ir[4], ir[3]) || shl_rm_c_w  (ir[4], ir[3]) ||
        shr_rm_1_b  (ir[4], ir[3]) || shr_rm_c_b  (ir[4], ir[3]) || shr_rm_1_w  (ir[4], ir[3]) || shr_rm_c_w  (ir[4], ir[3]) ||
        sar_rm_1_b  (ir[4], ir[3]) || sar_rm_c_b  (ir[4], ir[3]) || sar_rm_1_w  (ir[4], ir[3]) || sar_rm_c_w  (ir[4], ir[3]) ||
        rol_rm_1_b  (ir[4], ir[3]) || rol_rm_c_b  (ir[4], ir[3]) || rol_rm_1_w  (ir[4], ir[3]) || rol_rm_c_w  (ir[4], ir[3]) ||
        ror_rm_1_b  (ir[4], ir[3]) || ror_rm_c_b  (ir[4], ir[3]) || ror_rm_1_w  (ir[4], ir[3]) || ror_rm_c_w  (ir[4], ir[3]) ||
        rcl_rm_1_b  (ir[4], ir[3]) || rcl_rm_c_b  (ir[4], ir[3]) || rcl_rm_1_w  (ir[4], ir[3]) || rcl_rm_c_w  (ir[4], ir[3]) ||
        rcr_rm_1_b  (ir[4], ir[3]) || rcr_rm_c_b  (ir[4], ir[3]) || rcr_rm_1_w  (ir[4], ir[3]) || rcr_rm_c_w  (ir[4], ir[3]) ||
        not_rm_b    (ir[4], ir[3]) || not_rm_w    (ir[4], ir[3]) ||
        and_rm_r_b  (ir[4], ir[3]) || and_rm_r_w  (ir[4], ir[3]) ||
        or_rm_r_b   (ir[4], ir[3]) || or_rm_r_w   (ir[4], ir[3]) ||
        xor_rm_r_b  (ir[4], ir[3]) || xor_rm_r_w  (ir[4], ir[3]) ||
        and_rm_i_b  (ir[4], ir[3]) || and_rm_i_w  (ir[4], ir[3]) ||
        or_rm_i_b   (ir[4], ir[3]) || or_rm_i_w   (ir[4], ir[3]) ||
        xor_rm_i_b  (ir[4], ir[3]) || xor_rm_i_w  (ir[4], ir[3]) ||
    )) || (first_byte[4] && (
        mov_m_a_b   (ir[4], ir[3]) || mov_m_a_w   (ir[4], ir[3]) ||
        push_rm     (ir[4], ir[3]) ||
        push_r      (ir[4], ir[3]) ||
        push_sr     (ir[4], ir[3]) ||
        pushf       (ir[4], ir[3]) ||
        movs_b      (ir[4], ir[3]) || movs_w      (ir[4], ir[3]) ||
        stos_b      (ir[4], ir[3]) || stos_w      (ir[4], ir[3]) ||
        call_i_dir  (ir[4], ir[3]) || call_rm_dir (ir[4], ir[3]) ||
        call_i_ptr  (ir[4], ir[3]) || call_rm_ptr (ir[4], ir[3])
    ));
    
    assign ram_wr_we = (first_byte[4] && is_mem_mod(ir[3], ir[2]) && (
        mov_rm_r_w  (ir[4], ir[3]) ||
        mov_rm_i_w  (ir[4], ir[3]) ||
        xchg_r_rm_w (ir[4], ir[3]) ||
        add_rm_r_w  (ir[4], ir[3]) ||
        adc_rm_r_w  (ir[4], ir[3]) ||
        sub_rm_r_w  (ir[4], ir[3]) ||
        sbb_rm_r_w  (ir[4], ir[3]) ||
        add_rm_zi_w (ir[4], ir[3]) || add_rm_si_w (ir[4], ir[3]) ||
        adc_rm_zi_w (ir[4], ir[3]) || adc_rm_si_w (ir[4], ir[3]) ||
        sub_rm_zi_w (ir[4], ir[3]) || sub_rm_si_w (ir[4], ir[3]) ||
        sbb_rm_zi_w (ir[4], ir[3]) || sbb_rm_si_w (ir[4], ir[3]) ||
        inc_rm_w    (ir[4], ir[3]) ||
        dec_rm_w    (ir[4], ir[3]) ||
        neg_rm_w    (ir[4], ir[3]) ||
        shl_rm_1_w  (ir[4], ir[3]) || shl_rm_c_w  (ir[4], ir[3]) ||
        shr_rm_1_w  (ir[4], ir[3]) || shr_rm_c_w  (ir[4], ir[3]) ||
        sar_rm_1_w  (ir[4], ir[3]) || sar_rm_c_w  (ir[4], ir[3]) ||
        rol_rm_1_w  (ir[4], ir[3]) || rol_rm_c_w  (ir[4], ir[3]) ||
        ror_rm_1_w  (ir[4], ir[3]) || ror_rm_c_w  (ir[4], ir[3]) ||
        rcl_rm_1_w  (ir[4], ir[3]) || rcl_rm_c_w  (ir[4], ir[3]) ||
        rcr_rm_1_w  (ir[4], ir[3]) || rcr_rm_c_w  (ir[4], ir[3]) ||
        not_rm_w    (ir[4], ir[3]) ||
        and_rm_r_w  (ir[4], ir[3]) ||
        or_rm_r_w   (ir[4], ir[3]) ||
        xor_rm_r_w  (ir[4], ir[3]) ||
        and_rm_i_w  (ir[4], ir[3]) ||
        or_rm_i_w   (ir[4], ir[3]) ||
        xor_rm_i_w  (ir[4], ir[3]) 
    )) || (first_byte[4] && (
        mov_m_a_w   (ir[4], ir[3]) ||
        push_rm     (ir[4], ir[3]) ||
        push_r      (ir[4], ir[3]) ||
        push_sr     (ir[4], ir[3]) ||
        pushf       (ir[4], ir[3]) ||
        movs_w      (ir[4], ir[3]) ||
        stos_w      (ir[4], ir[3]) ||
        call_i_dir  (ir[4], ir[3]) || call_rm_dir (ir[4], ir[3]) ||
        call_i_ptr  (ir[4], ir[3]) || call_rm_ptr (ir[4], ir[3])
    ));

    reg [19:0] ram_wr_addr_signal;

    always @(*) begin
        if (~rst)
            ram_wr_addr_signal = 'b0;
        else if ((first_byte[4] && is_mem_mod(ir[3], ir[2]) && (
            mov_rm_r_b  (ir[4], ir[3]) || mov_rm_r_w  (ir[4], ir[3]) ||
            xchg_r_rm_b (ir[4], ir[3]) || xchg_r_rm_w (ir[4], ir[3]) ||
            add_rm_r_b  (ir[4], ir[3]) || add_rm_r_w  (ir[4], ir[3]) ||
            adc_rm_r_b  (ir[4], ir[3]) || adc_rm_r_w  (ir[4], ir[3]) ||
            sub_rm_r_b  (ir[4], ir[3]) || sub_rm_r_w  (ir[4], ir[3]) ||
            sbb_rm_r_b  (ir[4], ir[3]) || sbb_rm_r_w  (ir[4], ir[3]) ||
            mov_rm_i_b  (ir[4], ir[3]) || mov_rm_i_w  (ir[4], ir[3]) ||
            add_rm_i_b  (ir[4], ir[3]) || add_rm_zi_w (ir[4], ir[3]) || add_rm_si_w (ir[4], ir[3]) ||
            adc_rm_i_b  (ir[4], ir[3]) || adc_rm_zi_w (ir[4], ir[3]) || adc_rm_si_w (ir[4], ir[3]) ||
            sub_rm_i_b  (ir[4], ir[3]) || sub_rm_zi_w (ir[4], ir[3]) || sub_rm_si_w (ir[4], ir[3]) ||
            sbb_rm_i_b  (ir[4], ir[3]) || sbb_rm_zi_w (ir[4], ir[3]) || sbb_rm_si_w (ir[4], ir[3]) ||
            inc_rm_b    (ir[4], ir[3]) || inc_rm_w    (ir[4], ir[3]) ||
            dec_rm_b    (ir[4], ir[3]) || dec_rm_w    (ir[4], ir[3]) ||
            neg_rm_b    (ir[4], ir[3]) || neg_rm_w    (ir[4], ir[3]) ||
            shl_rm_1_b  (ir[4], ir[3]) || shl_rm_c_b  (ir[4], ir[3]) || shl_rm_1_w  (ir[4], ir[3]) || shl_rm_c_w  (ir[4], ir[3]) ||
            shr_rm_1_b  (ir[4], ir[3]) || shr_rm_c_b  (ir[4], ir[3]) || shr_rm_1_w  (ir[4], ir[3]) || shr_rm_c_w  (ir[4], ir[3]) ||
            sar_rm_1_b  (ir[4], ir[3]) || sar_rm_c_b  (ir[4], ir[3]) || sar_rm_1_w  (ir[4], ir[3]) || sar_rm_c_w  (ir[4], ir[3]) ||
            rol_rm_1_b  (ir[4], ir[3]) || rol_rm_c_b  (ir[4], ir[3]) || rol_rm_1_w  (ir[4], ir[3]) || rol_rm_c_w  (ir[4], ir[3]) ||
            ror_rm_1_b  (ir[4], ir[3]) || ror_rm_c_b  (ir[4], ir[3]) || ror_rm_1_w  (ir[4], ir[3]) || ror_rm_c_w  (ir[4], ir[3]) ||
            rcl_rm_1_b  (ir[4], ir[3]) || rcl_rm_c_b  (ir[4], ir[3]) || rcl_rm_1_w  (ir[4], ir[3]) || rcl_rm_c_w  (ir[4], ir[3]) ||
            rcr_rm_1_b  (ir[4], ir[3]) || rcr_rm_c_b  (ir[4], ir[3]) || rcr_rm_1_w  (ir[4], ir[3]) || rcr_rm_c_w  (ir[4], ir[3]) ||
            not_rm_b    (ir[4], ir[3]) || not_rm_w    (ir[4], ir[3]) ||
            and_rm_r_b  (ir[4], ir[3]) || and_rm_r_w  (ir[4], ir[3]) ||
            or_rm_r_b   (ir[4], ir[3]) || or_rm_r_w   (ir[4], ir[3]) ||
            xor_rm_r_b  (ir[4], ir[3]) || xor_rm_r_w  (ir[4], ir[3]) ||
            and_rm_i_b  (ir[4], ir[3]) || and_rm_i_w  (ir[4], ir[3]) ||
            or_rm_i_b   (ir[4], ir[3]) || or_rm_i_w   (ir[4], ir[3]) ||
            xor_rm_i_b  (ir[4], ir[3]) || xor_rm_i_w  (ir[4], ir[3])
        )) || (first_byte[4] && (
            mov_m_a_b   (ir[4], ir[3]) || mov_m_a_w   (ir[4], ir[3])
        )))
            ram_wr_addr_signal = {`DS, 4'b0} + addr_reg;
        else if (first_byte[4] && (
            push_rm     (ir[4], ir[3]) ||
            push_r      (ir[4], ir[3]) ||
            push_sr     (ir[4], ir[3]) ||
            pushf       (ir[4], ir[3]) ||
            call_i_dir  (ir[4], ir[3]) || call_rm_dir (ir[4], ir[3]) ||
            call_i_ptr  (ir[4], ir[3]) || call_rm_ptr (ir[4], ir[3])
        ))
            ram_wr_addr_signal = {`SS, 4'b0} + `SP - 'h2;
        else if (first_byte[4] && (
            movs_b      (ir[4], ir[3]) || movs_w      (ir[4], ir[3]) ||
            stos_b      (ir[4], ir[3]) || stos_w      (ir[4], ir[3])
        ))
            ram_wr_addr_signal = {`ES, 4'b0} + `DI;
        else
            ram_wr_addr_signal = 'b0;
    end

    assign ram_wr_addr = ram_wr_addr_signal;

    reg [15:0] ram_wr_data_signal;

    always @(*) begin
        if (~rst)
            ram_wr_data_signal = 'b0;
        else if (first_byte[4] && is_mem_mod(ir[3] && (
            mov_rm_r_b  (ir[4], ir[3]) ||
            mov_rm_r_w  (ir[4], ir[3])
        )) || (first_byte[4] && (
            mov_m_a_b   (ir[4], ir[3]) || mov_m_a_w   (ir[4], ir[3]) ||
            push_rm     (ir[4], ir[3]) ||
            push_r      (ir[4], ir[3]) ||
            push_sr     (ir[4], ir[3]) ||
            pushf       (ir[4], ir[3]) ||
            movs_b      (ir[4], ir[3]) || movs_w      (ir[4], ir[3])
        )))
            ram_wr_data_signal = data_reg;
        else if ((first_byte[4] && is_mem_mod(ir[3], ir[2]) && mov_rm_i_b(ir[4], ir[3])))
            ram_wr_data_signal = {8'b0, 
                disp0(ir[3], ir[2]) ? ir[2] :
                disp1(ir[3], ir[2]) ? ir[1] :
                disp2(ir[3], ir[2]) ? ir[0] :
                'b0
            };
        else if ((first_byte[4] && is_mem_mod(ir[3], ir[2]) && mov_rm_i_w(ir[4], ir[3])))
            ram_wr_data_signal = 
                disp0(ir[3], ir[2]) ? {ir[1], ir[2]} :
                disp1(ir[3], ir[2]) ? {ir[0], ir[1]} :
                disp2(ir[3], ir[2]) ? {rom_data,    ir[0]} :
                'b0;
        else if ((first_byte[4] && is_mem_mod(ir[3], ir[2]) && xchg_r_rm_b(ir[4], ir[3])))
            ram_wr_data_signal = register[reg_b(field_reg(ir[3], ir[2])) +:  8];
        else if ((first_byte[4] && is_mem_mod(ir[3], ir[2]) && xchg_r_rm_w(ir[4], ir[3])))
            ram_wr_data_signal = register[reg_w(field_reg(ir[3], ir[2])) +: 16];
        else if ((first_byte[4] && is_mem_mod(ir[3], ir[2]) && (
            add_rm_r_b  (ir[4], ir[3]) || add_rm_r_w  (ir[4], ir[3]) ||
            adc_rm_r_b  (ir[4], ir[3]) || adc_rm_r_w  (ir[4], ir[3]) ||
            sub_rm_r_b  (ir[4], ir[3]) || sub_rm_r_w  (ir[4], ir[3]) ||
            sbb_rm_r_b  (ir[4], ir[3]) || sbb_rm_r_w  (ir[4], ir[3]) ||
            add_rm_i_b  (ir[4], ir[3]) || add_rm_zi_w (ir[4], ir[3]) || add_rm_si_w (ir[4], ir[3]) ||
            adc_rm_i_b  (ir[4], ir[3]) || adc_rm_zi_w (ir[4], ir[3]) || adc_rm_si_w (ir[4], ir[3]) ||
            sub_rm_i_b  (ir[4], ir[3]) || sub_rm_zi_w (ir[4], ir[3]) || sub_rm_si_w (ir[4], ir[3]) ||
            sbb_rm_i_b  (ir[4], ir[3]) || sbb_rm_zi_w (ir[4], ir[3]) || sbb_rm_si_w (ir[4], ir[3]) ||
            inc_rm_b    (ir[4], ir[3]) || inc_rm_w    (ir[4], ir[3]) ||
            dec_rm_b    (ir[4], ir[3]) || dec_rm_w    (ir[4], ir[3]) ||
            neg_rm_b    (ir[4], ir[3]) || neg_rm_w    (ir[4], ir[3]) ||
            shl_rm_1_b  (ir[4], ir[3]) || shl_rm_c_b  (ir[4], ir[3]) || shl_rm_1_w  (ir[4], ir[3]) || shl_rm_c_w  (ir[4], ir[3]) ||
            shr_rm_1_b  (ir[4], ir[3]) || shr_rm_c_b  (ir[4], ir[3]) || shr_rm_1_w  (ir[4], ir[3]) || shr_rm_c_w  (ir[4], ir[3]) ||
            sar_rm_1_b  (ir[4], ir[3]) || sar_rm_c_b  (ir[4], ir[3]) || sar_rm_1_w  (ir[4], ir[3]) || sar_rm_c_w  (ir[4], ir[3]) ||
            rol_rm_1_b  (ir[4], ir[3]) || rol_rm_c_b  (ir[4], ir[3]) || rol_rm_1_w  (ir[4], ir[3]) || rol_rm_c_w  (ir[4], ir[3]) ||
            ror_rm_1_b  (ir[4], ir[3]) || ror_rm_c_b  (ir[4], ir[3]) || ror_rm_1_w  (ir[4], ir[3]) || ror_rm_c_w  (ir[4], ir[3]) ||
            rcl_rm_1_b  (ir[4], ir[3]) || rcl_rm_c_b  (ir[4], ir[3]) || rcl_rm_1_w  (ir[4], ir[3]) || rcl_rm_c_w  (ir[4], ir[3]) ||
            rcr_rm_1_b  (ir[4], ir[3]) || rcr_rm_c_b  (ir[4], ir[3]) || rcr_rm_1_w  (ir[4], ir[3]) || rcr_rm_c_w  (ir[4], ir[3]) ||
            not_rm_b    (ir[4], ir[3]) || not_rm_w    (ir[4], ir[3]) ||
            and_rm_r_b  (ir[4], ir[3]) || and_rm_r_w  (ir[4], ir[3]) ||
            or_rm_r_b   (ir[4], ir[3]) || or_rm_r_w   (ir[4], ir[3]) ||
            xor_rm_r_b  (ir[4], ir[3]) || xor_rm_r_w  (ir[4], ir[3]) ||
            and_rm_i_b  (ir[4], ir[3]) || and_rm_i_w  (ir[4], ir[3]) ||
            or_rm_i_b   (ir[4], ir[3]) || or_rm_i_w   (ir[4], ir[3]) ||
            xor_rm_i_b  (ir[4], ir[3]) || xor_rm_i_w  (ir[4], ir[3])
        )))
            ram_wr_data_signal = r;
        else if (first_byte[4] && stos_b(ir[4], ir[3]))
            ram_wr_data_signal = `AL;
        else if (first_byte[4] && stos_w(ir[4], ir[3]))
            ram_wr_data_signal = `AX;
        else if (first_byte[4] && (
            call_i_dir  (ir[4], ir[3]) || call_rm_dir (ir[4], ir[3]) ||
            call_i_ptr  (ir[4], ir[3]) || call_rm_ptr (ir[4], ir[3])
        ))
            ram_wr_data_signal = `CS;
        else if (call_i_ptr  (ir[4], ir[3]))
            ram_wr_data_signal = {`CS, ip - 'h1};
        else if (call_rm_ptr (ir[4], ir[3]))
            ram_wr_data_signal = {`CS, ip -
                disp0(ir[4], ir[3]) ? 'h4 :
                disp1(ir[4], ir[3]) ? 'h3 :
                disp2(ir[4], ir[3]) ? 'h2 :
                'h0
            };
        else
            ram_wr_data_signal = 'b0;
    end

    assign ram_wr_data = ram_wr_data_signal;

endmodule