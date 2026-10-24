// Baud offset: frames 2..3% fast or slow at the longest framings (8 bits,
// parity, 2 stop bits) and a random one. Inside the sampling margin every
// frame must arrive clean: the monitor allows no error.
class fwvip_uart_baud_offset_seq extends fwvip_uart_b2b_seq_base;
    `uvm_object_utils(fwvip_uart_baud_offset_seq)

    function new(string name = "fwvip_uart_baud_offset_seq");
        super.new(name);
    endfunction

    task body();
        fwvip_uart_cfg_item c = fwvip_uart_cfg_item::type_id::create("c");
        for (int k = 0; k < 3; k++) begin
            fwvip_uart_err_seq e = fwvip_uart_err_seq::type_id::create("e");
            if (k < 2) void'(c.set(2 + k, 8, 1, k[0], 0, 1));
            else       c = rand_cfg();
            reconfigure(c);
            e.en_parity = 0;
            e.en_stop   = 0;
            e.en_glitch = 0;
            e.n_errs    = 16;
            e.start(m_sequencer, this);
        end
        settle();
    endtask
endclass
