// The monitor agent has teeth: smoke traffic first (which must be clean),
// then a parity error, a framing error and a break injected on the line,
// with the monitor allowing none of them. It must flag each one as a
// UVM_ERROR; this case turns those errors into infos and checks that it saw
// them. The scoreboard still checks every character against the model.
class fwvip_uart_mon_teeth_seq extends fwvip_uart_smoke_seq;
    `uvm_object_utils(fwvip_uart_mon_teeth_seq)

    function new(string name = "fwvip_uart_mon_teeth_seq");
        super.new(name);
    endfunction

    protected task expect_flag(string what, int unsigned n_before);
        settle();
        if (env.m_mon.n_errors == n_before)
            `uvm_error(get_type_name(), {"the monitor agent did not flag ", what})
        else
            `uvm_info(get_type_name(), $sformatf("flagged: %s", env.m_mon.last_error), UVM_LOW)
    endtask

    task body();
        fwvip_uart_cfg_item c   = fwvip_uart_cfg_item::type_id::create("c");
        uvm_report_server   srv = uvm_report_server::get_server();
        int unsigned        n0, n_id0;
        super.body();
        if (env.m_mon.n_errors != 0)
            `uvm_error(get_type_name(), "traffic before the bad frames was not clean")
        env.m_mon.set_report_severity_id_override(UVM_ERROR, "UART_MON", UVM_INFO);
        n_id0 = srv.get_id_count("UART_MON");

        reconfigure(c.set(2, 8, 1, 1));    // 8E1/2

        n0 = env.m_mon.n_errors;
        send_err(8'h5a, .bad_parity(1));
        expect_flag("a parity error", n0);

        n0 = env.m_mon.n_errors;
        send_err(8'h5a, .bad_stop(1));
        expect_flag("a framing error", n0);

        n0 = env.m_mon.n_errors;
        send_break(2);
        expect_flag("a break", n0);

        if (srv.get_id_count("UART_MON") == n_id0)
            `uvm_error(get_type_name(), "the monitor agent did not report the errors")
        env.m_mon.clear();
    endtask
endclass
