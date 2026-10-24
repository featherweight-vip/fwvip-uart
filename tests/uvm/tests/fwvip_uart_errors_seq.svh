// Line errors at random framings with parity: bad parity (PE), bad stop
// (FE), baud offsets inside the sampling margin (clean) and a glitch across
// one data bit (that bit flipped, PE). The scoreboard checks each error
// against the model; the monitor allows PE and FE.
class fwvip_uart_errors_seq extends fwvip_uart_b2b_seq_base;
    `uvm_object_utils(fwvip_uart_errors_seq)

    function new(string name = "fwvip_uart_errors_seq");
        super.new(name);
    endfunction

    virtual function void defaults();
        super.defaults();
        env.m_mon.allow_status(FWVIP_UART_PE | FWVIP_UART_FE);
    endfunction

    task body();
        repeat (4) begin
            fwvip_uart_err_seq  e = fwvip_uart_err_seq::type_id::create("e");
            fwvip_uart_cfg_item c = rand_cfg();
            c.parity_en = 1;
            `uvm_info(get_type_name(), {"framing ", c.convert2string()}, UVM_LOW)
            reconfigure(c);
            e.n_errs = 20;
            e.start(m_sequencer, this);
        end
        settle();
        check(env.m_mon.n_pe != 0, "the monitor saw no parity error");
        check(env.m_mon.n_fe != 0, "the monitor saw no framing error");
    endtask
endclass
