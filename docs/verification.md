# Verification

## The bench

`tests/uvm/`: the VIP's tx agent drives the kit's tx transactor onto one
line; the kit's rx transactor and monitor transactor sit on it, under the
VIP's rx and monitor agents. The scoreboard (`fwvip_uart_b2b_sb`) checks
every character the rx agent and the monitor agent report against the tx
agent's prediction, in order, data and status. It is an error for the bench
to send a frame the model cannot predict.

## Cases

| Case | Checks |
|---|---|
| `smoke` | 8N1/2: a burst back to back, gaps; `get()` hands the characters back in order |
| `rand_traffic` | 200 characters in bursts and gaps at a random framing |
| `cfg_sweep` | all 40 framings (5..8 bits × N/O/E/M/S × 1/2 stop), divisors 1..3, the link reconfigured between them |
| `break` | breaks of 1 and 3 characters between characters, at two framings: one BI character each |
| `errors` | 80 error frames over four random framings with parity: PE, FE, a flipped data bit, baud offsets |
| `baud_offset` | ±2..3% at 8E2 and 8O2 and a random framing: all clean |
| `glitch` | idle-line glitches up to a third of a bit (no character), then half-bit glitches across data bits |
| `mon_teeth` | smoke, then a parity error, a framing error and a break with the monitor allowing none: each must be flagged |

`dfm run smoke` runs `smoke` and `mon_teeth` (CI on every push); `dfm run
tests` runs all eight (nightly).

## How the bench was checked

All eight cases pass. The random cases (`rand_traffic`, `errors`,
`baud_offset`, `glitch`) were also run on eight seeds each, all clean. Five
mutations were each caught by the case meant to catch them:

| Mutation | Caught by |
|---|---|
| model: FE never predicted | `errors` (scoreboard mismatch) |
| model: a glitch never flips the bit | `glitch` (scoreboard mismatch) |
| env: the rx agent not a peer of the tx config (not reconfigured) | `cfg_sweep` (scoreboard mismatch) |
| err_seq: baud offset up to 4.5%, past the margin | `baud_offset` (unpredictable frame) |
| monitor: status never checked | `mon_teeth` (not flagged) |
