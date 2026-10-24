// fwvip_uart_xtor_pkg -- the consumer-side constants every fwvip-<proto> has.
// UART is a fixed 8-bit carrier with the word length set at run time, so
// there are no widths to thread: just the kit's oversampling factor and the
// LSR-aligned status bits the kit's rx and monitor report.
package fwvip_uart_xtor_pkg;

    // Ticks per bit in the kit's transactors (their OVERSAMPLE default). A
    // bit is OVERSAMPLE * divisor clocks.
    localparam int OVERSAMPLE = 16;

    // The status nibble {OE, BI, FE, PE} (uart_rx_if, uart_monitor_if).
    localparam bit [3:0] FWVIP_UART_PE = 4'b0001;
    localparam bit [3:0] FWVIP_UART_FE = 4'b0010;
    localparam bit [3:0] FWVIP_UART_BI = 4'b0100;
    localparam bit [3:0] FWVIP_UART_OE = 4'b1000;

    function automatic string fwvip_uart_status_str(bit [3:0] s);
        string r = "";
        if (s == 0) return "ok";
        if (s & FWVIP_UART_OE) r = {r, "OE "};
        if (s & FWVIP_UART_BI) r = {r, "BI "};
        if (s & FWVIP_UART_FE) r = {r, "FE "};
        if (s & FWVIP_UART_PE) r = {r, "PE "};
        return r.substr(0, r.len() - 2);
    endfunction

endpackage
