`define AL register[7'b0000000 +:  8]
`define AH register[7'b0001000 +:  8]
`define CL register[7'b0010000 +:  8]
`define CH register[7'b0011000 +:  8]
`define DL register[7'b0100000 +:  8]
`define DH register[7'b0101000 +:  8]
`define BL register[7'b0110000 +:  8]
`define BH register[7'b0111000 +:  8]
`define AX register[7'b0000000 +: 16]
`define CX register[7'b0010000 +: 16]
`define DX register[7'b0100000 +: 16]
`define BX register[7'b0110000 +: 16]
`define SP register[7'b1000000 +: 16]
`define BP register[7'b1010000 +: 16]
`define SI register[7'b1100000 +: 16]
`define DI register[7'b1110000 +: 16]
`define ES segment_register[2'b0]
`define CS segment_register[2'b1]
`define SS segment_register[2'b2]
`define DS segment_register[2'b3]
`define OF flags[4'd11]
`define DF flags[4'd10]
`define IF flags[4'd9 ]
`define TF flags[4'd8 ]
`define SF flags[4'd7 ]
`define ZF flags[4'd6 ]
`define AF flags[4'd4 ]
`define PF flags[4'd2 ]
`define CF flags[4'd0 ]



// DATA TRANSFER OPERATIONS
// MOV
function mov_rm_r_b     (input[7:0]i);      mov_rm_r_b      = (i[7:0]==8'b10001000);                    endfunction
function mov_r_rm_b     (input[7:0]i);      mov_r_rm_b      = (i[7:0]==8'b10001010);                    endfunction
function mov_rm_r_w     (input[7:0]i);      mov_rm_r_w      = (i[7:0]==8'b10001001);                    endfunction
function mov_r_rm_w     (input[7:0]i);      mov_r_rm_w      = (i[7:0]==8'b10001011);                    endfunction
function mov_rm_i_b     (input[7:0]i1,i2);  mov_rm_i_b      = (i1[7:0]==8'b11000110&i2[5:3]==3'b000);   endfunction
function mov_rm_i_w     (input[7:0]i1,i2);  mov_rm_i_w      = (i1[7:0]==8'b11000111&i2[5:3]==3'b000);   endfunction
function mov_r_i_b      (input[7:0]i);      mov_r_i_b       = (i[7:3]==5'b10110);                       endfunction
function mov_r_i_w      (input[7:0]i);      mov_r_i_w       = (i[7:3]==5'b10111);                       endfunction
function mov_a_m_b      (input[7:0]i);      mov_a_m_b       = (i[7:0]==8'b10100000);                    endfunction
function mov_a_m_w      (input[7:0]i);      mov_a_m_w       = (i[7:0]==8'b10100001);                    endfunction
function mov_m_a_b      (input[7:0]i);      mov_m_a_b       = (i[7:0]==8'b10100010);                    endfunction
function mov_m_a_w      (input[7:0]i);      mov_m_a_w       = (i[7:0]==8'b10100011);                    endfunction
function mov_sr_rm      (input[7:0]i);      mov_sr_rm       = (i[7:0]==8'b10001110);                    endfunction
function mov_rm_sr      (input[7:0]i);      mov_rm_sr       = (i[7:0]==8'b10001100);                    endfunction
// PUSH
function push_rm        (input[7:0]i1,i2);  push_rm         = (i1[7:0]==8'b11111111&i2[5:3]==3'b110);   endfunction
function push_r         (input[7:0]i);      push_r          = (i[7:3]==5'b01010);                       endfunction
function push_sr        (input[7:0]i);      push_sr         = (i&'he7==8'b00000110);                    endfunction
// POP
function pop_rm         (input[7:0]i1,i2);  pop_rm          = (i1[7:0]==8'b10001111&i2[5:3]==3'b000);   endfunction
function pop_r          (input[7:0]i);      pop_r           = (i[7:3]==5'b01011);                       endfunction
function pop_sr         (input[7:0]i);      pop_sr          = (i&'he7==8'b00000111);                    endfunction
// XCHG
function xchg_r_rm_b    (input[7:0]i);      xchg_r_rm_b     = (i[7:0]==8'b10000110);                    endfunction
function xchg_r_rm_w    (input[7:0]i);      xchg_r_rm_w     = (i[7:0]==8'b10000111);                    endfunction
function xchg_a_r       (input[7:0]i);      xchg_a_r        = (i[7:3]==5'b10010);                       endfunction
// XLAT
function xlat           (input[7:0]i);      xlat            = (i[7:0]==8'b11010111);                    endfunction
// LEA
function lea            (input[7:0]i);      lea             = (i[7:0]==8'b10001101);                    endfunction
// LDS
function lds            (input[7:0]i);      lds             = (i[7:0]==8'b11000101);                    endfunction
// LES
function les            (input[7:0]i);      les             = (i[7:0]==8'b11000100);                    endfunction
// LAHF
function lahf           (input[7:0]i);      lahf            = (i[7:0]==8'b10011111);                    endfunction
// SAHF
function sahf           (input[7:0]i);      sahf            = (i[7:0]==8'b10011110);                    endfunction
// PUSHF
function pushf          (input[7:0]i);      pushf           = (i[7:0]==8'b10011100);                    endfunction
// POPF
function popf           (input[7:0]i)l      popf            = (i[7:0]==8'b10011101);                    endfunction

// ARITHMETIC OPERATIONS
// ADD
function add_rm_r_b     (input[7:0]i);      add_rm_r_b      = (i[7:0]==8'b00000000);                    endfunction
function add_r_rm_b     (input[7:0]i);      add_r_rm_b      = (i[7:0]==8'b00000010);                    endfunction
function add_rm_r_w     (input[7:0]i);      add_rm_r_w      = (i[7:0]==8'b00000001);                    endfunction
function add_r_rm_w     (input[7:0]i);      add_r_rm_w      = (i[7:0]==8'b00000011);                    endfunction
function add_rm_i_b     (input[7:0]i1,i2);  add_rm_i_b      = (i1[7:0]==8'b10000000&i2[5:3]==3'b000);   endfunction
function add_rm_zi_w    (input[7:0]i1,i2);  add_rm_zi_w     = (i1[7:0]==8'b10000001&i2[5:3]==3'b000);   endfunction
function add_rm_si_w    (input[7:0]i1,i2);  add_rm_si_w     = (i1[7:0]==8'b10000011&i2[5:3]==3'b000);   endfunction
function add_a_i_b      (input[7:0]i);      add_a_i_b       = (i[7:0]==8'b00010100);                    endfunction
function add_a_i_w      (input[7:0]i);      add_a_i_w       = (i[7:0]==8'b00010101);                    endfunction
// ADC
function adc_rm_r_b     (input[7:0]i);      adc_rm_r_b      = (i[7:0]==8'b00010000);                    endfunction
function adc_r_rm_b     (input[7:0]i);      adc_r_rm_b      = (i[7:0]==8'b00010010);                    endfunction
function adc_rm_r_w     (input[7:0]i);      adc_rm_r_w      = (i[7:0]==8'b00010001);                    endfunction
function adc_r_rm_w     (input[7:0]i);      adc_r_rm_w      = (i[7:0]==8'b00010011);                    endfunction
function adc_rm_i_b     (input[7:0]i1,i2);  adc_rm_i_b      = (i[7:0]==8'b10000000&i2[5:3]==3'b010);    endfunction
function adc_rm_zi_w    (input[7:0]i1,i2);  adc_rm_zi_w     = (i[7:0]==8'b10000001&i2[5:3]==3'b010);    endfunction
function adc_rm_si_w    (input[7:0]i1,i2);  adc_rm_si_w     = (i[7:0]==8'b10000011&i2[5:3]==3'b010);    endfunction
function adc_a_i_b      (input[7:0]i);      adc_a_i_b       = (i[7:0]==8'b00010100);                    endfunction
function adc_a_i_w      (input[7:0]i);      adc_a_i_w       = (i[7:0]==8'b00010101);                    endfunction
// INC
function inc_rm_b       (input[7:0]i1,i2)   inc_rm_b        = (i1[7:0]==8'b11111110&i2[5:3]==3'b000);   endfunction
function inc_rm_w       (input[7:0]i1,i2)   inc_rm_w        = (i1[7:0]==8'b11111111&i2[5:3]==3'b000);   endfunction
function inc_r          (input[7:0]i)       inc_r           = (i[7:3]==5'b01000);                       endfunction
// AAA
function aaa            (input[7:0]i)       aaa             = (i[7:0]==8'b00110111);                    endfunction
// DAA
function daa            (input[7:0]i)       daa             = (i[7:0]==8'b00100111);                    endfunction
// SUB
function sub_rm_r_b     (input[7:0]i);      sub_rm_r_b      = (i[7:0]==8'b00101000);                    endfunction
function sub_r_rm_b     (input[7:0]i);      sub_r_rm_b      = (i[7:0]==8'b00101010);                    endfunction
function sub_rm_r_w     (input[7:0]i);      sub_rm_r_w      = (i[7:0]==8'b00101001);                    endfunction
function sub_r_rm_w     (input[7:0]i);      sub_r_rm_w      = (i[7:0]==8'b00101011);                    endfunction
function sub_rm_i_b     (input[7:0]i1,i2);  sub_rm_i_b      = (i1[7:0]==8'b10000000&i2[5:3]==3'b101);   endfunction
function sub_rm_zi_w    (input[7:0]i1,i2);  sub_rm_zi_w     = (i1[7:0]==8'b10000001&i2[5:3]==3'b101);   endfunction
function sub_rm_si_w    (input[7:0]i1,i2);  sub_rm_si_w     = (i1[7:0]==8'b10000011&i2[5:3]==3'b101);   endfunction
function sub_a_i_b      (input[7:0]i);      sub_a_i_b       = (i[7:0]==8'b00101100);                    endfunction
function sub_a_i_w      (input[7:0]i);      sub_a_i_w       = (i[7:0]==8'b00101101);                    endfunction
// SBB
function sbb_rm_r_b     (input[7:0]i);      sbb_rm_r_b      = (i[7:0]==8'b00011000);                    endfunction
function sbb_r_rm_b     (input[7:0]i);      sbb_r_rm_b      = (i[7:0]==8'b00011010);                    endfunction
function sbb_rm_r_w     (input[7:0]i);      sbb_rm_r_w      = (i[7:0]==8'b00011001);                    endfunction
function sbb_r_rm_w     (input[7:0]i);      sbb_r_rm_w      = (i[7:0]==8'b00011011);                    endfunction
function sbb_rm_i_b     (input[7:0]i1,i2);  sbb_rm_i_b      = (i1[7:0]==8'b10000000&i2[5:3]==3'b011);   endfunction
function sbb_rm_zi_w    (input[7:0]i1,i2);  sbb_rm_zi_w     = (i1[7:0]==8'b10000001&i2[5:3]==3'b011);   endfunction
function sbb_rm_si_w    (input[7:0]i1,i2);  sbb_rm_si_w     = (i1[7:0]==8'b10000011&i2[5:3]==3'b011);   endfunction
function sbb_a_i_b      (input[7:0]i);      sbb_a_i_b       = (i[7:0]==8'b00011100);                    endfunction
function sbb_a_i_w      (input[7:0]i);      sbb_a_i_w       = (i[7:0]==8'b00011101);                    endfunction
// DEC
function dec_rm_b       (input[7:0]i1,i2)   dec_rm_b        = (i1[7:0]==8'b11111110&i2[5:3]==3'b001);   endfunction
function dec_rm_w       (input[7:0]i1,i2)   dec_rm_w        = (i1[7:0]==8'b11111111&i2[5:3]==3'b001);   endfunction
function dec_r          (input[7:0]i)       dec_r           = (i[7:3]==5'b01001);                       endfunction

function length1 (input [7:0] i);
    length1 = push_r(i)|push_sr(i)|pop_r(i)|pop_sr(i)|xchg_a_r(i)|xlat(i)|lahf(i)|sahf(i)|pushf(i)|popf(i)|inc_r(i)|aaa(i)|daa(i);
endfunction

function length2 (input [7:0] i1, input [7:0] i2);
    length2 = mov_rm_r_b(i1)&disp0(i2)|mov_r_rm_b(i1)&disp0(i2)|mov_rm_r_w(i1)&disp0(i2)|mov_r_rm_w(i1)&disp0(i2)|mov_r_i_b(i1)|mov_sr_rm(i1)&disp0(i2)|mov_rm_sr(i1)&disp0(i2)|
              push_rm(i1)&disp0(i2)|pop_rm(i1)&disp0(i2)|xchg_r_rm_b(i1)&disp0(i2)|xchg_r_rm_w(i1)&disp0(i2)|
              lea(i1)&disp0(i2)|lds(i1)&disp0(i2)|les(i1)&disp0(i2)|
              add_rm_r_b(i1)&disp0(i2)|add_r_rm_b(i1)&disp0(i2)|add_rm_r_w(i1)&disp0(i2)|add_r_rm_w(i1)&disp0(i2)|add_a_i_b(i1)|
              adc_rm_r_b(i1)&disp0(i2)|adc_r_rm_b(i1)&disp0(i2)|adc_rm_r_w(i1)&disp0(i2)|adc_r_rm_w(i1)&disp0(i2)|adc_a_i_b(i1)|
              inc_rm_b(i1,i2)&disp0(i2)|inc_rm_w(i1,i2)&disp0(i2);
endfunction

function length3 (input [7:0] i1, input [7:0] i2);
    length3 = mov_rm_r_b(i1)&disp1(i2)|mov_r_rm_b(i1)&disp1(i2)|mov_rm_r_w(i1)&disp1(i2)|mov_r_rm_w(i1)&disp1(i2)|mov_rm_i_b(i1)&disp0(i2)|mov_r_i_w(i1)|mov_a_m_b(i1)|mov_a_m_w(i1)|mov_m_a_b(i1)|mov_m_a_w(i1)|mov_sr_rm(i1)&disp1(i2)|mov_rm_sr(i1)&disp1(i2)|
              push_rm(i1)&disp1(i2)|pop_rm(i1)&disp1(i2)|xchg_r_rm_b(i1)&disp1(i2)|xchg_r_rm_w(i1)&disp1(i2)|
              lea(i1)&disp1(i2)|lds(i1)&disp1(i2)|les(i1)&disp1(i2)|
              add_rm_r_b(i1)&disp1(i2)|add_r_rm_b(i1)&disp1(i2)|add_rm_r_w(i1)&disp1(i2)|add_r_rm_w(i1)&disp1(i2)|add_rm_i_b(i1,i2)&disp0(i2)|add_rm_si_w(i1,i2)&disp0(i2)|add_a_i_w(i1)|
              adc_rm_r_b(i1)&disp1(i2)|adc_r_rm_b(i1)&disp1(i2)|adc_rm_r_w(i1)&disp1(i2)|adc_r_rm_w(i1)&disp1(i2)|adc_rm_i_b(i1,i2)&disp0(i2)|adc_rm_si_w(i1,i2)&disp0(i2)|adc_a_i_w(i1)|
              inc_rm_b(i1,i2)&disp1(i2)|inc_rm_w(i1,i2)&disp1(i2);
endfunction

function length4 (input [7:0] i1, input [7:0] i2);
    length4 = mov_rm_r_b(i1)&disp2(i2)|mov_r_rm_b(i1)&disp2(i2)|mov_rm_r_w(i1)&disp2(i2)|mov_r_rm_w(i1)&disp2(i2)|mov_rm_i_b(i1)&disp1(i2)|mov_rm_i_w(i1)&disp0(i2)|mov_sr_rm(i1)&disp2(i2)|mov_rm_sr(i1)&disp2(i2)|
              push_rm(i1)&disp2(i2)|pop_rm(i1)&disp2(i2)|xchg_r_rm_b(i1)&disp2(i2)|xchg_r_rm_w(i1)&disp2(i2)|
              lea(i1)&disp2(i2)|lds(i1)&disp2(i2)|les(i1)&disp2(i2)|
              add_rm_r_b(i1)&disp2(i2)|add_r_rm_b(i1)&disp2(i2)|add_rm_r_w(i1)&disp2(i2)|add_r_rm_w(i1)&disp2(i2)|add_rm_i_b(i1,i2)&disp1(i2)|add_rm_si_w(i1,i2)&disp1(i2)|add_rm_zi_w(i1,i2)&disp0(i2)|
              adc_rm_r_b(i1)&disp2(i2)|adc_r_rm_b(i1)&disp2(i2)|adc_rm_r_w(i1)&disp2(i2)|adc_r_rm_w(i1)&disp2(i2)|adc_rm_i_b(i1,i2)&disp1(i2)|adc_rm_si_w(i1,i2)&disp1(i2)|adc_rm_zi_w(i1,i2)&disp0(i2)|
              inc_rm_b(i1,i2)&disp2(i2)|inc_rm_w(i1,i2)&disp2(i2);
endfunction

function length5 (input [7:0] i1, input [7:0] i2);
    length5 = mov_rm_i_b(i1)&disp2(i2)|mov_rm_i_w(i1)&disp1(i2)|
              add_rm_i_b(i1,i2)&disp2(i2)|add_rm_si_w(i1,i2)&disp2(i2)|add_rm_zi_w(i1,i2)&disp1(i2)|
              adc_rm_i_b(i1,i2)&disp2(i2)|adc_rm_si_w(i1,i2)&disp2(i2)|adc_rm_zi_w(i1,i2)&disp1(i2);
endfunction

function length6 (input [7:0] i1, input [7:0] i2);
    length6 = mov_rm_i_w(i1)&disp2(i2)|add_rm_zi_w(i1,i2)&disp2(i2)|adc_rm_zi_w(i1,i2)&disp2(i2);
endfunction

function disp0 (input [7:0] i2);
    disp0 = ((i2[7:6] == 2'b00) && (i2[2:0] != 3'b110)) || (i2[7:6] == 2'b11);
endfunction

function disp1 (input [7:0] i2);
    disp1 = i2[7:6] == 2'b01;
endfunction

function disp2 (input [7:0] i2);
    disp2 = ((i2[7:6] == 2'b00) && (i2[2:0] == 3'b110)) || (i2[7:6] == 2'b10);
endfunction

function [1:0] field_mod (input [7:0] i);
    field_mod = i[7:6];
endfunction

function [2:0] field_reg (input [7:0] i);
    field_reg = i[5:3];
endfunction

function [2:0] field_r_m (input [7:0] i);
    field_reg = i[2:0];
endfunction

function is_mem_mod (input [7:0] i);
    is_mem_mod = i[7:6] != 2'b11;
endfunction

function is_reg_mod (input [7:0] i);
    is_reg_mod = i[7:6] == 2'b11;
endfunction

function [6:0] reg_b (input [2:0] a);
    reg_b = {1'b0, a[1:0], a[2], 3'b0};
endfunction

function [6:0] reg_w (input [2:0] a);
    reg_w = {a[2:0], 4'b0};
endfunction

function of_b (input [7:0] a,b,r);
    of_b = (~a[7]&~b[7]&r[7]) || (a[7]&b[7]&~r[7]);
endfunction

function of_w (input [15:0] a,b,r);
    of_w = (~a[15]&~b[15]&r[15]) || (a[15]&b[15]&~r[15]);
endfunction

function sf_b (input [7:0] r);
    sf_b = r[7];
endfunction

function sf_w (input [15:0] r);
    sf_w = r[15];
endfunction

function zf_b (input [7:0] r);
    zf_b = r == 8'b0;
endfunction

function zf_w (input [15:0] r);
    zf_w = r == 16'b0;
endfunction

function af_b (input [7:0] a,b,c; reg [3:0] r);
    {af_b, r} = a[3:0] + b[3:0] + c;
endfunction

function af_w (input [15:0] a,b,c; reg [3:0] r);
    {af_w, r} = a[3:0] + b[3:0] + c;
endfunction

function pf_b (input [7:0] r);
    pf_b = ~(^r);
endfunction

function pf_w (input [15:0] r);
    pf_w = ~(^r);
endfunction

function cf_b (input [7:0] a,b,c; reg [7:0] r);
    {cf_b, r} = a + b + c;
endfunction

function cf_w (input [15:0] a,b,c; reg [15:0] r);
    {cf_w, r} = a + b + c;
endfunction



// TODO: MUL FUNC
function [15:0] fmul (input [7:0] a, b); fmul = a * b; endfunction
// TODO: DIV FUNC
function [15:0] fdiv (input [7:0] a, b); fdiv = {a % b, a / b}; endfunction