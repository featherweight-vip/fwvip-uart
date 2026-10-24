// The tx agent's sequencer. Holds the agent's config, so a sequence can
// read the framing in force (fwvip_uart_tx_seq_base::line()).
class fwvip_uart_tx_sequencer extends uvm_sequencer #(fwvip_uart_char);
    `uvm_component_utils(fwvip_uart_tx_sequencer)

    fwvip_uart_tx_config m_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
