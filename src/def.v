`define AL register[4'd0]
`define AH register[4'd4]
`define CL register[4'd1]
`define CH register[4'd5]
`define DL register[4'd2]
`define DH register[4'd6]
`define BL register[4'd3]
`define BH register[4'd7]
`define AX {`AH, `AL}
`define CX {`CH, `CL}
`define DX {`DH, `DL}
`define BX {`BH, `BL}
`define SP {register[4'd12], register[4'd8 ]}
`define BP {register[4'd13], register[4'd9 ]}
`define SI {register[4'd14], register[4'd10]}
`define DI {register[4'd15], register[4'd11]}
`define ES segment_register[2'b0]
`define CS segment_register[2'b1]
`define SS segment_register[2'b2]
`define DS segment_register[2'b3]



// DATA TRANSFER OPERATIONS
// MOV
function mov_rm_r_b     (input [7:0] i); mov_rm_r_b     = (i[7:0]==8'b10001000); endfunction
function mov_r_rm_b     (input [7:0] i); mov_r_rm_b     = (i[7:0]==8'b10001010); endfunction
function mov_rm_r_w     (input [7:0] i); mov_rm_r_w     = (i[7:0]==8'b10001001); endfunction
function mov_r_rm_w     (input [7:0] i); mov_r_rm_w     = (i[7:0]==8'b10001011); endfunction
function mov_rm_i_b     (input [7:0] i); mov_rm_i_b     = (i[7:0]==8'b11000110); endfunction
function mov_rm_i_w     (input [7:0] i); mov_rm_i_w     = (i[7:0]==8'b11000111); endfunction
function mov_r_i_b      (input [7:0] i); mov_r_i_b      = (i[7:3]==5'b10110   ); endfunction
function mov_r_i_w      (input [7:0] i); mov_r_i_w      = (i[7:3]==5'b10111   ); endfunction
function mov_a_m_b      (input [7:0] i); mov_a_m_b      = (i[7:0]==8'b10100000); endfunction
function mov_a_m_w      (input [7:0] i); mov_a_m_w      = (i[7:0]==8'b10100001); endfunction
function mov_m_a_b      (input [7:0] i); mov_m_a_b      = (i[7:0]==8'b10100010); endfunction
function mov_m_a_w      (input [7:0] i); mov_m_a_w      = (i[7:0]==8'b10100011); endfunction
function mov_sr_rm      (input [7:0] i); mov_sr_rm      = (i[7:0]==8'b10001110); endfunction
function mov_rm_sr      (input [7:0] i); mov_rm_sr      = (i[7:0]==8'b10001100); endfunction
// PUSH
function push_rm        (input [7:0] i); push_rm        = (i[7:0]==8'b11111111); endfunction
function push_r         (input [7:0] i); push_r         = (i[7:3]==5'b01010   ); endfunction
function push_sr        (input [7:0] i); push_sr        = (i&'he7==8'b00000110); endfunction
// POP
function pop_rm         (input [7:0] i); pop_rm         = (i[7:0]==8'b10001111); endfunction
function pop_r          (input [7:0] i); pop_r          = (i[7:3]==5'b01011   ); endfunction
function pop_sr         (input [7:0] i); pop_sr         = (i&'he7==8'b00000111); endfunction
// XCHG
function xchg_r_rm_b    (input [7:0] i); xchg_r_rm_b    = (i[7:0]==8'b10000110); endfunction
function xchg_r_rm_w    (input [7:0] i); xchg_r_rm_w    = (i[7:0]==8'b10000111); endfunction
function xchg_a_r       (input [7:0] i); xchg_a_r       = (i[7:3]==5'b10010   ); endfunction
// XLAT
function xlat           (input [7:0] i); xlat           = (i[7:0]==8'b11010111); endfunction


function length1 (input [7:0] i);
    length1 = push_r(i)|push_sr(i)|pop_r(i)|pop_sr(i)|xchg_a_r(i);
endfunction

function length2 (input [7:0] i1, input [7:0] i2);
    length2 = mov_rm_r_b(i1)&disp0(i2)|mov_r_rm_b(i1)&disp0(i2)|mov_rm_r_w(i1)&disp0(i2)|mov_r_rm_w(i1)&disp0(i2)|mov_r_i_b(i1)|mov_sr_rm(i1)&disp0(i2)|mov_rm_sr(i1)&disp0(i2)|
              push_rm(i1)&disp0(i2)|pop_rm(i1)&disp0(i2)|xchg_r_rm_b(i1)&disp0(i2)|xchg_r_rm_w(i1)&disp0(i2);
endfunction

function length3 (input [7:0] i1, input [7:0] i2);
    length3 = mov_rm_r_b(i1)&disp1(i2)|mov_r_rm_b(i1)&disp1(i2)|mov_rm_r_w(i1)&disp1(i2)|mov_r_rm_w(i1)&disp1(i2)|mov_rm_i_b(i1)&disp0(i2)|mov_r_i_w(i1)|mov_a_m_b(i1)|mov_a_m_w(i1)|mov_m_a_b(i1)|mov_m_a_w(i1)|mov_sr_rm(i1)&disp1(i2)|mov_rm_sr(i1)&disp1(i2)|
              push_rm(i1)&disp1(i2)|pop_rm(i1)&disp1(i2)|xchg_r_rm_b(i1)&disp1(i2)|xchg_r_rm_w(i1)&disp1(i2);
endfunction

function length4 (input [7:0] i1, input [7:0] i2);
    length4 = mov_rm_r_b(i1)&disp2(i2)|mov_r_rm_b(i1)&disp2(i2)|mov_rm_r_w(i1)&disp2(i2)|mov_r_rm_w(i1)&disp2(i2)|mov_rm_i_b(i1)&disp1(i2)|mov_rm_i_w(i1)&disp0(i2)|mov_sr_rm(i1)&disp2(i2)|mov_rm_sr(i1)&disp2(i2)|
              push_rm(i1)&disp2(i2)|pop_rm(i1)&disp2(i2)|xchg_r_rm_b(i1)&disp2(i2)|xchg_r_rm_w(i1)&disp2(i2);
endfunction

function length5 (input [7:0] i1, input [7:0] i2);
    length5 = mov_rm_i_b(i1)&disp2(i2)|mov_rm_i_w(i1)&disp1(i2);
endfunction

function length6 (input [7:0] i1, input [7:0] i2);
    length6 = mov_rm_i_w(i1)&disp2(i2);
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

function [3:0] reg_w_hi (input [2:0] a);
    reg_w_hi = {a[2], 1'b1, a[1:0]};
endfunction

function [3:0] reg_w_lo (input [2:0] a);
    reg_w_lo = {a[2], 1'b0, a[1:0]};
endfunction

// TODO: MUL FUNC
function [15:0] fmul (input [7:0] a, b); fmul = a * b; endfunction
// TODO: DIV FUNC
function [15:0] fdiv (input [7:0] a, b); fdiv = {a % b, a / b}; endfunction