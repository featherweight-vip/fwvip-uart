// The tx agent's driver: runs each fwvip_uart_char item through the config,
// fills in what a receiver configured alike should report (predict()) and
// the times, then publishes it on `ap`. Items run in order, one at a time;
// CHAR items return as soon as the transactor has queued the character, so
// a run of them goes out back to back.
//
// The kit's API has no "transmitter idle" event, so the driver keeps an
// estimate of when the last frame ends (m_busy_until): a queued character
// starts when the one before it ends, or now. drain() waits for that, plus
// one bit for what the estimate leaves out (the wait for the next baud tick,
// the transactor's clocked copies). IDLE and CFG items drain first.
class fwvip_uart_tx_driver extends uvm_driver #(fwvip_uart_char);
    `uvm_component_utils(fwvip_uart_tx_driver)

    fwvip_uart_tx_config                  m_cfg;
    fwvip_clock_config                    m_clock;
    uvm_analysis_port #(fwvip_uart_char)  ap;
    int unsigned                          n_done;

    protected realtime  m_period;
    protected realtime  m_busy_until;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        fwvip_uart_char t;
        measure_period();
        forever begin
            seq_item_port.get_next_item(t);
            execute(t);
            n_done++;
            ap.write(t);
            seq_item_port.item_done();
        end
    endtask

    // The clock period, for the frame-time estimate and timestamps.
    protected task measure_period();
        realtime t0;
        m_clock.tick(1);
        t0 = $realtime;
        m_clock.tick(1);
        m_period = $realtime - t0;
    endtask

    function realtime clock_period();
        return m_period;
    endfunction

    // Wait until everything sent so far is off the line.
    task drain();
        realtime idle_at = m_busy_until + real'(m_cfg.line.bit_clocks()) * m_period;
        if (idle_at > $realtime)
            m_clock.tick(int'((idle_at - $realtime) / m_period) + 1);
    endtask

    virtual task execute(fwvip_uart_char t);
        fwvip_uart_cfg_item c = m_cfg.line;
        realtime            frame = real'(c.char_clocks()) * m_period;
        t.predict(c);
        t.t_start = $realtime;
        case (t.op)
        FWVIP_UART_CHAR: begin
            m_cfg.send(t.data);
            t.t_start = (m_busy_until > $realtime) ? m_busy_until : $realtime;
            m_busy_until = t.t_start + frame;
        end
        FWVIP_UART_ERR: begin
            m_cfg.send_err(t.data, t.bad_parity, t.bad_stop, t.baud_ppm,
                           t.glitch_at, t.glitch_len);
            m_busy_until = $realtime;
        end
        FWVIP_UART_BREAK: begin
            m_cfg.send_break(t.n_chars);
            // The core holds mark for a bit after a break.
            m_busy_until = $realtime + real'(c.bit_clocks()) * m_period;
        end
        FWVIP_UART_GLITCH: begin
            m_cfg.glitch(t.glitch_len);
            m_busy_until = $realtime;
        end
        FWVIP_UART_IDLE: begin
            drain();
            t.t_start = $realtime;
            m_clock.tick(t.n_bits * c.bit_clocks());
        end
        FWVIP_UART_CFG: begin
            if (t.cfg == null)
                `uvm_fatal(get_type_name(), "CFG item with no cfg")
            drain();
            m_cfg.configure_line(t.cfg);
        end
        endcase
        t.t_end  = (t.op == FWVIP_UART_CHAR) ? m_busy_until : $realtime;
        t.t_bits = t.t_end / (real'(c.bit_clocks()) * m_period);
    endtask
endclass
