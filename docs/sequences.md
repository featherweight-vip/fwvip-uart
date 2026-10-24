# Items and sequences

## `fwvip_uart_cfg_item`: the line configuration

The arguments of the kit's `uart_config_if`: `divisor`, `word_bits` (5..8),
`parity_en`, `parity_even`, `parity_stick`, `stop_bits`. Defaults are the
kit transactors' reset configuration: divisor 16, 8N1. `set(...)` sets them
all in one call; `randomize()` gives a legal framing with a soft divisor of
1..4. `convert2string()` prints `8E1/2` (word bits, parity N/O/E/M/S, stop
bits, divisor). Helpers: `bit_clocks()`, `char_clocks()`, `mask()`,
`parity(data)`.

## `fwvip_uart_char`: one op on the line

| `op` | Fields | What goes on the line |
|---|---|---|
| `FWVIP_UART_CHAR` | `data` | one frame |
| `FWVIP_UART_ERR` | `data`, `bad_parity`, `bad_stop`, `baud_ppm`, `glitch_at`, `glitch_len` | one frame with errors (the kit's `send_err`) |
| `FWVIP_UART_BREAK` | `n_chars` | a break of `n_chars` character times |
| `FWVIP_UART_GLITCH` | `glitch_len` | a pulse of space, `glitch_len` clocks, on the idle line |
| `FWVIP_UART_IDLE` | `n_bits` | mark for `n_bits` bit times after everything before it |
| `FWVIP_UART_CFG` | `cfg` | reconfigure the tx side and its peers once the line is idle |

After the driver runs an item, it holds the predicted reception: `rx_n`
(0 or 1 characters), `rx_data`, `rx_status` ({OE, BI, FE, PE}), or
`rx_known` = 0. It also holds `t_start`/`t_end` (simulation time) and
`t_bits` (`t_end` in bit times). The rx and monitor agents publish the same
class, with `op` CHAR and `data`/`status` as received.

### The reception model

`predict()` models a receiver like the kit's (and a 16550's): one sample
at the middle of each bit, timed from the start edge; only the first stop
bit is checked; a start bit that is mark again at its middle is a glitch.

- A glitch counts if it covers a quarter bit either side of a sample point,
  and does not count if it misses that window. Anything in between is
  `rx_known = 0`.
- A baud offset is clean while every sample point stays more than 15% of a
  bit from the edges of the sent bit. Past that, `rx_known = 0`.
- A frame that samples as space throughout is a break: data 0, BI alone.

## Sequences

All run on the tx agent's sequencer and extend `fwvip_uart_tx_seq_base`,
which has one helper per op: `send`, `send_err`, `send_break`, `glitch`,
`idle`, `reconfigure`, and `line()` (the framing in force).

| Sequence | Knobs | Does |
|---|---|---|
| `fwvip_uart_rand_seq` | `n_chars`, `burst_min`/`burst_max`, `gap_min`/`gap_max` (character times) | bursts of random characters with idle gaps. The default gap of 0..8 characters straddles a 16550's four-character RX timeout |
| `fwvip_uart_err_seq` | `n_errs`, `en_parity`, `en_stop`, `en_baud`, `en_glitch`, `baud_ppm_min`/`max` | error frames, each followed by a clean one: bad parity, bad stop, baud offset (default ±2..3%, clean), a half-bit glitch across one data bit |

## The driver's idle estimate

The kit's tx API has no "line idle" event: `send()` returns when the
character is queued. The driver estimates when the last frame ends (a
queued frame starts when the one before it ends) and IDLE and CFG wait for
that plus one bit. A reconfiguration therefore never lands in the middle
of a frame on the line.
