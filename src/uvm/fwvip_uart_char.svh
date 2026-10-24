// One operation on a UART line, and the character that results.
//
// The tx agent takes these as sequence items; `op` says what goes on the
// line:
//   CHAR    one frame of `data` (uart_tx_if.send)
//   ERR     one frame of `data` with errors (uart_tx_inject_if.send_err):
//           bad_parity, bad_stop, baud_ppm, glitch_at/glitch_len
//   BREAK   a break of n_chars character times (uart_tx_if.send_break)
//   GLITCH  a space pulse of glitch_len clocks on the idle line
//   IDLE    mark for n_bits bit times after everything before it went out
//   CFG     reconfigure the line to `cfg` once it is idle: the tx side and
//           every peer the tx config holds (fwvip_uart_tx_config)
//
// When the tx driver has run an item it fills in what a receiver configured
// alike should report (predict()): rx_n (0 or 1 characters), rx_data and
// rx_status, or rx_known = 0 when the model cannot tell (a glitch on a
// sample point's edge, a baud offset past the sampling margin).
//
// The rx and monitor agents publish one of these per character received,
// with op CHAR, `data` and `status` as reported, and is_tx (monitor).
//
// Times: t_start/t_end are simulation times (the tx side's t_start is an
// estimate of when the frame started: send() returns once the transactor
// has queued the character). t_bits is t_end in bit times at the
// configuration in force, for gap arithmetic in sequences and scoreboards.
typedef enum {
    FWVIP_UART_CHAR,
    FWVIP_UART_ERR,
    FWVIP_UART_BREAK,
    FWVIP_UART_GLITCH,
    FWVIP_UART_IDLE,
    FWVIP_UART_CFG
} fwvip_uart_op_e;

class fwvip_uart_char extends uvm_sequence_item;
    `uvm_object_utils(fwvip_uart_char)

    rand fwvip_uart_op_e  op = FWVIP_UART_CHAR;
    rand bit [7:0]        data;
    bit [3:0]             status;      // rx/monitor: {OE, BI, FE, PE}
    bit                   is_tx;       // monitor: the line tapped

    // ERR
    rand bit              bad_parity;
    rand bit              bad_stop;
    rand int              baud_ppm;
    rand int unsigned     glitch_at;
    rand int unsigned     glitch_len;  // also GLITCH
    // BREAK
    rand int unsigned     n_chars = 1;
    // IDLE
    rand int unsigned     n_bits;
    // CFG
    fwvip_uart_cfg_item   cfg;

    // Filled in by the tx driver (predict()).
    bit                   rx_known = 1;
    int unsigned          rx_n;
    bit [7:0]             rx_data;
    bit [3:0]             rx_status;
    string                line_cfg;    // the configuration it ran under

    realtime              t_start, t_end;
    real                  t_bits;

    constraint c_default_clean {
        soft op == FWVIP_UART_CHAR;
        soft bad_parity == 0;
        soft bad_stop == 0;
        soft baud_ppm == 0;
        soft glitch_len == 0;
    }

    function new(string name = "fwvip_uart_char");
        super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
        fwvip_uart_char r;
        super.do_copy(rhs);
        $cast(r, rhs);
        op = r.op; data = r.data; status = r.status; is_tx = r.is_tx;
        bad_parity = r.bad_parity; bad_stop = r.bad_stop; baud_ppm = r.baud_ppm;
        glitch_at = r.glitch_at; glitch_len = r.glitch_len;
        n_chars = r.n_chars; n_bits = r.n_bits; cfg = r.cfg;
        rx_known = r.rx_known; rx_n = r.rx_n; rx_data = r.rx_data; rx_status = r.rx_status;
        line_cfg = r.line_cfg;
        t_start = r.t_start; t_end = r.t_end; t_bits = r.t_bits;
    endfunction

    function string convert2string();
        case (op)
        FWVIP_UART_CHAR:
            return $sformatf("CHAR 0x%02h %s%s", data, fwvip_uart_status_str(status), rx_str());
        FWVIP_UART_ERR:
            return $sformatf("ERR 0x%02h%s%s ppm=%0d glitch=%0d@%0d%s", data,
                             bad_parity ? " bad_parity" : "", bad_stop ? " bad_stop" : "",
                             baud_ppm, glitch_len, glitch_at, rx_str());
        FWVIP_UART_BREAK:  return $sformatf("BREAK %0d chars%s", n_chars, rx_str());
        FWVIP_UART_GLITCH: return $sformatf("GLITCH %0d clocks%s", glitch_len, rx_str());
        FWVIP_UART_IDLE:   return $sformatf("IDLE %0d bits", n_bits);
        FWVIP_UART_CFG:    return $sformatf("CFG %s", (cfg == null) ? "-" : cfg.convert2string());
        endcase
        return "?";
    endfunction

    protected function string rx_str();
        if (line_cfg == "") return "";
        if (!rx_known)      return $sformatf(" [%s] -> ?", line_cfg);
        if (rx_n == 0)      return $sformatf(" [%s] -> none", line_cfg);
        return $sformatf(" [%s] -> 0x%02h %s", line_cfg, rx_data, fwvip_uart_status_str(rx_status));
    endfunction

    // What a kit-style receiver (one mid-bit sample per bit, OVERSAMPLE/2
    // ticks in, only the first stop bit checked) configured as `c` reports
    // for this item. Sample points are taken at the receiver's bit centres;
    // a glitch must cover a quarter bit either side of one to count, and
    // must miss that window entirely to not count.
    function void predict(fwvip_uart_cfg_item c);
        line_cfg  = c.convert2string();
        rx_known  = 1;
        rx_n      = 0;
        rx_data   = 0;
        rx_status = 0;
        case (op)
        FWVIP_UART_CHAR: begin
            rx_n    = 1;
            rx_data = data & c.mask();
        end
        FWVIP_UART_BREAK: begin
            rx_n      = 1;
            rx_status = FWVIP_UART_BI;
        end
        FWVIP_UART_GLITCH:
            // A glitch shorter than half a bit is mark again at the start
            // bit's middle: no character.
            if (glitch_len * 2 + c.bit_clocks() / 4 > c.bit_clocks()) rx_known = 0;
        FWVIP_UART_ERR: predict_err(c);
        default: ;
        endcase
    endfunction

    protected function void predict_err(fwvip_uart_cfg_item c);
        // The frame as sent, bit 0 = start, then data, parity, first stop.
        bit           v[$];
        int unsigned  nb = c.frame_bits() + 1;
        real          b  = real'(c.bit_clocks());
        real          bt = b * (1.0 + real'(baud_ppm) / 1.0e6);
        bit [7:0]     d  = 0;
        bit           all_space = 1;
        bit           p;

        v.push_back(1'b0);
        for (int i = 0; i < c.word_bits; i++) v.push_back(data[i]);
        if (c.parity_en) v.push_back(c.parity(data) ^ bad_parity);
        v.push_back(!bad_stop);

        for (int i = 0; i < nb; i++) begin
            real s  = (real'(i) + 0.5) * b;  // the receiver's sample point
            real lo = s - b / 4.0, hi = s + b / 4.0;
            int  k;
            bit  x;
            // The sent bit at the sample point, with a margin for the tick
            // the receiver's start detection can be late by.
            k = int'($floor(s / bt));
            if (k != i || (s - real'(i) * bt) < 0.15 * bt || (real'(i + 1) * bt - s) < 0.15 * bt) begin
                rx_known = 0;
                return;
            end
            x = v[i];
            if (glitch_len != 0) begin
                real g0 = real'(glitch_at), g1 = real'(glitch_at + glitch_len);
                if (g0 <= lo && g1 >= hi)      x = !x;
                else if (g1 > lo && g0 < hi) begin
                    rx_known = 0;
                    return;
                end
            end
            if (i == 0 && x) begin
                // The start bit is mark at its middle: the receiver rejects
                // it, and the rest of the frame may start another.
                rx_known = 0;
                return;
            end
            if (x) all_space = 0;
            if (i >= 1 && i <= c.word_bits) d[i - 1] = x;
            v[i] = x;
        end

        rx_n = 1;
        if (all_space) begin
            rx_status = FWVIP_UART_BI;
            return;
        end
        rx_data = d;
        if (c.parity_en && v[c.word_bits + 1] != c.parity(d)) rx_status |= FWVIP_UART_PE;
        if (!v[nb - 1])                                         rx_status |= FWVIP_UART_FE;
    endfunction
endclass
