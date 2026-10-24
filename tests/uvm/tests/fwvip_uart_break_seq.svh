// Break: characters, a one-character break, characters, a three-character
// break, characters. Each break must arrive as one character, data 0 with
// BI, at two framings.
class fwvip_uart_break_seq extends fwvip_uart_b2b_seq_base;
    `uvm_object_utils(fwvip_uart_break_seq)

    function new(string name = "fwvip_uart_break_seq");
        super.new(name);
    endfunction

    virtual function void defaults();
        super.defaults();
        env.m_mon.allow_status(FWVIP_UART_BI);
    endfunction

    task body();
        fwvip_uart_cfg_item c = fwvip_uart_cfg_item::type_id::create("c");
        for (int k = 0; k < 2; k++) begin
            if (k == 1) reconfigure(c.set(3, 5, 1, 1, 0, 1));    // 5E1.5/3
            send(8'h12);
            send(8'h34);
            send_break(1);
            send(8'h56);
            send_break(3);
            send_break(1);
            send(8'h78);
        end
        settle();
        check(env.m_mon.n_bi == 6, $sformatf("monitor saw %0d breaks, want 6", env.m_mon.n_bi));
    endtask
endclass
