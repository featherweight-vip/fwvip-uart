typedef class fwvip_uart_rx_agent;

// The rx agent's seam: a uart_rx_if sink that hands every character the
// kit's receiver deframes to the agent, and the receiver's uart_config_if.
// The vif-aware specialization runs the kit's uart_rx_xtor_bridge with this
// config as its sink. `line` is the framing last configured.
//
// The sink never blocks, so the kit receiver's output is always taken: an
// OE seen here was made on the line side, not by the VIP.
class fwvip_uart_rx_config extends uvm_object implements uart_rx_if, uart_config_if;
    `uvm_object_utils(fwvip_uart_rx_config)

    fwvip_uart_cfg_item            line;
    protected fwvip_uart_rx_agent  m_agent;

    function new(string name = "fwvip_uart_rx_config");
        super.new(name);
        line = fwvip_uart_cfg_item::type_id::create("line");
    endfunction

    function void attach(fwvip_uart_rx_agent agent);
        m_agent = agent;
    endfunction

    // Start delivering characters (the specialization starts the kit bridge).
    virtual task start();
    endtask

    virtual task recv(input bit [7:0] data, input bit [3:0] status);
        if (m_agent != null) m_agent.receive(data, status);
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
        // No transactor: a sink fed by something else (a model) only
        // records the framing.
    endtask
endclass

class fwvip_uart_rx_config_p #(type vif_t = virtual uart_rx_xtor_if)
        extends fwvip_uart_rx_config;
    typedef fwvip_uart_rx_config_p #(vif_t) this_t;

    vif_t                vif;
    uart_rx_xtor_bridge  m_bridge;

    function new(string name = "fwvip_uart_rx_config_p");
        super.new(name);
    endfunction

    static function this_t set(uvm_component ctxt, string inst, string field, vif_t vif);
        this_t cfg = new();
        cfg.vif = vif;
        uvm_config_db #(fwvip_uart_rx_config)::set(ctxt, inst, field, cfg);
        return cfg;
    endfunction

    protected function void ensure();
        if (m_bridge == null) m_bridge = new(vif, this);
    endfunction

    virtual task start();
        ensure();
        m_bridge.start_bridge();
    endtask

    protected virtual task xtor_configure(input bit [15:0] divisor, input bit [3:0] word_bits,
                                          input bit parity_en, input bit parity_even,
                                          input bit parity_stick, input bit [1:0] stop_bits);
        ensure();
        m_bridge.configure(divisor, word_bits, parity_en, parity_even, parity_stick, stop_bits);
    endtask
endclass
