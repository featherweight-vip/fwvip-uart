# fwvip-uart

The UVM Verification IP for an asynchronous serial line (16550-style
framing, break, line errors), built on the `fw-proto-uart` transactor kit
(fetched under `packages/`), in the `fwvip-i2c` layout.

**Status:** tx, rx and monitor agents, a reception model that predicts what
a receiver reports for every frame (injected errors included), and a
back-to-back UVM bench with eight cases, all passing.

```sh
dfm run tests        # every UVM case
dfm run smoke        # what CI runs on every push
dfm run docs         # Sphinx, warnings as errors
```

See [`docs/design.md`](docs/design.md) for the design,
[`skills/fwvip-uart-usage/SKILL.md`](skills/fwvip-uart-usage/SKILL.md) for
how to wire and drive the agents, and [`docs/`](docs/) for the
user-facing documentation.

Setup note: `ivpm update` does not install fw-hdl's dfm plugin. Install it
once with `uv pip install --python packages/python/bin/python -e
packages/fw-hdl/python` (see `ivpm.yaml`).
