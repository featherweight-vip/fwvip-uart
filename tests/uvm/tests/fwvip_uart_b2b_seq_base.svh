// Base for the back-to-back cases: a tx sequence with a handle to the env
// (scoreboard, rx and monitor agents). The scoreboard checks every
// character against the tx agent's prediction; a case checks what is
// particular to it with check().
class fwvip_uart_b2b_seq_base extends fwvip_uart_tx_seq_base;
    `uvm_object_utils(fwvip_uart_b2b_seq_base)

    fwvip_uart_b2b_env  env;

    function new(string name = "fwvip_uart_b2b_seq_base");
        super.new(name);
    endfunction

    // What every case starts from: 8N1 at divisor 2 (32 clocks a bit), and
    // a monitor that allows no line error.
    virtual function void defaults();
        env.m_mon.allow_status(0);
    endfunction

    // Run first, on the sequencer: set the starting framing.
    virtual task pre_body();
        fwvip_uart_cfg_item c = fwvip_uart_cfg_item::type_id::create("c");
        reconfigure(c.set(2));
    endtask

    function void check(bit cond, string what);
        if (!cond) `uvm_error(get_type_name(), {"check failed: ", what})
    endfunction

    // Let the last character reach the rx and monitor agents.
    task settle();
        idle(2);
    endtask

    // A random legal framing at divisor 1..4.
    function fwvip_uart_cfg_item rand_cfg();
        fwvip_uart_cfg_item c = fwvip_uart_cfg_item::type_id::create("c");
        if (!c.randomize()) `uvm_fatal(get_type_name(), "cfg randomize failed")
        return c;
    endfunction
endclass
