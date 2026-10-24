# Design

## 1. Goal

A UVM VIP for an asynchronous serial line, built the way `fwvip-i2c` is: a
thin methodology layer over a transactor kit (`fw-proto-uart`), with no
transactors of its own. Its first user is the `ref` view of `fw-uart16550`,
a UVM bench around the freecores 16550, so it must be able to:

- drive every 16550 framing, break, and the line errors a 16550 detects
  (PE, FE, BI), and idle gaps long enough to hit the 16550's RX timeout;
- receive what the DUT transmits, with its status;
- say, for every frame it sends, what a 16550 should report, so a bench can
  check the DUT's receive path without its own model of the line.

## 2. The kit and the VIP

The kit owns everything below the class APIs: the transactor modules and
interfaces, the bridges, the synthesizable cores, and the error injection
(K6, driven from the tx transactor interface, outside the core). The VIP
owns the UVM layer: configs, agents, items, sequences, the reception model
and the bench.

| Kit API | VIP side |
|---|---|
| `uart_tx_if` (`send`, `set_break`, `send_break`) | `fwvip_uart_tx_config` forwards to `uart_tx_xtor_bridge` |
| `uart_tx_inject_if` (`send_err`, `glitch`) | the same |
| `uart_rx_if` (a sink the bridge calls) | `fwvip_uart_rx_config` is the sink |
| `uart_monitor_if` (a subscriber) | `fwvip_uart_mon_config` is the subscriber |
| `uart_config_if` (`configure`) | each config implements it and records the framing in `line` |

Each config is an abstract base (calling it unbound is a fatal) and a
`_p #(vif_t)` specialization that holds the transactor's `u_if` and builds
the bridge on first use. Benches set the specialization in the config DB
with the register macros. This is the `fwvip-i2c` pattern unchanged.

## 3. Agents

**tx.** A sequencer, a driver and an analysis port. The item is
`fwvip_uart_char`, one op on the line (CHAR, ERR, BREAK, GLITCH, IDLE,
CFG). The driver runs each item, predicts its reception, timestamps it and
publishes it. The sequencer holds the config, so a sequence can read the
framing in force.

The kit's tx API returns from `send()` once the character is queued, and
has no "idle" event. The driver keeps an estimate of when the last frame
ends and makes IDLE and CFG wait for it plus a bit. The estimate is exact
for back-to-back frames (the core leaves no gap) and early by at most a
baud tick plus two clocks after an idle line, which the extra bit covers.

**Reconfiguration.** All roles on a link must have the same framing, and a
role samples its configuration at the start of a character. A CFG item
waits for the line to be idle, then configures the tx side and every
*peer*: the `uart_config_if` handles in the tx config's `peers`. The b2b
env adds the rx and monitor configs. A DUT bench adds the monitor on the
line the VIP drives, and configures the DUT through its registers.

**rx.** No sequencer: UART has no response on the wire, so there is
nothing to drive. The config is the bridge's sink. It hands each
character to the agent, which publishes it and keeps it for `get()`. The
sink never blocks, so an OE the agent reports was made on the line, not by
the VIP being slow.

**Monitor.** Publishes each character with `is_tx` (fixed per instance, as
the kit's bridge does) and checks it: a status bit outside `allow` is a
`UART_MON` error. `allow` defaults to 0, so a line error is a test failure
unless the test expects it.

**Time.** The agents measure the clock period from fwvip-core's clock
provider at the start of the run. `t_bits` is a timestamp in bit times at
the framing in force, which is what RX-timeout tests reason in.

## 4. The reception model

`fwvip_uart_char::predict()` says what a receiver configured like the tx
side reports for an item. It models the kit's rx core, which models the
16550's: one sample at the middle of each bit, timed from the start edge,
and only the first stop bit checked. A glitched start bit sends the
receiver back to idle, and an all-space frame is a break (data 0, BI
alone).

The model is exact where the outcome is determined, and says so
(`rx_known = 0`) where it is not:

- a glitch that covers a quarter bit either side of a sample point flips
  that sample; one that misses that window does not count; anything else is
  unknown. The window is wider than the receiver's start-detection lag (up
  to a tick, 1/16 bit), so the rule holds at every divisor;
- a baud offset is clean while every sample point is more than 15% of a
  bit from the edges of the sent bit. Past that, the result is unknown;
- an idle-line glitch longer than 3/8 of a bit is unknown. The receiver
  samples the start bit 7/16 to 8/16 of a bit after it sees the edge.

This is what makes the VIP useful against a DUT: a 16550 bench checks the
DUT's RBR and LSR against `rx_data` and `rx_status`, including injected
errors, without a line model of its own. Where the reference differs from
the kit at the sample point (fw-uart16550 risk "kit rx core vs U4"), the
comparison for glitch and baud-offset tests is under allowed differences,
as the fw-uart16550 plan says.

## 5. The back-to-back bench

One line: the tx agent and its transactor drive it, and the rx agent and
the monitor agent listen. The scoreboard pairs the tx agent's predictions
with the rx agent's characters and, separately, with the monitor's. Eight
cases ({doc}`verification`), one sequence each, chosen by `+SEQ`.

## 6. Not in this VIP

- **Modem-control lines** (RTS, CTS, DTR, DSR, RI, DCD). They are not UART
  framing. fw-uart16550 decision D6 was to reuse fwvip-gpio if its API fits,
  else add a modem agent here. fw-proto-gpio's API fits (`set` to drive the
  modem inputs, a `changed` sink for the outputs). fwvip-gpio itself is
  still on the old template (cocotb dependencies, no `use` dep-set). So
  the fw-uart16550 bench drives the modem pins through fw-proto-gpio
  directly, and this VIP has no modem agent.
- **A pull-style rx API in the kit** (fw-uart16550 K3), a TLM link (K7),
  and loopback (K8). They come with the class model in fw-uart16550 step 7.
  `get()` on the rx agent covers what a UVM test needs.
- **A sampling option** (K5). The model follows the kit's single mid-bit
  sample. If the kit gains 3-sample majority, `predict()` needs a matching
  mode.

## 7. Open issues

1. The driver's idle estimate is an estimate. A kit "tx idle" event
   (`busy` is already on the transactor interface) would make IDLE and CFG
   exact. Add it to the kit with K1 (runtime configure at a character
   boundary) in fw-uart16550 step 7 if a DUT bench needs tighter timing.
2. The rx agent's `get()` queue grows without bound if nothing takes from
   it. A long DUT test that only uses `ap` should call `clear()` now and
   then.
