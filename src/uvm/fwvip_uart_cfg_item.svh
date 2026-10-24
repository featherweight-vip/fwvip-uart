// The line configuration: the arguments of the kit's uart_config_if, as an
// object a sequence can randomize, apply and print. Default: divisor 16, 8N1,
// the kit transactors' reset configuration.
//
// Constraints: the legal space (5..8 bits, divisor >= 1, stop_bits 0 or 1)
// and a soft divisor of 1..4, which keeps a character under 1000 clocks.
class fwvip_uart_cfg_item extends uvm_object;
    `uvm_object_utils(fwvip_uart_cfg_item)

    rand bit [15:0] divisor      = 16'd16;
    rand bit [3:0]  word_bits    = 4'd8;
    rand bit        parity_en    = 1'b0;
    rand bit        parity_even  = 1'b0;
    rand bit        parity_stick = 1'b0;
    rand bit [1:0]  stop_bits    = 2'd0;

    constraint c_legal {
        divisor != 0;
        word_bits inside {[5:8]};
        stop_bits inside {0, 1};
    }
    constraint c_divisor_small { soft divisor inside {[1:4]}; }

    function new(string name = "fwvip_uart_cfg_item");
        super.new(name);
    endfunction

    // Set every field (one call per line configuration).
    function fwvip_uart_cfg_item set(bit [15:0] divisor, bit [3:0] word_bits = 8,
                                     bit parity_en = 0, bit parity_even = 0,
                                     bit parity_stick = 0, bit [1:0] stop_bits = 0);
        this.divisor      = divisor;
        this.word_bits    = word_bits;
        this.parity_en    = parity_en;
        this.parity_even  = parity_even;
        this.parity_stick = parity_stick;
        this.stop_bits    = stop_bits;
        return this;
    endfunction

    task apply(uart_config_if c);
        c.configure(divisor, word_bits, parity_en, parity_even, parity_stick, stop_bits);
    endtask

    function void do_copy(uvm_object rhs);
        fwvip_uart_cfg_item r;
        super.do_copy(rhs);
        $cast(r, rhs);
        void'(set(r.divisor, r.word_bits, r.parity_en, r.parity_even, r.parity_stick, r.stop_bits));
    endfunction

    function bit same(fwvip_uart_cfg_item r);
        return divisor == r.divisor && word_bits == r.word_bits &&
               parity_en == r.parity_en && parity_even == r.parity_even &&
               parity_stick == r.parity_stick && stop_bits == r.stop_bits;
    endfunction

    // ---- timing, in clocks

    function int unsigned bit_clocks();
        return OVERSAMPLE * int'(divisor);
    endfunction

    // Stop length in half bits: 1, 1.5 (5-bit words) or 2 stop bits.
    function int unsigned stop_halves();
        if (stop_bits == 0) return 2;
        return (word_bits == 5) ? 3 : 4;
    endfunction

    // Bits from the start bit to the last parity bit.
    function int unsigned frame_bits();
        return 1 + int'(word_bits) + int'(parity_en);
    endfunction

    function int unsigned char_clocks();
        return ((2 * frame_bits() + stop_halves()) * bit_clocks()) / 2;
    endfunction

    // ---- framing

    function bit [7:0] mask();
        return 8'((9'd1 << word_bits) - 1);
    endfunction

    // The parity bit sent with `data` (with parity on).
    function bit parity(bit [7:0] data);
        bit p = ^(data & mask());
        if (parity_stick) return !parity_even;
        return parity_even ? p : !p;
    endfunction

    // "8N1/4": word bits, parity (N none, O odd, E even, M mark, S space),
    // stop bits, divisor.
    function string convert2string();
        string p, s;
        if (!parity_en)         p = "N";
        else if (parity_stick)  p = parity_even ? "S" : "M";
        else                    p = parity_even ? "E" : "O";
        s = (stop_bits == 0) ? "1" : (word_bits == 5) ? "1.5" : "2";
        return $sformatf("%0d%s%s/%0d", word_bits, p, s, divisor);
    endfunction
endclass
