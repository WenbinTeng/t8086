`define AX register[3'h0]
`define BX register[3'h1]
`define CX register[3'h2]
`define DX register[3'h3]
`define SP register[3'h4]
`define BP register[3'h5]
`define SI register[3'h6]
`define DI register[3'h7]
`define AL register[3'h0][ 7:0]
`define AH register[3'h0][15:8]
`define BL register[3'h1][ 7:0]
`define BH register[3'h1][15:8]
`define CL register[3'h2][ 7:0]
`define CH register[3'h2][15:8]
`define DL register[3'h3][ 7:0]
`define DH register[3'h3][15:8]
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



function length1 (input [7:0] i);
    length1 = 'b0;
endfunction

function length2 (input [7:0] i1, input [7:0] i2);
    length2 = mov_r_i_b(i1)|mov_rm_r_b(i1)&~disp(i2)|mov_r_rm_b(i1)&~disp(i2)|mov_rm_r_w(i1)&~disp(i2)|mov_r_rm_w(i1)&~disp(i2)|mov_sr_rm(i1)&~disp(i2)|mov_rm_sr(i1)&~disp(i2);
endfunction

function length3 (input [7:0] i1, input [7:0] i2);
    length3 = mov_rm_i_b(i1)&~disp(i2)|mov_r_i_w(i1)|mov_a_m_b(i1)|mov_a_m_w(i1)|mov_m_a_b(i1)|mov_m_a_w(i1);
endfunction

function length4 (input [7:0] i1, input [7:0] i2);
    length4 = mov_rm_r_b(i1)&disp(i2)|mov_r_rm_b(i1)&disp(i2)|mov_rm_r_w(i1)&disp(i2)|mov_r_rm_w(i1)&disp(i2)|mov_rm_i_w(i1)&~disp(i2)|mov_sr_rm(i1)&disp(i2)|mov_rm_sr(i1)&disp(i2);
endfunction

function length5 (input [7:0] i1, input [7:0] i2);
    length5 = mov_rm_i_b(i1)&disp(i2);
endfunction

function length6 (input [7:0] i1, input [7:0] i2);
    length6 = mov_rm_i_w(i1)&disp(i2);
endfunction

function disp (input [7:0] i2);
    disp = ((i2[7:6] == 2'b00) && (i2[2:0] != 3'b110)) || (i2[7:6] == 2'b11);
endfunction

// TODO: MUL FUNC
function [15:0] fmul (input [7:0] a, b); fmul = a * b; endfunction
// TODO: DIV FUNC
function [15:0] fdiv (input [7:0] a, b); fdiv = {a % b, a / b}; endfunction