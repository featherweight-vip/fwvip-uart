// Register macros: bind a kit transactor's `u_if` to a VIP agent through
// the config DB, from an HVL top. `inst` is the agent's path glob.
//
//   `fwvip_uart_tx_register(hdl.u_tx.u_if, "uvm_test_top.m_env.m_tx*")
//   `fwvip_uart_rx_register(hdl.u_rx.u_if, "uvm_test_top.m_env.m_rx*")
//   `fwvip_uart_mon_register(hdl.u_mon.u_if, "uvm_test_top.m_env.m_mon*", 1'b1)
//
// The monitor's last argument is the line it taps: 1 = a transmit line, 0 =
// a receive line (uart_monitor_if is_tx).

`define fwvip_uart_tx_register(vif, inst) \
    void'(fwvip_uart_pkg::fwvip_uart_tx_config_p #(virtual uart_tx_xtor_if)::set(null, inst, "cfg", vif));

`define fwvip_uart_rx_register(vif, inst) \
    void'(fwvip_uart_pkg::fwvip_uart_rx_config_p #(virtual uart_rx_xtor_if)::set(null, inst, "cfg", vif));

`define fwvip_uart_mon_register(vif, inst, is_tx) \
    void'(fwvip_uart_pkg::fwvip_uart_mon_config_p #(virtual uart_monitor_xtor_if)::set(null, inst, "cfg", vif, is_tx));
