# Integration

## Packages and exports

Fetch with ivpm `dep-set: use`: that brings fw-hdl, `fw-proto-uart` (the
kit) and `fwvip-core`. In `flow.yaml`, import `org.fwvip.uart` and depend on:

| Export | For |
|---|---|
| `org.fwvip.uart.vip-uvm-hvlsrc` | `fwvip_uart_pkg` (pulls in `fw.proto.uart.class`, the kit's transactors and bridges, and `org.fwvip.core.core-uvm-pkg`) |
| `org.fwvip.uart.xtor-pkg` | `fwvip_uart_xtor_pkg` alone: `OVERSAMPLE`, the status bits |
| `org.fwvip.core.clock-reset-xtor` | the clock and reset providers the agents use |

## The agents

| Role | Agent | Config ("cfg" in the config DB) | Shape |
|---|---|---|---|
| Transmit | `fwvip_uart_tx_agent` | `fwvip_uart_tx_config`: the kit's `uart_tx_if`, `uart_tx_inject_if` and `uart_config_if` | active: `fwvip_uart_char` items on `m_seqr`; `ap` publishes each item once it has run, with the predicted reception |
| Receive | `fwvip_uart_rx_agent` | `fwvip_uart_rx_config`: the kit's `uart_rx_if` sink and `uart_config_if` | `ap` publishes each character; `get()` hands them out in order |
| Monitor | `fwvip_uart_mon_agent` | `fwvip_uart_mon_config`: the kit's `uart_monitor_if` and `uart_config_if` | passive: `ap` publishes each character; status bits outside `allow` are `UART_MON` errors |

The tx agent also needs fwvip-core's clock provider under "clock"; the rx
and monitor agents use it if it is there, for timestamps in bit times.

## HDL top

Instance the kit's wrappers on your lines. A 16550-style DUT has two: the
VIP's tx drives the DUT's serial input, and the VIP's rx listens to the
DUT's serial output. Put a monitor on each.

```systemverilog
uart_tx_xtor      u_tx     (.clock, .reset, .txd(dut_srx));
uart_rx_xtor      u_rx     (.clock, .reset, .rxd(dut_stx));
uart_monitor_xtor u_mon_tx (.clock, .reset, .line(dut_stx));   // DUT -> VIP
uart_monitor_xtor u_mon_rx (.clock, .reset, .line(dut_srx));   // VIP -> DUT
```

The kit's transactors run their own baud divider from `clock`, so a bit is
`16 * divisor` clocks of the transactor's clock. Clock them so that matches
the DUT's bit time (with the same clock, use the same divisor).

## HVL top

```systemverilog
`include "fwvip_uart_macros.svh"

initial begin
    `fwvip_uart_tx_register(hdl.u_tx.u_if, "uvm_test_top.m_env.m_tx*")
    `fwvip_uart_rx_register(hdl.u_rx.u_if, "uvm_test_top.m_env.m_rx*")
    `fwvip_uart_mon_register(hdl.u_mon_tx.u_if, "uvm_test_top.m_env.m_mon_tx*", 1'b1)
    `fwvip_uart_mon_register(hdl.u_mon_rx.u_if, "uvm_test_top.m_env.m_mon_rx*", 1'b0)
    fwvip_clock_config_p #(virtual fwvip_clock_xtor_if)::set(
        null, "uvm_test_top.m_env*", "clock", hdl.u_clk_if);
    run_test();
end
```

## Configuring the line

Every role on a link must be configured alike. The tx config's `peers` are
the roles a CFG item reconfigures along with the tx side; add them in the
env's `connect_phase`:

```systemverilog
m_tx.add_peer(m_mon_rx.m_cfg);   // monitors the line the VIP drives
```

Against a DUT, the DUT's side is configured by register writes, not by the
VIP. A test reconfigures the DUT and the VIP's roles together, at a moment
when both lines are idle: run a CFG item for the tx side and its peers,
and `configure()` the rx agent's and the other monitor's configs directly.

## Checking a DUT

The tx agent's `ap` carries, for every item, what a receiver configured
alike should report (`rx_n`, `rx_data`, `rx_status`; `rx_known` = 0 when
the model cannot tell). Use it as the expected stream for the DUT's receive
path. The rx agent's `ap` (or `get()`) gives what the DUT transmitted.

A test that provokes line errors sets the monitor's `allow_status()` to the
bits it expects, or the monitor reports them as errors.
