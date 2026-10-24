// HVL top: binds each kit transactor to its VIP agent with the register
// macros, publishes fwvip-core's clock and reset providers, and runs the
// test.
`include "uvm_macros.svh"
`include "fwvip_uart_macros.svh"

module fwvip_uart_hvl_top;
    import uvm_pkg::*;
    import fwvip_core_uvm_pkg::*;
    import fwvip_uart_pkg::*;
    import fwvip_uart_b2b_env_pkg::*;
    import fwvip_uart_b2b_tests_pkg::*;

    fwvip_uart_hdl_top hdl();

    initial begin
        `fwvip_uart_tx_register(hdl.u_tx.u_if, "uvm_test_top.m_env.m_tx*")
        `fwvip_uart_rx_register(hdl.u_rx.u_if, "uvm_test_top.m_env.m_rx*")
        `fwvip_uart_mon_register(hdl.u_mon.u_if, "uvm_test_top.m_env.m_mon*", 1'b1)
        fwvip_clock_config_p #(virtual fwvip_clock_xtor_if)::set(
            null, "uvm_test_top.m_env*", "clock", hdl.u_clk_if);
        fwvip_reset_config_p #(virtual fwvip_reset_xtor_if #(1))::set(
            null, "uvm_test_top.m_env*", "reset", hdl.u_rst_if);
        run_test();
    end
endmodule
