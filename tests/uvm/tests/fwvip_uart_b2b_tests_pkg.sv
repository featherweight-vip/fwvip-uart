// The back-to-back cases (one sequence per case, chosen by +SEQ) and tests.
`include "uvm_macros.svh"

package fwvip_uart_b2b_tests_pkg;
    import uvm_pkg::*;
    import fw_proto_uart_pkg::*;
    import fwvip_uart_xtor_pkg::*;
    import fwvip_uart_pkg::*;
    import fwvip_uart_b2b_env_pkg::*;

    `include "fwvip_uart_b2b_seq_base.svh"
    `include "fwvip_uart_smoke_seq.svh"
    `include "fwvip_uart_rand_traffic_seq.svh"
    `include "fwvip_uart_cfg_sweep_seq.svh"
    `include "fwvip_uart_break_seq.svh"
    `include "fwvip_uart_errors_seq.svh"
    `include "fwvip_uart_baud_offset_seq.svh"
    `include "fwvip_uart_glitch_seq.svh"
    `include "fwvip_uart_mon_teeth_seq.svh"

    `include "fwvip_uart_b2b_test.svh"
endpackage
