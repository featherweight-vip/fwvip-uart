// Base for tx sequences: one helper per op, each running one item and
// returning it completed (predicted reception and times filled in).
class fwvip_uart_tx_seq_base extends uvm_sequence #(fwvip_uart_char);
    `uvm_object_utils(fwvip_uart_tx_seq_base)

    function new(string name = "fwvip_uart_tx_seq_base");
        super.new(name);
    endfunction

    // The framing the tx agent is configured with now.
    function fwvip_uart_cfg_item line();
        fwvip_uart_tx_sequencer seqr;
        if (!$cast(seqr, m_sequencer) || seqr.m_cfg == null)
            `uvm_fatal(get_type_name(), "not running on a fwvip_uart_tx_agent's sequencer")
        return seqr.m_cfg.line;
    endfunction

    task do_item(fwvip_uart_char t);
        start_item(t);
        finish_item(t);
    endtask

    protected function fwvip_uart_char mk(fwvip_uart_op_e op, string name);
        fwvip_uart_char t = fwvip_uart_char::type_id::create(name);
        t.op = op;
        return t;
    endfunction

    task send(bit [7:0] data);
        fwvip_uart_char t = mk(FWVIP_UART_CHAR, "char");
        t.data = data;
        do_item(t);
    endtask

    task send_err(bit [7:0] data, bit bad_parity = 0, bit bad_stop = 0, int baud_ppm = 0,
                  int unsigned glitch_at = 0, int unsigned glitch_len = 0);
        fwvip_uart_char t = mk(FWVIP_UART_ERR, "err");
        t.data       = data;
        t.bad_parity = bad_parity;
        t.bad_stop   = bad_stop;
        t.baud_ppm   = baud_ppm;
        t.glitch_at  = glitch_at;
        t.glitch_len = glitch_len;
        do_item(t);
    endtask

    task send_break(int unsigned n_chars = 1);
        fwvip_uart_char t = mk(FWVIP_UART_BREAK, "break");
        t.n_chars = n_chars;
        do_item(t);
    endtask

    task glitch(int unsigned glitch_len);
        fwvip_uart_char t = mk(FWVIP_UART_GLITCH, "glitch");
        t.glitch_len = glitch_len;
        do_item(t);
    endtask

    // Mark for n_bits bit times, after everything before it has gone out.
    task idle(int unsigned n_bits);
        fwvip_uart_char t = mk(FWVIP_UART_IDLE, "idle");
        t.n_bits = n_bits;
        do_item(t);
    endtask

    // Reconfigure the link (tx and its peers) once the line is idle.
    task reconfigure(fwvip_uart_cfg_item c);
        fwvip_uart_char t = mk(FWVIP_UART_CFG, "cfg");
        t.cfg = fwvip_uart_cfg_item::type_id::create("cfg");
        t.cfg.copy(c);
        do_item(t);
    endtask
endclass
