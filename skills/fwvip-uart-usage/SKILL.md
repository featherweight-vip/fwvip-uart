---
name: fwvip-uart-usage
description: Connect and drive the fwvip-uart Verification IP — bind its tx, rx and monitor
  agents into a UVM env (register macros + config DB), send characters, breaks, error frames
  and idle gaps, reconfigure a link, and check a DUT against the tx agent's predicted
  reception. Use when integrating fwvip-uart into a testbench or generating UART stimulus
  with it.
tools: Read, Write, Edit, Bash, Grep, Glob
---

# fwvip-uart — usage

The UVM layer over the `fw-proto-uart` transactor kit. Package
`fwvip_uart_pkg`; DFM export `org.fwvip.uart.vip-uvm-hvlsrc` (it pulls in
`fw.proto.uart.class`, the kit's transactors and bridges, and
`org.fwvip.core.core-uvm-pkg`). A bench also needs
`org.fwvip.core.clock-reset-xtor` for the clock provider.

## What it provides

| Role | Agent | Config (config DB "cfg") | Shape |
|---|---|---|---|
| Transmit | `fwvip_uart_tx_agent` | `fwvip_uart_tx_config` (the kit's `uart_tx_if`, `uart_tx_inject_if`, `uart_config_if`) | active: `fwvip_uart_char` items on `m_seqr`; `ap` publishes each with its predicted reception |
| Receive | `fwvip_uart_rx_agent` | `fwvip_uart_rx_config` (the kit's `uart_rx_if` sink) | `ap` publishes each character; `get(t)` returns them in order |
| Monitor | `fwvip_uart_mon_agent` | `fwvip_uart_mon_config` (the kit's `uart_monitor_if`; `is_tx`) | passive: `ap`; status outside `allow` is a `UART_MON` error |

The tx agent needs "clock" (`fwvip_clock_config`) in the config DB too.

## Wiring

```systemverilog
// HDL top: the kit's wrappers on the lines
uart_tx_xtor      u_tx  (.clock, .reset, .txd(dut_srx));
uart_rx_xtor      u_rx  (.clock, .reset, .rxd(dut_stx));
uart_monitor_xtor u_mon (.clock, .reset, .line(dut_stx));

// HVL top
`include "fwvip_uart_macros.svh"
`fwvip_uart_tx_register(hdl.u_tx.u_if, "uvm_test_top.m_env.m_tx*")
`fwvip_uart_rx_register(hdl.u_rx.u_if, "uvm_test_top.m_env.m_rx*")
`fwvip_uart_mon_register(hdl.u_mon.u_if, "uvm_test_top.m_env.m_mon*", 1'b1)  // 1: taps a tx line
fwvip_clock_config_p #(virtual fwvip_clock_xtor_if)::set(null, "uvm_test_top.m_env*", "clock", hdl.u_clk_if);
```

A bit is `16 * divisor` clocks of the transactor's clock.

## Driving

Extend `fwvip_uart_tx_seq_base` and use its helpers, on `m_tx.m_seqr`:

```systemverilog
fwvip_uart_cfg_item c = fwvip_uart_cfg_item::type_id::create("c");
reconfigure(c.set(2, 8, 1, 1));       // 8E1, divisor 2: tx side + peers, once idle
send(8'h41);                          // returns once queued
send_err(8'h42, .bad_parity(1));      // PE
send_err(8'h43, .bad_stop(1));        // FE
send_err(8'h44, .baud_ppm(25000));    // 2.5% slow: clean
send_break(2);                        // one char, data 0, BI
glitch(10);                           // short pulse on idle line: no char
idle(40);                             // 40 bit times of mark after the last frame
```

Library sequences: `fwvip_uart_rand_seq` (bursts and gaps, in character
times), `fwvip_uart_err_seq` (mixed error frames). `line()` gives the
framing in force.

## Configuring a link

All roles on a line need the same framing. `m_tx.add_peer(cfg)` in
`connect_phase` makes a CFG item reconfigure that role too (the rx agent's
or a monitor's config). A DUT is configured by your register sequence. Do
both while the line is idle.

## Checking

Each item on `m_tx.ap` carries `rx_n` (0/1), `rx_data`, `rx_status`
({OE, BI, FE, PE}, `FWVIP_UART_*` in `fwvip_uart_xtor_pkg`), or
`rx_known = 0` (a glitch on a sample window's edge, a baud offset past the
margin). Compare a DUT's received characters against these. Set
`m_mon.allow_status(FWVIP_UART_PE | FWVIP_UART_FE)` in a test that injects
errors.

## Gotchas

- `send()` returns before the frame is on the line. Use `idle(n)` (it waits
  for the frame to end) before you look for the result.
- The rx agent keeps every character for `get()`. If you only use `ap`,
  call `clear()` now and then in long tests.
- Glitch and baud-offset frames are predicted for a mid-bit single-sample
  receiver (the kit's and a 16550's). A majority-vote receiver can differ.
