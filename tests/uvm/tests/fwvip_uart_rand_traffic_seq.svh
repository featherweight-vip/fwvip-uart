// Random traffic at a random framing: 200 characters in bursts of 1..8
// with gaps of 0..8 character times.
class fwvip_uart_rand_traffic_seq extends fwvip_uart_b2b_seq_base;
    `uvm_object_utils(fwvip_uart_rand_traffic_seq)

    function new(string name = "fwvip_uart_rand_traffic_seq");
        super.new(name);
    endfunction

    task body();
        fwvip_uart_rand_seq r = fwvip_uart_rand_seq::type_id::create("r");
        fwvip_uart_cfg_item c = rand_cfg();
        `uvm_info(get_type_name(), {"framing ", c.convert2string()}, UVM_LOW)
        reconfigure(c);
        r.n_chars = 200;
        r.start(m_sequencer, this);
        settle();
    endtask
endclass
