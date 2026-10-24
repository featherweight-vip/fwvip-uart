// Smoke: 8N1, a burst of characters back to back, an idle gap, then a few
// more one at a time; the rx agent must hand them back in order.
class fwvip_uart_smoke_seq extends fwvip_uart_b2b_seq_base;
    `uvm_object_utils(fwvip_uart_smoke_seq)

    function new(string name = "fwvip_uart_smoke_seq");
        super.new(name);
    endfunction

    task body();
        bit [7:0] d[] = '{8'h55, 8'haa, 8'h00, 8'hff, 8'h01, 8'h80, 8'h3c, 8'hc3};
        foreach (d[i]) send(d[i]);
        idle(20);
        send(8'h41);
        idle(3);
        send(8'h42);
        settle();
        for (int i = 0; i < d.size(); i++) begin
            fwvip_uart_char t;
            env.m_rx.get(t);
            check(t.data == d[i], $sformatf("get() %0d: 0x%02h, want 0x%02h", i, t.data, d[i]));
        end
    endtask
endclass
