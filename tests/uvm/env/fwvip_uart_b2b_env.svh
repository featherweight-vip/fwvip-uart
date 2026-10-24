// The back-to-back UVM env: the VIP's tx, rx and monitor agents on one
// link, and a scoreboard over the tx agent's predictions and what the rx
// and monitor agents received. The rx and monitor configs are the tx
// agent's peers, so a CFG item reconfigures the whole link.
class fwvip_uart_b2b_env extends uvm_env;
    `uvm_component_utils(fwvip_uart_b2b_env)

    fwvip_uart_tx_agent   m_tx;
    fwvip_uart_rx_agent   m_rx;
    fwvip_uart_mon_agent  m_mon;
    fwvip_uart_b2b_sb     m_sb;
    fwvip_reset_config    m_reset;
    fwvip_clock_config    m_clock;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_tx  = fwvip_uart_tx_agent::type_id::create("m_tx", this);
        m_rx  = fwvip_uart_rx_agent::type_id::create("m_rx", this);
        m_mon = fwvip_uart_mon_agent::type_id::create("m_mon", this);
        m_sb  = fwvip_uart_b2b_sb::type_id::create("m_sb", this);
        if (!uvm_config_db #(fwvip_reset_config)::get(this, "", "reset", m_reset))
            `uvm_fatal(get_type_name(), "no reset provider (fwvip_reset_config) in the config DB")
        if (!uvm_config_db #(fwvip_clock_config)::get(this, "", "clock", m_clock))
            `uvm_fatal(get_type_name(), "no clock provider (fwvip_clock_config) in the config DB")
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_tx.add_peer(m_rx.m_cfg);
        m_tx.add_peer(m_mon.m_cfg);
        m_tx.ap.connect(m_sb.tx_export);
        m_rx.ap.connect(m_sb.rx_export);
        m_mon.ap.connect(m_sb.mon_export);
    endfunction

    task wait_ready();
        m_reset.wait_reset();
    endtask
endclass
