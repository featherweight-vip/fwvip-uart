# Getting started

## Set up

```sh
ivpm update                       # fetches the kit, fwvip-core, dv-flow, Verilator
uv pip install --python packages/python/bin/python -e packages/fw-hdl/python
direnv allow
```

fw-hdl's dfm plugin lives in a subdirectory, so `ivpm update` does not
install it; `project.dv.uvm` does not load without it. Install it once.

## Run

```sh
dfm run smoke                     # smoke + mon_teeth: what CI runs on every push
dfm run tests                     # all eight cases (nightly)
dfm run tests --tests errors      # one case
dfm run docs                      # this documentation, warnings as errors
```

Each case's log is `rundir/org.fwvip.uart.bench.uvm-tests.<case>_<n>/sim.log`.
The scoreboard's last line says how many characters it matched:

```
[SB] 160 characters expected; rx matched 160, monitor matched 160; 0 bad
```

## Trace plusargs

| Plusarg | Prints |
|---|---|
| `+fwvip_uart_rx_trace` | every character the rx agent receives |
| `+fwvip_uart_mon_trace` | every character the monitor agent observes |
| `+fwvip_uart_line_trace` | every change on the bench's line (HDL top) |
