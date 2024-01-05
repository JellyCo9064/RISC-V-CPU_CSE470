module fifo_memory #(
    parameter c_DEPTH = 8, c_WIDTH = 8
    )(
    input clk,
    input reset,
    input wren,
    input rden,
    input  [c_WIDTH-1:0] data_in,
    output [c_WIDTH-1:0] data_out, data_out_peek,
    output reg [7:0] size,
    output reg fifo_full,
    output reg fifo_empty,
    output reg fifo_overflow,
    output reg fifo_underflow
    );

    reg [c_WIDTH-1:0] memory [0:(1 << c_DEPTH)-1];
    reg [c_DEPTH-1:0]  wraddr = 0;
    reg [c_DEPTH-1:0]  rdaddr = 0;
    reg [c_WIDTH-1:0] r_Data_Out, r_data_out_peek;

    // Writing to FIFO
    always @(posedge clk) begin
        size <= (wraddr - rdaddr);
    
        if (reset) begin
            wraddr <= 8'b0;
        end else if (wren) begin
            memory[wraddr] <= data_in;

            // Incrementing wraddr pointer
            if ((!fifo_full) || (rden)) begin
                wraddr <= wraddr + 1'b1;
                fifo_overflow <= 1'b0;
            end
            else
                fifo_overflow <= 1'b1;
        end
    end

    // Reading from FIFO
    always @(posedge clk) begin
        r_data_out_peek <= memory[rdaddr];
    
        if (reset) begin
            rdaddr <= 8'b0;
        end 
        else if (rden) begin
            r_Data_Out <= memory[rdaddr];

            // Incrementing raddr pointer
            if (!fifo_empty) begin
                rdaddr <= rdaddr + 1'b1;
                fifo_underflow <= 1'b0;
            end
else
                fifo_underflow <= 1'b1;
        end
    end
    assign data_out_peek = r_data_out_peek;
    assign data_out = r_Data_Out;

    // Calculating full/empty flags, referenced from zipcpu.com
    wire	[c_DEPTH-1:0]	dblnext, nxtread;
    assign	dblnext = wraddr + 2;
    assign	nxtread = rdaddr + 1'b1;

    always @(posedge clk)
    
        // clk case
        if (reset)
        begin
            // clk output flags
            fifo_full <= 1'b0;
            fifo_empty <= 1'b1;
            
        end else casez({ wren, rden, !fifo_full, !fifo_empty })
        4'b01?1: begin	// A successful read
            fifo_full  <= 1'b0;
            fifo_empty <= (nxtread == wraddr);
        end
        4'b101?: begin	// A successful write
            fifo_full <= (dblnext == rdaddr);
            fifo_empty <= 1'b0;
        end
        4'b11?0: begin	// Successful write, failed read
            fifo_full  <= 1'b0;
            fifo_empty <= 1'b0;
        end
        4'b11?1: begin	// Successful read and write
            fifo_full  <= fifo_full;
            fifo_empty <= 1'b0;
        end
        default: begin end
        endcase
    
endmodule
