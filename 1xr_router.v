`timescale 1ns/1ps
module router_1x3 (
    input  wire        clk,
    input  wire        resetn,
    input  wire        pkt_valid,
    input  wire [7:0]  data_in,
    output reg  [7:0]  data_out_0,
    output reg  [7:0]  data_out_1,
    output reg  [7:0]  data_out_2,
    output reg         vld_out_0,
    output reg         vld_out_1,
    output reg         vld_out_2,
    output reg         err,
    output reg  [7:0]  parity_calc
);

    // FSM State Encoding
    parameter IDLE   = 2'b00,
              HEADER = 2'b01,
              DATA   = 2'b10,
              PARITY = 2'b11;

    reg [1:0] current_state, next_state;
    reg [1:0] dest;
    reg [7:0] parity_recv;
    reg       parity_ready;

    // --------------------------------
    // Sequential State Update
    // --------------------------------
    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // --------------------------------
    // Next-State Logic
    // --------------------------------
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE:   if (pkt_valid) next_state = HEADER;
            HEADER: next_state = DATA;
            DATA:   if (!pkt_valid) next_state = PARITY;
            PARITY: next_state = IDLE;
        endcase
    end

    // --------------------------------
    // Parity Ready Toggle
    // --------------------------------
    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            parity_ready <= 1'b0;
        else if (current_state == PARITY)
            parity_ready <= ~parity_ready;
        else
            parity_ready <= 1'b0;
    end

    // --------------------------------
    // Main FSM Logic
    // --------------------------------
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            dest <= 2'b00;
            parity_calc <= 8'd0;
            parity_recv <= 8'd0;
            err <= 1'b0;
            data_out_0 <= 8'd0;
            data_out_1 <= 8'd0;
            data_out_2 <= 8'd0;
            {vld_out_0, vld_out_1, vld_out_2} <= 3'b000;
        end
        else begin
            case (current_state)

                // -----------------
                // IDLE
                // -----------------
                IDLE: begin
                    data_out_0 <= 8'd0;
                    data_out_1 <= 8'd0;
                    data_out_2 <= 8'd0;
                    {vld_out_0, vld_out_1, vld_out_2} <= 3'b000;
                    parity_calc <= 8'd0;
                    parity_recv <= 8'd0;
                    err <= 1'b0;
                end

                // -----------------
                // HEADER
                // -----------------
                HEADER: begin
                    dest <= data_in[1:0];   // destination field
                    parity_calc <= data_in; // start parity
                    {vld_out_0, vld_out_1, vld_out_2} <= 3'b000;
                end

                // -----------------
                // DATA
                // -----------------
                DATA: begin
                    if (pkt_valid) begin
                        // Update parity only while valid data
                        parity_calc <= parity_calc ^ data_in;

                        // Route to correct output port
                        case (dest)
                            2'b00: begin
                                data_out_0 <= data_in;
                                {vld_out_0, vld_out_1, vld_out_2} <= 3'b100;
                            end
                            2'b01: begin
                                data_out_1 <= data_in;
                                {vld_out_0, vld_out_1, vld_out_2} <= 3'b010;
                            end
                            2'b10: begin
                                data_out_2 <= data_in;
                                {vld_out_0, vld_out_1, vld_out_2} <= 3'b001;
                            end
                            default: {vld_out_0, vld_out_1, vld_out_2} <= 3'b000;
                        endcase
                    end 
                    else begin
                        // When pkt_valid = 0 ? clear output immediately
                        data_out_0 <= 8'd0;
                        data_out_1 <= 8'd0;
                        data_out_2 <= 8'd0;
                        {vld_out_0, vld_out_1, vld_out_2} <= 3'b000;
                    end
                end

                // -----------------
                // PARITY
                // -----------------
                PARITY: begin
                    // Outputs remain cleared
                    data_out_0 <= 8'd0;
                    data_out_1 <= 8'd0;
                    data_out_2 <= 8'd0;
                    {vld_out_0, vld_out_1, vld_out_2} <= 3'b000;

                    // Capture and compare parity
                    if (!parity_ready)
                        parity_recv <= data_in;

                    if (parity_calc == data_in)
                        err <= 1'b0;
                    else
                        err <= 1'b1;
                end

            endcase
        end
    end

endmodule