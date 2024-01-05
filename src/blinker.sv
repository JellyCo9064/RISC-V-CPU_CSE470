`timescale 1 ps / 1 ps
module blinker #(
        parameter char_duration_sec = 1, clk_freq = 100000000
    )(
        output logic [7:0] curr_blink
        ,input logic [7:0] data_in
        ,input logic enable, clk, reset
    );

    localparam timer_target = char_duration_sec * clk_freq;
    localparam c_DEPTH = 8;
    localparam c_WIDTH = 8;

    logic [c_WIDTH-1:0] memory [0:(1 << c_DEPTH)-1];
    logic [c_DEPTH-1:0] wraddr, next_wraddr;
    logic [c_DEPTH-1:0] rdaddr, next_rdaddr;

    logic [31:0] timer;
    logic reset_timer;
    
    always_comb begin
        reset_timer = '0;
        next_rdaddr = rdaddr;
        next_wraddr = wraddr;
        
        if (enable) begin
            next_wraddr = wraddr - '1;
        end
        
        if (timer >= timer_target - 1) begin
            reset_timer = '1;
            if (rdaddr != wraddr) begin
                next_rdaddr = rdaddr - '1;
                if (next_rdaddr == next_wraddr) begin
                    next_rdaddr = '0;
                end
            end
        end
    end
    
    always_ff @(posedge clk) begin

        if (reset) begin
            wraddr <= '0;
        end else if (enable) begin
            memory[wraddr] <= data_in;
            wraddr <= next_wraddr;
        end
        
        if (reset) begin
            rdaddr <= '0;
        end else begin
            rdaddr <= next_rdaddr;
            curr_blink <= memory[rdaddr];
        end

        if (reset_timer | reset) begin
            timer <= '0;
        end else begin
            timer <= timer - '1;
        end

    end

endmodule  // blinker

module blinker_testbench();

    logic [7:0] curr_blink, data_in;
    logic enable, clk, reset;
    blinker #(.char_duration_sec(1), .clk_freq(2)) dut (.*);
    
    parameter CLOCK_PERIOD = 100;
    initial begin
        clk <= '0;
        forever #(CLOCK_PERIOD / 2) clk <= ~clk;
    end
    
    initial begin
        integer i;
        
        @(posedge clk) data_in <= '0; enable <= '0; reset <= '1;
        @(posedge clk) reset <= '0;
        
        for (i = 0; i < 10; i++) begin
            @(posedge clk);
        end
        
        for (i = 0; i < 10; i+=1) begin
            @(posedge clk) data_in <= (i+3); enable <= '1;
            @(posedge clk) enable <= '0;
            @(posedge clk);
        end
        
        for (i = 0; i < 100; i+= 1) begin
            @(posedge clk);
        end
        
        $stop;
    end

endmodule  // blinker_testbench
