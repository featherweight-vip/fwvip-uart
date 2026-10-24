// Transmit agent (design.md §3): sequences of fwvip_uart_char items, driven
// through the kit's transmit and error-injection APIs. Fetches "cfg" (a
// fwvip_uart_tx_config) and "clock" (fwvip-core's clock provider) from the
// config DB. `ap` publishes every item once it has run, with the predicted
// reception filled in: a scoreboard's expected stream.
class fwvip_uart_tx_agent extends uvm_agent;
    `uvm_component_utils(fwvip_uart_tx_agent)

    fwvip_uart_tx_config                  m_cfg;
    fwvip_clock_config                    m_clock;
    fwvip_uart_tx_sequencer               m_seqr;
    fwvip_uart_tx_driver                  m_driver;
    uvm_analysis_port #(fwvip_uart_char)  ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(fwvip_uart_tx_config)::get(this, "", "cfg", m_cfg))
            `uvm_fatal(get_type_name(), "no fwvip_uart_tx_config \"cfg\" in the config DB")
        if (!uvm_config_db #(fwvip_clock_config)::get(this, "", "clock", m_clock))
            `uvm_fatal(get_type_name(), "no clock provider (fwvip_clock_config \"clock\") in the config DB")
        m_seqr   = fwvip_uart_tx_sequencer::type_id::create("m_seqr", this);
        m_seqr.m_cfg = m_cfg;
        m_driver = fwvip_uart_tx_driver::type_id::create("m_driver", this);
        m_driver.m_cfg   = m_cfg;
        m_driver.m_clock = m_clock;
        ap = new("ap", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_driver.seq_item_port.connect(m_seqr.seq_item_export);
        m_driver.ap.connect(ap);
    endfunction

    // Add a role on the same link to those a CFG item reconfigures.
    function void add_peer(uart_config_if peer);
        m_cfg.peers.push_back(peer);
    endfunction
endclass
