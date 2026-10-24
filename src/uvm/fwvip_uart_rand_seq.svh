// Random traffic: bursts of random characters separated by idle gaps.
//
//   n_chars              characters in all
//   burst_min/burst_max  characters per burst (back to back)
//   gap_min/gap_max      idle between bursts, in character times at the
//                        current framing (rounded up to whole bits). The
//                        default 0..8 straddles a 16550's four-character
//                        RX timeout
class fwvip_uart_rand_seq extends fwvip_uart_tx_seq_base;
    `uvm_object_utils(fwvip_uart_rand_seq)

    int unsigned  n_chars   = 32;
    int unsigned  burst_min = 1;
    int unsigned  burst_max = 8;
    real          gap_min   = 0.0;
    real          gap_max   = 8.0;

    function new(string name = "fwvip_uart_rand_seq");
        super.new(name);
    endfunction

    task body();
        int unsigned sent = 0;
        fwvip_uart_cfg_item c = line();
        real         bits_per_char = real'(2 * c.frame_bits() + c.stop_halves()) / 2.0;
        while (sent < n_chars) begin
            int unsigned n = $urandom_range(burst_max, burst_min);
            real         g = gap_min + (gap_max - gap_min) * real'($urandom_range(1000, 0)) / 1000.0;
            if (n > n_chars - sent) n = n_chars - sent;
            repeat (n) send(8'($urandom));
            sent += n;
            if (sent < n_chars) idle(int'($ceil(g * bits_per_char)));
        end
    endtask
endclass
