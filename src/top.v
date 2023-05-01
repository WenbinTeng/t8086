module top (
    input           clk,    // clock
    input           rst,    // reset
    input           rdy,    // ready
    input           test,   // test signal
    input           mn,     // mode control
    inout   [15:0]  ad,     // address data bus
    inout   [ 3:0]  as,     // address status bus
    output          ale,    // address latch enable
    output          rd_n,   // read, active LOW
    output          wr_n,   // write, active LOW
    output          m_n,    // access external memory or IO
    output          bhe_n,  // bus high enable, active LOW
    output          den_n,  // data enable
    output          dt,     // data transmit
    input           intr,   // interupt request
    input           nmi,    // non-maskable interrupt request
    output          inta_n, // interupt acknowledge, active LOW
    input           hold,   // hold request
    output          hlda    // hold acknowledge
);
    
endmodule