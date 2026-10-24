// Error injection (K6): n_errs frames with a line error, each followed by a
// clean character, at the framing in force. The kinds, picked at random
// from those enabled:
//
//   bad_parity  the parity bit inverted: PE (skipped with parity off)
//   bad_stop    the stop bit space: FE
//   baud        a baud offset of baud_ppm_min..baud_ppm_max either way.
//               Inside the sampling margin (the default, 2..3%), the frame
//               must arrive clean
//   glitch      the line inverted for half a bit across the middle of one
//               data bit: that bit flips, and PE with (non-stick) parity
//
// The data avoids 0x00, so a bad stop bit does not make a whole frame of
// space (a break). The monitor and receiver report errors; a bench that
// runs this lets its monitors allow PE and FE.
class fwvip_uart_err_seq extends fwvip_uart_tx_seq_base;
    `uvm_object_utils(fwvip_uart_err_seq)

    int unsigned  n_errs       = 16;
    bit           en_parity    = 1;
    bit           en_stop      = 1;
    bit           en_baud      = 1;
    bit           en_glitch    = 1;
    int           baud_ppm_min = 20000;
    int           baud_ppm_max = 30000;

    function new(string name = "fwvip_uart_err_seq");
        super.new(name);
    endfunction

    task body();
        fwvip_uart_cfg_item c = line();
        int unsigned        kinds[$];
        if (en_parity && c.parity_en) kinds.push_back(0);
        if (en_stop)                  kinds.push_back(1);
        if (en_baud)                  kinds.push_back(2);
        if (en_glitch)                kinds.push_back(3);
        if (kinds.size() == 0)
            `uvm_fatal(get_type_name(), "no error kind enabled")
        repeat (n_errs) begin
            bit [7:0] d;
            do d = 8'($urandom) & c.mask(); while (d == 0);
            case (kinds[$urandom_range(kinds.size() - 1, 0)])
            0: send_err(d, .bad_parity(1));
            1: send_err(d, .bad_stop(1));
            2: begin
                int ppm = $urandom_range(baud_ppm_max, baud_ppm_min);
                send_err(d, .baud_ppm($urandom_range(1, 0) ? ppm : -ppm));
            end
            3: begin
                int unsigned b = c.bit_clocks();
                int unsigned k = $urandom_range(c.word_bits - 1, 0);
                // Data bit k is bit k+1 of the frame; its middle is
                // (k + 1.5) bits after the start edge.
                send_err(d, .glitch_at(((2 * k + 3) * b) / 2 - b / 4), .glitch_len(b / 2));
            end
            endcase
            send(8'($urandom));
        end
    endtask
endclass
