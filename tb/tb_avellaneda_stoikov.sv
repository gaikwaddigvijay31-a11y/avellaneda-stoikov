
`timescale 1ns/1ps

module tb_avellaneda_stoikov;

  import fixed_point_pkg::*;

  logic clk = 0;
  logic rst_n = 0;
  logic enable = 0;

  top_of_book_t tob;
  logic tob_valid = 0;

  fp_t gamma;
  fp_t kappa;
  fp_t time_remaining;

  logic fill_valid = 0;
  side_t fill_side;
  qty_t fill_qty;

  order_out_t bid_order;
  order_out_t ask_order;

  logic orders_valid;
  logic signed [31:0] current_position;
  fp_t reservation_price;
  fp_t optimal_spread;
  fp_t realized_volatility;
  logic quoting_active;

  // 100 MHz simulation clock: 10 ns period.
  always #5 clk = ~clk;

  // Device Under Test (DUT).
  avellaneda_stoikov dut (
    .clk(clk),
    .rst_n(rst_n),
    .enable(enable),
    .tob(tob),
    .tob_valid(tob_valid),
    .gamma(gamma),
    .kappa(kappa),
    .time_remaining(time_remaining),
    .fill_valid(fill_valid),
    .fill_side(fill_side),
    .fill_qty(fill_qty),
    .bid_order(bid_order),
    .ask_order(ask_order),
    .orders_valid(orders_valid),
    .current_position(current_position),
    .reservation_price(reservation_price),
    .optimal_spread(optimal_spread),
    .realized_volatility(realized_volatility),
    .quoting_active(quoting_active)
  );

  // Send one top-of-book update.
  // The DUT's stage-1 code treats mid_price as integer ticks.
  task automatic send_mid(input integer mid_ticks);
    begin
      @(negedge clk);
      tob.mid_price = mid_ticks;
      tob.valid = 1'b1;
      tob_valid = 1'b1;

      @(negedge clk);
      tob_valid = 1'b0;
    end
  endtask

  initial begin
    // Save signals for GTKWave.
    $dumpfile("waves.vcd");
    $dumpvars(0, tb_avellaneda_stoikov);

    // Initialize inputs.
    tob = '0;
    fill_side = SIDE_BID;
    fill_qty = '0;

    gamma = 32'sh00010000;          // Q16.16: 1.0
    kappa = 32'sh000A0000;          // Q16.16: 10.0
    time_remaining = 32'sh00010000; // Q16.16: 1.0

    // Test 1: Reset.
    $display("TEST 1: Reset");
    repeat (3) @(negedge clk);
    rst_n = 1'b1;
    enable = 1'b1;

    // Test 2: First market price.
    $display("TEST 2: Mid-price = 100 ticks");
    send_mid(100);
    repeat (5) @(negedge clk);

    $display("Position = %0d", current_position);
    $display("Reservation price (raw Q16.16) = %0d",
             reservation_price);
    $display("Optimal spread (raw Q16.16) = %0d",
             optimal_spread);

    // Test 3: Change the market price.
    $display("TEST 3: Mid-price = 101 ticks");
    send_mid(101);
    repeat (5) @(negedge clk);

    $display("Realized volatility (raw) = %0d",
             realized_volatility);

    // Test 4: Buy fill increases inventory.
    $display("TEST 4: BID fill of 25 units");
    @(negedge clk);
    fill_side = SIDE_BID;
    fill_qty = 25;
    fill_valid = 1'b1;

    @(negedge clk);
    fill_valid = 1'b0;

    if (current_position !== 25)
      $error("FAIL: Expected position 25, got %0d",
             current_position);
    else
      $display("PASS: Position = %0d", current_position);

    // Test 5: Sell fill decreases inventory.
    $display("TEST 5: ASK fill of 10 units");
    @(negedge clk);
    fill_side = SIDE_ASK;
    fill_qty = 10;
    fill_valid = 1'b1;

    @(negedge clk);
    fill_valid = 1'b0;

    if (current_position !== 15)
      $error("FAIL: Expected position 15, got %0d",
             current_position);
    else
      $display("PASS: Position = %0d", current_position);

    // Test 6: Disable the design.
    $display("TEST 6: Disable");
    enable = 1'b0;

    repeat (5) @(negedge clk);

    $display("Simulation finished.");
    $finish;
  end

  // Global simulation timeout.
  initial begin
    #2000;
    $fatal(1, "Simulation timeout");
  end

endmodule
