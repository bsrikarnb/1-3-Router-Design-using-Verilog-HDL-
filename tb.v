`timescale 1ns/1ps
module tb;

reg clk, resetn, pkt_valid;
reg [7:0] data_in;
wire [7:0] data_out_0, data_out_1, data_out_2;
wire vld_out_0, vld_out_1, vld_out_2;
wire err;
wire [7:0] parity_calc;

// Instantiate DUT
router_1x3 DUT (
    .clk(clk),
    .resetn(resetn),
    .pkt_valid(pkt_valid),
    .data_in(data_in),
    .data_out_0(data_out_0),
    .data_out_1(data_out_1),
    .data_out_2(data_out_2),
    .vld_out_0(vld_out_0),
    .vld_out_1(vld_out_1),
    .vld_out_2(vld_out_2),
    .err(err),
    .parity_calc(parity_calc)
);

// Clock generation
initial clk = 0;
always #10 clk = ~clk;

// --------------------
// Task to send one packet (Header + Payload + Parity)
// --------------------
task send_packet;
    input [1:0] dest;
    input introduce_error;
    integer i;
    reg [7:0] header;
    reg [7:0] parity;
    reg [7:0] payload [0:4];
begin
    header = {6'b101010, dest};
    parity = header;

    // Generate payload bytes and compute parity
    for (i = 0; i < 5; i = i + 1) begin
        payload[i] = $random;
        parity = parity ^ payload[i];
    end

    // Introduce parity error if requested
    if (introduce_error)
        parity = ~parity;
          //parity = 8'd0;

    // Send header
    @(negedge clk);
    pkt_valid = 1'b1;
    data_in = header;
    @(negedge clk);
    
    @(negedge clk);

    // Send payload
    for (i = 0; i < 5; i = i + 1) begin
        data_in = payload[i];
        @(negedge clk);
    end

    // Send parity
    pkt_valid = 1'b0;
    data_in = parity;
    @(negedge clk);
end
endtask

// --------------------
// Main Test Sequence
// --------------------
initial begin
    resetn = 0;
    pkt_valid = 0;
    data_in = 0;
    #100 resetn = 1;
    //#100;


    send_packet( 2'd10, 1'd1);
    #60;

    
    send_packet(2'b01, 1'd0);
    #60;

    
    send_packet(2'b00, 1'd1);
    #60;
    
        send_packet( 2'd01, 1'd0);
    #60;

    
    send_packet(2'b10, 1'd0);
    #60;

    
    send_packet(2'b10, 1'd1);
    #60; //
    
        send_packet( 2'd11, 1'd0);
    #60;

    
   // send_packet(2'b01, 1'd0);
    //#60;

    
    //send_packet(2'b00, 1'd1);
    //#60;
    
    
    

    $finish;
end

endmodule