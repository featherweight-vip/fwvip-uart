// HDL top: one serial link -- the kit's tx transactor driving the line, the
// kit's rx transactor and monitor transactor on it -- plus fwvip-core's
// clock and reset transactor interfaces.
module fwvip_uart_hdl_top;

    reg clock = 0, reset = 1;
    always #5ns clock = ~clock;
    initial begin
        repeat (4) @(posedge clock);
        reset = 0;
    end

    fwvip_clock_xtor_if               u_clk_if (.clock(clock), .reset(reset));
    fwvip_reset_xtor_if #(.ACTIVE(1)) u_rst_if (.clock(clock), .reset(reset));

    wire line;

    uart_tx_xtor      u_tx  (.clock(clock), .reset(reset), .txd(line));
    uart_rx_xtor      u_rx  (.clock(clock), .reset(reset), .rxd(line));
    uart_monitor_xtor u_mon (.clock(clock), .reset(reset), .line(line));

    // +fwvip_uart_line_trace prints every change on the line.
    initial if ($test$plusargs("fwvip_uart_line_trace")) forever begin
        @(line);
        $display("%t LINE %b", $time, line);
    end
endmodule
