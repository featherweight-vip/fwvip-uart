// The tx agent's seam: the kit's transmit, error-injection and
// configuration APIs (uart_tx_if, uart_tx_inject_if, uart_config_if). The
// agent depends only on this abstract config; the bench sets the vif-aware
// specialization in the config DB under "cfg", usually with
// `fwvip_uart_tx_register.
//
// `line` is the framing last configured. `peers` are the other roles on the
// same link (the rx agent's and monitor agents' configs, or a DUT model's);
// configure_line() sets the tx side and every peer alike, which is how a CFG
// item reconfigures a whole link.
class fwvip_uart_tx_config extends uvm_object
        implements uart_tx_if, uart_tx_inject_if, uart_config_if;
    `uvm_object_utils(fwvip_uart_tx_config)

    fwvip_uart_cfg_item  line;
    uart_config_if       peers[$];

    function new(string name = "fwvip_uart_tx_config");
        super.new(name);
        line = fwvip_uart_cfg_item::type_id::create("line");
    endfunction

    // Configure the tx side and every peer to `c`. The caller makes sure the
    // line is idle (the tx driver's CFG op waits for it).
    task configure_line(fwvip_uart_cfg_item c);
        c.apply(this);
        foreach (peers[i]) c.apply(peers[i]);
    endtask

    virtual task configure(input bit [15:0] divisor, input bit [3:0] word_bits,
                           input bit parity_en, input bit parity_even,
                           input bit parity_stick, input bit [1:0] stop_bits);
        void'(line.set(divisor, word_bits, parity_en, parity_even, parity_stick, stop_bits));
        xtor_configure(divisor, word_bits, parity_en, parity_even, parity_stick, stop_bits);
    endtask

    protected virtual task xtor_configure(input bit [15:0] divisor, input bit [3:0] word_bits,
                                          input bit parity_en, input bit parity_even,
                                          input bit parity_stick, input bit [1:0] stop_bits);
        `uvm_fatal("FWVIP_UART", "fwvip_uart_tx_config: no transactor bound (set a fwvip_uart_tx_config_p)")
    endtask

    virtual task send(input bit [7:0] data);
        `uvm_fatal("FWVIP_UART", "fwvip_uart_tx_config: no transactor bound (set a fwvip_uart_tx_config_p)")
    endtask

    virtual task set_break(input bit on);
        `uvm_fatal("FWVIP_UART", "fwvip_uart_tx_config: no transactor bound (set a fwvip_uart_tx_config_p)")
    endtask

    virtual task send_break(input int unsigned n_chars);
        `uvm_fatal("FWVIP_UART", "fwvip_uart_tx_config: no transactor bound (set a fwvip_uart_tx_config_p)")
    endtask

    virtual task send_err(input bit [7:0] data, input bit bad_parity, input bit bad_stop,
                          input int baud_ppm, input int unsigned glitch_at,
                          input int unsigned glitch_len);
        `uvm_fatal("FWVIP_UART", "fwvip_uart_tx_config: no transactor bound (set a fwvip_uart_tx_config_p)")
    endtask

    virtual task glitch(input int unsigned glitch_len);
        `uvm_fatal("FWVIP_UART", "fwvip_uart_tx_config: no transactor bound (set a fwvip_uart_tx_config_p)")
    endtask
endclass

// vif-aware specialization: holds the kit tx transactor's `u_if` and
// forwards the APIs to a kit uart_tx_xtor_bridge, built on first use so it
// works whatever the call order is relative to phasing.
class fwvip_uart_tx_config_p #(type vif_t = virtual uart_tx_xtor_if)
        extends fwvip_uart_tx_config;
    typedef fwvip_uart_tx_config_p #(vif_t) this_t;

    vif_t                vif;
    uart_tx_xtor_bridge  m_bridge;

    function new(string name = "fwvip_uart_tx_config_p");
        super.new(name);
    endfunction

    static function this_t set(uvm_component ctxt, string inst, string field, vif_t vif);
        this_t cfg = new();
        cfg.vif = vif;
        uvm_config_db #(fwvip_uart_tx_config)::set(ctxt, inst, field, cfg);
        return cfg;
    endfunction

    protected function void ensure();
        if (m_bridge == null) m_bridge = new(vif);
    endfunction

    protected virtual task xtor_configure(input bit [15:0] divisor, input bit [3:0] word_bits,
                                          input bit parity_en, input bit parity_even,
                                          input bit parity_stick, input bit [1:0] stop_bits);
        ensure();
        m_bridge.configure(divisor, word_bits, parity_en, parity_even, parity_stick, stop_bits);
    endtask

    virtual task send(input bit [7:0] data);
        ensure();
        m_bridge.send(data);
    endtask

    virtual task set_break(input bit on);
        ensure();
        m_bridge.set_break(on);
    endtask

    virtual task send_break(input int unsigned n_chars);
        ensure();
        m_bridge.send_break(n_chars);
    endtask

    virtual task send_err(input bit [7:0] data, input bit bad_parity, input bit bad_stop,
                          input int baud_ppm, input int unsigned glitch_at,
                          input int unsigned glitch_len);
        ensure();
        m_bridge.send_err(data, bad_parity, bad_stop, baud_ppm, glitch_at, glitch_len);
    endtask

    virtual task glitch(input int unsigned glitch_len);
        ensure();
        m_bridge.glitch(glitch_len);
    endtask
endclass
