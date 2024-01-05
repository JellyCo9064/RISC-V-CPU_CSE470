
// 
// Module: impl_top
// 
// Notes:
// - Top level module to be used in an implementation.
// - To be used in conjunction with the constraints/defaults.xdc file.
// - Ports can be (un)commented depending on whether they are being used.
// - The constraints file contains a complete list of the available ports
//   including the chipkit/Arduino pins.
//

module uart #(
        parameter uart_clk_freq = 100000000, baud = 9600
    )(
        output logic uart_txd, zero
        ,output logic [7:0] size
        ,input logic clk, reset, uart_rxd, uart_txd_enable
        ,input logic [7:0] uart_txd_data
    );
    
    logic RxD_data_ready;
    logic [7:0] RxD_data, fifo_peek, fifo_data_out, fifo_data_in;
    logic TxD_busy, TxD_start, TxD_start_next;
    logic fifo_full, fifo_empty, fifo_pop, fifo_pop_next, pop_ready, pop_ready_next, fifo_wren;

    fifo_memory fm (
        .clk(clk)
        ,.reset(reset)
        ,.wren(fifo_wren)
        ,.rden(fifo_pop)
        ,.data_in(fifo_data_in)
        ,.data_out(fifo_data_out)
        ,.data_out_peek(fifo_peek)
        ,.fifo_full(fifo_full)
        ,.fifo_empty(fifo_empty)
        ,.fifo_overflow()
        ,.fifo_underflow()
        ,.size(size)
    );
    
    async_receiver #(.ClkFrequency(uart_clk_freq), .Baud(baud)) RX(
         .clk(clk)
        ,.RxD(uart_rxd)
        ,.RxD_data_ready(RxD_data_ready)
        ,.RxD_data(RxD_data)
        ,.RxD_idle()
        ,.RxD_endofpacket()
    );
    
    async_transmitter #(.ClkFrequency(uart_clk_freq), .Baud(baud)) TX(
        .clk(clk)
        ,.TxD(uart_txd)
        ,.TxD_start(TxD_start)
        ,.TxD_data(fifo_data_out)
        ,.TxD_busy(TxD_busy)
    );
    
    always_comb begin
        fifo_pop_next = fifo_pop;
        TxD_start_next = TxD_start;
        pop_ready_next = pop_ready;
        
        if (~TxD_busy & ~fifo_empty & ~fifo_pop & pop_ready) begin
            // Gen pulse
            fifo_pop_next = 1'b1;
            pop_ready_next = 1'b0;
        end
        
        if (fifo_pop) begin
            fifo_pop_next = 1'b0;
            TxD_start_next = 1'b1;
        end
        
        if (TxD_start & ~TxD_busy) begin
            TxD_start_next = 1'b0;
        end
        
        if (TxD_busy & ~pop_ready) begin
            pop_ready_next = 1'b1;
        end
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin
            TxD_start <= 1'b0;
            fifo_pop <= 1'b0;
            pop_ready <= 1'b1;
        end else begin 
            TxD_start <= TxD_start_next;
            fifo_pop <= fifo_pop_next;
            pop_ready <= pop_ready_next;
        end
        
        if (reset) begin
            zero <= 1'b0;
        end else if (fifo_pop & (fifo_data_out == 8'b0)) begin
            zero <= 1'b1;
        end else begin
            zero <= 1'b0;
        end
        
        if (reset) begin
            fifo_data_in <= '0;
            fifo_wren <= '0;
        end else if (uart_txd_enable) begin
            fifo_data_in <= uart_txd_data;
            fifo_wren <= '1;
        end else begin
            fifo_data_in <= '0;
            fifo_wren <= '0;
        end
    end

endmodule

`timescale 1 ps / 1 ps
module uart_testbench();

    logic uart_txd, uart_rxd, clk, reset, uart_txd_enable, zero;
    logic [7:0] uart_txd_data, size;
    
    uart #(100000000, 10000000) dut (.*);
    
    parameter CLOCK_PERIOD = 100;
    initial begin
        clk <= 0;
        forever #(CLOCK_PERIOD / 2) clk <= ~clk;
    end
    
    initial begin
        integer i;
        @(posedge clk) reset <= 1'b1;
        @(posedge clk) reset <= 1'b0;
        @(posedge clk) uart_txd_data <= 8'h42; uart_txd_enable <= 1'b1;
        @(posedge clk) uart_txd_enable <= 1'b0;
        for (i = 0; i < 150; i++) begin
            @(posedge clk);
        end
        @(posedge clk) uart_txd_data <= 8'h69; uart_txd_enable <= 1'b1;
        @(posedge clk) uart_txd_enable <= 1'b0;
        @(posedge clk) uart_txd_data <= 8'h97; uart_txd_enable <= 1'b1;
        @(posedge clk) uart_txd_enable <= 1'b0;
        @(posedge clk) uart_txd_data <= 8'h20; uart_txd_enable <= 1'b1;
        @(posedge clk) uart_txd_enable <= 1'b0;
        @(posedge clk) uart_txd_data <= 8'h88; uart_txd_enable <= 1'b1;
        @(posedge clk) uart_txd_enable <= 1'b0;
        @(posedge clk) uart_txd_data <= 8'h77; uart_txd_enable <= 1'b1;
        @(posedge clk) uart_txd_enable <= 1'b0;
        @(posedge clk) uart_txd_data <= 8'h61; uart_txd_enable <= 1'b1;
        @(posedge clk) uart_txd_enable <= 1'b0;
        @(posedge clk) uart_txd_data <= 8'h00; uart_txd_enable <= 1'b1;
        @(posedge clk) uart_txd_enable <= 1'b0;
        for (i = 0; i < 100000; i++) begin
            @(posedge clk);
        end
        
        $stop;
    end

endmodule  // uart.sv
