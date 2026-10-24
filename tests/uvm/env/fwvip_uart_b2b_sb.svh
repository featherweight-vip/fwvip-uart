// The back-to-back scoreboard. Every item the tx agent ran carries what a
// receiver configured alike should report (fwvip_uart_char::predict()): no
// character, or one with its data and status. Both the rx agent's
// characters and the monitor agent's must match that stream, in order.
//
// An item the model cannot predict (rx_known = 0) is an error here: the
// bench's sequences only make frames whose reception is determined.
class fwvip_uart_b2b_sb extends uvm_component;
    `uvm_component_utils(fwvip_uart_b2b_sb)

    uvm_analysis_imp_tx  #(fwvip_uart_char, fwvip_uart_b2b_sb)  tx_export;
    uvm_analysis_imp_rx  #(fwvip_uart_char, fwvip_uart_b2b_sb)  rx_export;
    uvm_analysis_imp_mon #(fwvip_uart_char, fwvip_uart_b2b_sb)  mon_export;

    fwvip_uart_char  m_exp_rx[$];
    fwvip_uart_char  m_exp_mon[$];
    fwvip_uart_char  m_got_rx[$];
    fwvip_uart_char  m_got_mon[$];
    int unsigned     n_expected, n_rx_matched, n_mon_matched, n_bad;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tx_export  = new("tx_export", this);
        rx_export  = new("rx_export", this);
        mon_export = new("mon_export", this);
    endfunction

    function void write_tx(fwvip_uart_char t);
        if (!t.rx_known) begin
            n_bad++;
            `uvm_error("SB", {"the bench sent a frame whose reception the model cannot predict: ",
                              t.convert2string()})
            return;
        end
        if (t.rx_n == 0) return;
        n_expected++;
        m_exp_rx.push_back(t);
        m_exp_mon.push_back(t);
        pair("rx", m_exp_rx, m_got_rx, n_rx_matched);
        pair("monitor", m_exp_mon, m_got_mon, n_mon_matched);
    endfunction

    function void write_rx(fwvip_uart_char t);
        m_got_rx.push_back(t);
        pair("rx", m_exp_rx, m_got_rx, n_rx_matched);
    endfunction

    function void write_mon(fwvip_uart_char t);
        if (!t.is_tx) begin
            n_bad++;
            `uvm_error("SB", {"monitor reports the rx line; it taps the tx line: ", t.convert2string()})
        end
        m_got_mon.push_back(t);
        pair("monitor", m_exp_mon, m_got_mon, n_mon_matched);
    endfunction

    protected function void pair(string who, ref fwvip_uart_char exp[$],
                                 ref fwvip_uart_char got[$], ref int unsigned n_ok);
        while (exp.size() != 0 && got.size() != 0) begin
            fwvip_uart_char e = exp.pop_front();
            fwvip_uart_char g = got.pop_front();
            if (g.data == e.rx_data && g.status == e.rx_status) n_ok++;
            else begin
                n_bad++;
                `uvm_error("SB", $sformatf("%s mismatch:\n  sent     %s\n  received %s",
                                           who, e.convert2string(), g.convert2string()))
            end
        end
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (m_exp_rx.size() != 0 || m_got_rx.size() != 0)
            `uvm_error("SB", $sformatf("rx unpaired at the end: %0d expected, %0d received unexpected (first: %s)",
                                       m_exp_rx.size(), m_got_rx.size(),
                                       m_exp_rx.size() ? m_exp_rx[0].convert2string()
                                                       : m_got_rx[0].convert2string()))
        if (m_exp_mon.size() != 0 || m_got_mon.size() != 0)
            `uvm_error("SB", $sformatf("monitor unpaired at the end: %0d expected, %0d received unexpected (first: %s)",
                                       m_exp_mon.size(), m_got_mon.size(),
                                       m_exp_mon.size() ? m_exp_mon[0].convert2string()
                                                        : m_got_mon[0].convert2string()))
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf("%0d characters expected; rx matched %0d, monitor matched %0d; %0d bad",
                                  n_expected, n_rx_matched, n_mon_matched, n_bad), UVM_LOW)
    endfunction
endclass
