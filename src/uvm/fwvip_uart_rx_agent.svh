// Receive agent (design.md §3): the kit's receiver deframes characters from
// the line; the agent publishes each on `ap` as a fwvip_uart_char (op CHAR,
// data and status as reported) and keeps it for get(), so a test can pull
// characters in order. UART has no response on the wire, so there is no
// sequencer: what the far end sends arrives here.
//
// Fetches "cfg" (a fwvip_uart_rx_config) from the config DB, and "clock"
// (fwvip-core's clock provider) if there is one, for t_bits.
// +fwvip_uart_rx_trace prints every character.
class fwvip_uart_rx_agent extends uvm_component;
    `uvm_component_utils(fwvip_uart_rx_agent)

    fwvip_uart_rx_config                  m_cfg;
    fwvip_clock_config                    m_clock;
    uvm_analysis_port #(fwvip_uart_char)  ap;
    bit                                   trace;
    int unsigned                          n_chars;

    protected fwvip_uart_char  m_q[$];
    protected realtime         m_period;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(fwvip_uart_rx_config)::get(this, "", "cfg", m_cfg))
            `uvm_fatal(get_type_name(), "no fwvip_uart_rx_config \"cfg\" in the config DB")
        void'(uvm_config_db #(fwvip_clock_config)::get(this, "", "clock", m_clock));
        trace = $test$plusargs("fwvip_uart_rx_trace");
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

    function void receive(bit [7:0] data, bit [3:0] status);
        fwvip_uart_char t = fwvip_uart_char::type_id::create("rx");
        t.op       = FWVIP_UART_CHAR;
        t.data     = data;
        t.status   = status;
        t.line_cfg = m_cfg.line.convert2string();
        t.t_end    = $realtime;
        t.t_start  = $realtime;
        if (m_period != 0)
            t.t_bits = t.t_end / (real'(m_cfg.line.bit_clocks()) * m_period);
        n_chars++;
        if (trace) `uvm_info("UART_RX", t.convert2string(), UVM_LOW)
        m_q.push_back(t);
        ap.write(t);
    endfunction

    // The next character received, in order; waits for one.
    task get(output fwvip_uart_char t);
        wait (m_q.size() != 0);
        t = m_q.pop_front();
    endtask

    function int unsigned available();
        return m_q.size();
    endfunction

    // Forget the characters no one has taken with get().
    function void clear();
        m_q.delete();
    endfunction
endclass
