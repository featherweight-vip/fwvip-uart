// The back-to-back bench's UVM side: the env (the VIP's three agents on one
// link) and the scoreboard.
`include "uvm_macros.svh"

package fwvip_uart_b2b_env_pkg;
    import uvm_pkg::*;
    import fw_proto_uart_pkg::*;
    import fwvip_core_pkg::*;
    import fwvip_core_uvm_pkg::*;
    import fwvip_uart_xtor_pkg::*;
    import fwvip_uart_pkg::*;

    `uvm_analysis_imp_decl(_tx)
    `uvm_analysis_imp_decl(_rx)
    `uvm_analysis_imp_decl(_mon)

    `include "fwvip_uart_b2b_sb.svh"
    `include "fwvip_uart_b2b_env.svh"
endpackage
