# fwvip-uart — UART Verification IP

`fwvip-uart` is the UVM Verification IP for an asynchronous serial line
(16550-style framing: 5–8 data bits, none/odd/even/mark/space parity, 1, 1.5
or 2 stop bits, break): the methodology layer over the `fw-proto-uart`
transactor kit (fetched under `packages/`). See {doc}`design` for the design
rationale.

```{admonition} Status
:class: note
tx, rx and monitor agents, a reception model that predicts what a receiver
reports for every frame (including injected errors), and a back-to-back
bench with eight passing cases. Modem-control lines are not part of this
VIP (see {doc}`design` §6).
```

## Where to start

- {doc}`getting-started`: set up, build and run.
- {doc}`integration`: how to wire the agents into a bench.
- {doc}`sequences`: the item, the ops and the sequences.
- {doc}`verification`: what is tested, and how the tests were checked.
- {doc}`design`: architecture and decisions.

```{toctree}
:maxdepth: 2
:hidden:

getting-started
integration
sequences
verification
design
```
