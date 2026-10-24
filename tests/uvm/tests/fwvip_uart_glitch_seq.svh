// Glitches: pulses of space up to a third of a bit on the idle line (the
// receiver must reject each start bit: no character), then glitches across
// a data bit (that bit flips; PE with parity).
class fwvip_uart_glitch_seq extends fwvip_uart_b2b_seq_base;
    `uvm_object_utils(fwvip_uart_glitch_seq)

    function new(string name = "fwvip_uart_glitch_seq");
        super.new(name);
    endfunction

    virtual function void defaults();
        super.defaults();
        env.m_mon.allow_status(FWVIP_UART_PE);
    endfunction

    task body();
        fwvip_uart_err_seq  e = fwvip_uart_err_seq::type_id::create("e");
        fwvip_uart_cfg_item c = fwvip_uart_cfg_item::type_id::create("c");
        int unsigned        n0 = env.m_rx.n_chars;
        reconfigure(c.set(4, 8, 1, 1));    // 8E1/4: 64 clocks a bit
        for (int unsigned len = 1; len <= 21; len += 5) begin
            glitch(len);
            idle(2);
        end
        settle();
        check(env.m_rx.n_chars == n0, $sformatf("%0d characters from idle-line glitches",
                                                  env.m_rx.n_chars - n0));
        e.en_parity = 0;
        e.en_stop   = 0;
        e.en_baud   = 0;
        e.n_errs    = 16;
        e.start(m_sequencer, this);
        settle();
    endtask
endclass
