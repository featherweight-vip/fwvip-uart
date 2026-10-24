// Every framing: word lengths 5..8 x parity none, odd, even, mark, space x
// 1 and 2 (1.5) stop bits, divisors 1..3 in turn, reconfiguring the link
// between them. Each framing carries all-zeros, all-ones and two random
// characters.
class fwvip_uart_cfg_sweep_seq extends fwvip_uart_b2b_seq_base;
    `uvm_object_utils(fwvip_uart_cfg_sweep_seq)

    function new(string name = "fwvip_uart_cfg_sweep_seq");
        super.new(name);
    endfunction

    task body();
        fwvip_uart_cfg_item c = fwvip_uart_cfg_item::type_id::create("c");
        int unsigned n = 0;
        for (int w = 5; w <= 8; w++)
            for (int p = 0; p < 5; p++)
                for (int s = 0; s < 2; s++) begin
                    // p: 0 none, 1 odd, 2 even, 3 mark, 4 space
                    void'(c.set(16'(1 + n % 3), 4'(w), p != 0, p == 2 || p == 4, p >= 3, 2'(s)));
                    reconfigure(c);
                    send(8'h00);
                    send(8'hff);
                    send(8'($urandom));
                    send(8'($urandom));
                    n++;
                end
        settle();
    endtask
endclass
