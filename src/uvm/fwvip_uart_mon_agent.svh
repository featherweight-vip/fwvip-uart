// Passive agent (design.md §3): publishes every character the kit's monitor
// deframes on a tapped line as a fwvip_uart_char (op CHAR, data, status,
// is_tx) on `ap`, and checks it.
//
// The check: a character whose status has a bit outside `allow` is a
// UVM_ERROR with id UART_MON. `allow` is 0 by default, so a parity error,
// framing error, break or overrun on the line is flagged; a test that
// provokes one on purpose sets the bits it expects (allow_status()). Every
// status bit is counted (n_pe, n_fe, n_bi, n_oe) whether allowed or not.
// Set `check_enable = 0` to publish without checking.
//
// Fetches "cfg" (a fwvip_uart_mon_config) from the config DB, and "clock"
// (fwvip-core's clock provider) if there is one, for t_bits.
// +fwvip_uart_mon_trace prints every character.
class fwvip_uart_mon_agent extends uvm_component;
    `uvm_component_utils(fwvip_uart_mon_agent)

    fwvip_uart_mon_config                 m_cfg;
    fwvip_clock_config                    m_clock;
    uvm_analysis_port #(fwvip_uart_char)  ap;
    bit                                   check_enable = 1;
    bit [3:0]                             allow;
    bit                                   trace;
    int unsigned                          n_chars;
    int unsigned                          n_pe, n_fe, n_bi, n_oe;
    int unsigned                          n_errors;
    string                                last_error;

    protected realtime  m_period;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(fwvip_uart_mon_config)::get(this, "", "cfg", m_cfg))
            `uvm_fatal(get_type_name(), "no fwvip_uart_mon_config \"cfg\" in the config DB")
        void'(uvm_config_db #(fwvip_clock_config)::get(this, "", "clock", m_clock));
        trace = $test$plusargs("fwvip_uart_mon_trace");
        ap = new("ap", this);
        m_cfg.attach(this);
    endfunction

    task run_phase(uvm_phase phase);
        if (m_clock != null) begin
            realtime t0;
            m_clock.tick(1);
            t0 = $realtime;
            m_clock.tick(1);
            m_period = $realtime - t0;
        end
        m_cfg.start();
    endtask

    // The status bits (FWVIP_UART_PE, ...) a test expects on the line.
    function void allow_status(bit [3:0] bits);
        allow = bits;
    endfunction

    function void observe(bit [7:0] data, bit [3:0] status, bit is_tx);
        fwvip_uart_char t = fwvip_uart_char::type_id::create("mon");
        t.op       = FWVIP_UART_CHAR;
        t.data     = data;
        t.status   = status;
        t.is_tx    = is_tx;
        t.line_cfg = m_cfg.line.convert2string();
        t.t_end    = $realtime;
        t.t_start  = $realtime;
        if (m_period != 0)
            t.t_bits = t.t_end / (real'(m_cfg.line.bit_clocks()) * m_period);
        n_chars++;
        if (status & FWVIP_UART_PE) n_pe++;
        if (status & FWVIP_UART_FE) n_fe++;
        if (status & FWVIP_UART_BI) n_bi++;
        if (status & FWVIP_UART_OE) n_oe++;
        if (trace) `uvm_info("UART_MON", t.convert2string(), UVM_LOW)
        if (status & ~allow) begin
            n_errors++;
            last_error = $sformatf("%s line [%s]: 0x%02h %s", is_tx ? "tx" : "rx",
                                   t.line_cfg, data, fwvip_uart_status_str(status & ~allow));
            if (check_enable) `uvm_error("UART_MON", last_error)
        end
        ap.write(t);
    endfunction

    // Forget the error count: after a test that provoked errors on purpose.
    function void clear();
        n_errors   = 0;
        last_error = "";
    endfunction
endclass
