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

function length1 (input [7:0] i);
    length1 = 'b0;
endfunction

function length2 (input [7:0] i);
    length2 = 'b0;
endfunction

function length3 (input [7:0] i);
    length3 = 'b0;
endfunction

function length4 (input [7:0] i);
    length4 = 'b0;
endfunction

function length6 (input [7:0] i);
    length6 = 'b0;
endfunction

// TODO: MUL FUNC
function [15:0] fmul (input [7:0] a, b); fmul = a * b; endfunction
// TODO: DIV FUNC
function [15:0] fdiv (input [7:0] a, b); fdiv = {a % b, a / b}; endfunction