// fwvip_uart_pkg -- the UART VIP's UVM layer (design.md §3). Agents bind to
// the kit's transactors through their configs:
//   fwvip_uart_tx_agent   fwvip_uart_char items -> uart_tx_if, uart_tx_inject_if
//   fwvip_uart_rx_agent   uart_rx_if sink -> fwvip_uart_char, published and kept
//   fwvip_uart_mon_agent  passive: uart_monitor_if -> fwvip_uart_char, checked
// Thin package: imports, then one class per .svh in dependency order.
`include "uvm_macros.svh"
`include "fwvip_uart_macros.svh"

package fwvip_uart_pkg;
    import uvm_pkg::*;
    import fw_proto_uart_pkg::*;
    import fwvip_core_pkg::*;
    import fwvip_core_uvm_pkg::*;
    import fwvip_uart_xtor_pkg::*;

    `include "fwvip_uart_cfg_item.svh"
    `include "fwvip_uart_char.svh"

    // ---- transmit
    `include "fwvip_uart_tx_config.svh"
    `include "fwvip_uart_tx_sequencer.svh"
    `include "fwvip_uart_tx_driver.svh"
    `include "fwvip_uart_tx_agent.svh"
    `include "fwvip_uart_tx_seq_base.svh"
    `include "fwvip_uart_rand_seq.svh"
    `include "fwvip_uart_err_seq.svh"

    // ---- receive
    `include "fwvip_uart_rx_config.svh"
    `include "fwvip_uart_rx_agent.svh"

    // ---- monitor
    `include "fwvip_uart_mon_config.svh"
    `include "fwvip_uart_mon_agent.svh"
endpackage
