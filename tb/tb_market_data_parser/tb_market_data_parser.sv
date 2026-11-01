
`timescale 1ns / 1ps

module tb_market_data_parser;

import fixed_point_pkg::*;

    // Clock and reset
    logic clk;
    logic rst_n;
    logic enable;

    // AXI-Stream inputs
    logic [63:0] s_axis_tdata;
    logic        s_axis_tvalid;
    logic        s_axis_tready;
    logic        s_axis_tlast;
    logic [7:0]  s_axis_tkeep;

    // Parsed output
    parsed_msg_t parsed_msg;
    logic        parsed_valid;

    // DUT
    market_data_parser dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .enable        (enable),
        .s_axis_tdata  (s_axis_tdata),
        .s_axis_tvalid (s_axis_tvalid),
        .s_axis_tready (s_axis_tready),
        .s_axis_tlast  (s_axis_tlast),
        .s_axis_tkeep  (s_axis_tkeep),
        .parsed_msg    (parsed_msg),
        .parsed_valid  (parsed_valid)
    );

    // 100 MHz clock: 10 ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Send one 64-bit AXI-Stream word
    task automatic send_word(input logic [63:0] data);
        begin
            @(negedge clk);
            while (!s_axis_tready)
                @(negedge clk);

            s_axis_tdata  = data;
            s_axis_tvalid = 1'b1;
            s_axis_tkeep  = 8'hFF;

            @(negedge clk);
            s_axis_tvalid = 1'b0;
            s_axis_tdata  = '0;
        end
    endtask

    // Main test
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_market_data_parser);

        // Initialize
        rst_n         = 1'b0;
        enable        = 1'b1;
        s_axis_tdata  = '0;
        s_axis_tvalid = 1'b0;
        s_axis_tlast  = 1'b0;
        s_axis_tkeep  = 8'h00;

        $display("======================================");
        $display(" Market Data Parser Testbench");
        $display("======================================");

        // Reset
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        $display("TEST 1: Reset released");

        // Message layout:
        //
        // Word 0: [msg_type][order_id bits 63:8]
        // Word 1: [order_id bits 7:0][symbol][side][price]
        // Word 2: [quantity][timestamp bits 63:32]
        // Word 3: [timestamp bits 31:0][padding]
        //
        // Expected values:
        // msg_type  = 0x41
        // order_id  = 0x123456789ABCDEF0
        // symbol_id = 0x1234
        // side      = 0x42
        // price     = 0x000186A0 (100000)
        // quantity  = 0x00000019 (25)
        // timestamp = 0x1122334455667788

        $display("TEST 2: Sending market-data message");

        send_word(64'h41123456789ABCDE);
        send_word(64'hF0123442000186A0);
        send_word(64'h0000001911223344);
        send_word(64'h5566778800000000);

        // Wait for output
        wait (parsed_valid === 1'b1);
        #1;

        $display("--------------------------------------");
        $display("Parsed message:");
        $display("msg_type  = 0x%02h", parsed_msg.msg_type);
        $display("order_id  = 0x%016h", parsed_msg.order_id);
        $display("symbol_id = 0x%04h", parsed_msg.symbol_id);
        $display("side      = 0x%02h", parsed_msg.side);
        $display("price     = 0x%08h", parsed_msg.price);
        $display("quantity  = 0x%08h", parsed_msg.quantity);
        $display("timestamp = 0x%016h", parsed_msg.timestamp);
        $display("--------------------------------------");

        // Verify each field
        if (
            parsed_msg.msg_type  !== 8'h41 ||
            parsed_msg.order_id  !== 64'h123456789ABCDEF0 ||
            parsed_msg.symbol_id !== 16'h1234 ||
            parsed_msg.side      !== 8'h42 ||
            parsed_msg.price     !== 32'h000186A0 ||
            parsed_msg.quantity  !== 32'h00000019 ||
            parsed_msg.timestamp !== 64'h1122334455667788
        ) begin
            $error("FAIL: Parsed message does not match expected values");
            $finish;
        end

        if (parsed_msg.valid !== 1'b1) begin
            $error("FAIL: parsed_msg.valid was not asserted");
            $finish;
        end

        $display("PASS: All parsed fields match expected values!");

        // Finish
        repeat (3) @(negedge clk);
        $display("Simulation completed.");
        $finish;
    end

    // Timeout protection
    initial begin
        #2000;
        $fatal(1, "FAIL: Simulation timed out");
    end

endmodule
