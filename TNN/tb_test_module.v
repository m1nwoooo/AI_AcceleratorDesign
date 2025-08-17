/***************************************************************************
 * Copyright (C) 2025 Intelligent System Architecture (ISA) Lab. All rights reserved. 
 * 
 * This file is written solely for academic use in AI Accelerator Design course assignment 
 * In School of Electrical and Electronics Engineering, Konkuk University 
 *
 * Unauthorized distribution is strictly prohibited.
 ***************************************************************************/
 
`timescale 1ns/1ns //timescale set

module tb_top ();
    reg         clk, rst, run;
    reg         batch_mode;         // 0: 8-batch, 1: 16-batch
    wire [2:0]  state;             // Accelerator state 0~5
    wire        busy;          
    
    // Memory interface signals
    wire        re_X, re_W1, re_W2, we_Y;   //mem signals
    wire [6:0]  addr_X, addr_Y;             //7bits for 16batch
    wire [5:0]  addr_W1, addr_W2;           //weight addr is 0~63
    wire [7:0]  data_X, data_W1, data_W2;   //8bits
    wire [15:0] data_Y;                     //16bits for Output Y

    // Control signals for memory access from testbench 
    reg         we_X_ext, re_Y_ext;         //write X(input), read Y(output)
    reg  [6:0]  addr_X_ext, addr_Y_ext;     //addr for access
    reg  [7:0]  din_X_ext;                  //data from accelarator mem
    
    reg         mode;               // 0: 8-batch test, 1: 16-batch test
    // Memory enable and address
    wire        en_X = we_X_ext || re_X;                    //en for both we,re
    wire        we_X = we_X_ext;                            //we triggered by external
    wire [6:0]  addr_X_mux = we_X_ext ? addr_X_ext : addr_X;//choose addr..ext?in?
    wire [7:0]  din_X = we_X_ext ? din_X_ext : 8'd0;        //choose data..ext?in?
     // Memory interface for separate result storage 
    wire        en_Y = we_Y || re_Y_ext;                    //en both for we,re
    wire        we_Y_int = we_Y && !re_Y_ext;               //we while not ext_re disabled
    wire [6:0]  addr_Y_mux = re_Y_ext ? addr_Y_ext : addr_Y;//choose addr..ext Y?in?
    wire [15:0] dout_Y;                                     //Y mem output data
    
    // Separate result memory control signals
    reg         we_mem4_ext, we_mem5_ext, re_mem4_ext, re_mem5_ext;//for output batch 8 , 16
    reg  [6:0]  addr_mem4_ext, addr_mem5_ext;//addr
    wire [15:0] dout_mem4, dout_mem5;//data

    // Reference memory control signals
    reg         re_ref8_ext, re_ref16_ext;      //read en for ref mem
    reg  [6:0]  addr_ref8_ext, addr_ref16_ext;  //addr for ref access
    wire [15:0] dout_ref8, dout_ref16;          //reference data output
    
    ///////////////////////////
            // System parameters
    parameter real CLOCK_FREQ_MHZ = 100.0;           // 100 MHz clock
    parameter real CLOCK_PERIOD_NS = 10.0;           // 10 ns period
    parameter integer SYSTOLIC_SIZE = 4;             // 4x4 systolic array
    parameter integer MAC_UNITS = 16;                // 4x4 = 16 MAC units
    parameter integer DATA_WIDTH_BITS = 8;           // 8-bit data
    parameter integer WEIGHT_WIDTH_BITS = 8;         // 8-bit weights
    parameter integer OUTPUT_WIDTH_BITS = 16;        // 16-bit output
    
    // Calculate performance metrics
    real peak_bandwidth_mbps, peak_performance_gops;
    real latency_8batch_us, latency_16batch_us;
    real utilization_8batch, utilization_16batch;
    real theoretical_cycles_8batch, theoretical_cycles_16batch;
    real cycles_per_element_8, cycles_per_element_16;
    
    ///////////////////////
    

    // Memory instantiations with firmware initialization
    // Weight is 8*8 Matrix
    // bitline: 8, bitaddr: 6
    mem_behavior #(.firmware("C:/Users/user/AILab/TinyNeuralNetWork/data/model/w1_hex.txt"), .bitline(8), .bitaddr(6), .binary(0))  
        U_mem_W1 (
            .clk(clk), .en(re_W1), .we(1'b0), 
            .addr(addr_W1), .din(8'd0), .dout(data_W1)
        );
        
    mem_behavior #(.firmware("C:/Users/user/AILab/TinyNeuralNetWork/data/model/w2_hex.txt"), .bitline(8), .bitaddr(6), .binary(0))  
        U_mem_W2 (
            .clk(clk), .en(re_W2), .we(1'b0), 
            .addr(addr_W2), .din(8'd0), .dout(data_W2)
        );

    // data_X based on mode
    wire [7:0] data_X_8batch, data_X_16batch;           
    assign data_X = (mode == 1'b0) ? data_X_8batch : data_X_16batch;
    
    // Input memory - 8-batch data
    // X for batch 8 is 8*8 Matrix
    // bitline: 8, bitaddr: 6
    mem_behavior #(.firmware("C:/Users/user/AILab/TinyNeuralNetWork/data/inout_base/x_hex.txt"), .bitline(8), .bitaddr(6), .binary(0))  
        U_mem_X_8batch (
            .clk(clk), .en(en_X), .we(we_X), 
            .addr(addr_X_mux[5:0]), .din(din_X), .dout(data_X_8batch)
        );
    
    // Input memory - 16-batch data
    // X for batch 16 is 8*16 Matrix
    // bitline: 8, bitaddr: 7
    mem_behavior #(.firmware("C:/Users/user/AILab/TinyNeuralNetWork/data/inout_extra/x_hex.txt"), .bitline(8), .bitaddr(7), .binary(0))  
        U_mem_X_16batch (
            .clk(clk), .en(en_X), .we(we_X), 
            .addr(addr_X_mux), .din(din_X), .dout(data_X_16batch)
        );
    
    // Reference memory - 8-batch expected results 
    mem_behavior #(.firmware("C:/Users/user/AILab/TinyNeuralNetWork/data/inout_base/y_hex.txt"), .bitline(16), .bitaddr(7), .binary(0))  
        U_mem_ref8 (
            .clk(clk), .en(re_ref8_ext), .we(1'b0), 
            .addr(addr_ref8_ext), .din(16'd0), .dout(dout_ref8)
        );
    
    // Reference memory - 16-batch expected results
    mem_behavior #(.firmware("C:/Users/user/AILab/TinyNeuralNetWork/data/inout_extra/y_hex.txt"), .bitline(16), .bitaddr(7), .binary(0))  
        U_mem_ref16 (
            .clk(clk), .en(re_ref16_ext), .we(1'b0), 
            .addr(addr_ref16_ext), .din(16'd0), .dout(dout_ref16)
        );
    
    // Neural Network Accelerator instantiation
    TNN _TNN (
        .clk(clk),.rst(rst),.run(run),.batch_mode(batch_mode),.state(state),.busy(busy),
        .re_X(re_X),.addr_X(addr_X),.data_X(data_X),
        .re_W1(re_W1),.addr_W1(addr_W1),.data_W1(data_W1),
        .re_W2(re_W2),.addr_W2(addr_W2),.data_W2(data_W2),
        .we_Y(we_Y),.addr_Y(addr_Y),.data_Y(data_Y)
    );
    
    // Output memory - temporary storage during computation
    // Output Y mem (temporary save)
    mem_behavior #(.firmware(""), .bitline(16), .bitaddr(7), .binary(0))  
        U_mem_Y (
            .clk(clk), .en(en_Y), .we(we_Y_int), 
            .addr(addr_Y_mux), .din(data_Y), .dout(dout_Y)
        );
    
    // mem4: 8-batch results (64 elements)
    mem_behavior #(.firmware(""), .bitline(16), .bitaddr(7), .binary(0))  
        U_mem4 (
            .clk(clk), .en(we_mem4_ext || re_mem4_ext), .we(we_mem4_ext), 
            .addr(addr_mem4_ext), .din(dout_Y), .dout(dout_mem4)
        );
    
    // mem5: 16-batch results (128 elements)
    mem_behavior #(.firmware(""), .bitline(16), .bitaddr(7), .binary(0))  
        U_mem5 (
            .clk(clk), .en(we_mem5_ext || re_mem5_ext), .we(we_mem5_ext), 
            .addr(addr_mem5_ext), .din(dout_Y), .dout(dout_mem5)
        );
    

    always #5 clk <= ~clk;    // Clock generation
    
    // Task to copy results from temp memory to dedicated result memory
    task copy_results_to_memory;
        input [31:0] batch_size;
        input [31:0] dest_mem;  // 4: mem4, 5: mem5
        integer i;
        integer total_elements;
        begin
            total_elements = batch_size * 8;//for control loop
            
            for (i = 0; i < total_elements; i = i + 1) begin
                addr_Y_ext <= i;
                re_Y_ext <= 1'b1;
                repeat(2) @(posedge clk);
                
                case (dest_mem)
                    4: begin            //store mem 4
                        addr_mem4_ext <= i;
                        we_mem4_ext <= 1'b1;//write en
                        @(posedge clk);
                        we_mem4_ext <= 1'b0;
                    end
                    5: begin            //store mem 5
                        addr_mem5_ext <= i;
                        we_mem5_ext <= 1'b1;//write en
                        @(posedge clk);
                        we_mem5_ext <= 1'b0;
                    end
                endcase
                @(posedge clk);
            end
            re_Y_ext <= 1'b0;
        end
    endtask
    
    // Task to verify results against reference
    task verify_results;
        input [31:0] batch_size;
        input [31:0] result_mem;    // 4: mem4, 5: mem5
        input [31:0] ref_mem;       // 8: ref8, 16: ref16
        input [255:0] test_name;    // Test description
        integer i;
        integer total_elements;
        integer mismatch_count;
        reg signed [15:0] result_data, ref_data;
        begin
            total_elements = batch_size * 8;    //total elements to compare
            mismatch_count = 0;                 //initialize mismatch counter
            
            $display("\n========================================");
            $display("Verification: %s", test_name);
            $display("========================================");
            $display("Comparing %d elements...", total_elements);
            
            // Enable memory read
            case (result_mem)
                4: re_mem4_ext <= 1'b1;        //enable mem4 read
                5: re_mem5_ext <= 1'b1;        //enable mem5 read
            endcase
            
            case (ref_mem)
                8: re_ref8_ext <= 1'b1;        //enable ref8 read
                16: re_ref16_ext <= 1'b1;      //enable ref16 read
            endcase
            
            for (i = 0; i < total_elements; i = i + 1) begin
                // Read result data
                case (result_mem)
                    4: begin
                        addr_mem4_ext <= i;
                        repeat(3) @(posedge clk);
                        result_data = dout_mem4;
                    end
                    5: begin
                        addr_mem5_ext <= i;
                        repeat(3) @(posedge clk);
                        result_data = dout_mem5;
                    end
                endcase
                
                // Read reference data
                case (ref_mem)
                    8: begin
                        addr_ref8_ext <= i;
                        repeat(3) @(posedge clk);
                        ref_data = dout_ref8;
                    end
                    16: begin
                        addr_ref16_ext <= i;
                        repeat(3) @(posedge clk);
                        ref_data = dout_ref16;
                    end
                endcase
                
                // Compare and report mismatches
                if (result_data !== ref_data) begin
                    $display("MISMATCH at index %d: Result=%04h (%d), Expected=%04h (%d)", 
                             i, result_data, result_data, ref_data, ref_data);
                    mismatch_count = mismatch_count + 1;    //count mismatches
                end
            end
            
            // Disable memory read
            case (result_mem)
                4: re_mem4_ext <= 1'b0;        //disable mem4 read
                5: re_mem5_ext <= 1'b0;        //disable mem5 read
            endcase
            
            case (ref_mem)
                8: re_ref8_ext <= 1'b0;        //disable ref8 read
                16: re_ref16_ext <= 1'b0;      //disable ref16 read
            endcase
            
            // Report final result
            if (mismatch_count == 0) begin
                $display("? PASS: All %d elements match perfectly!", total_elements);
            end else begin
                $display("? FAIL: %d out of %d elements do not match", mismatch_count, total_elements);
                $display("Success rate: %0d.%02d%%", 
                         ((total_elements - mismatch_count) * 100) / total_elements,
                         (((total_elements - mismatch_count) * 10000) / total_elements) % 100);
            end
            $display("========================================");
        end
    endtask
    
    // check results in display
    task display_results;
        input [31:0] batch_size;
        input [31:0] source_mem;    //src mem num,, 4 or 5
        integer i, j;
        integer total_elements;
        reg signed [15:0] result;
        begin
            total_elements = batch_size * 8;
            
            case (source_mem)
                4: re_mem4_ext <= 1'b1;
                5: re_mem5_ext <= 1'b1;
            endcase
            
            // Display results
            // batch size & sorce_mem control loop
            if (batch_size==8) $write("Batch 0~7 \n");
            else $write("Batch 0~15 \n");
            for (i = 0; i < batch_size; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    case (source_mem)
                        4: begin
                            addr_mem4_ext <= i*8 + j;
                            repeat(3) @(posedge clk);
                            result = dout_mem4;
                        end
                        5: begin
                            addr_mem5_ext <= i*8 + j;
                            repeat(3) @(posedge clk);
                            result = dout_mem5;
                        end
                    endcase
                    $write("%04h (%d) ", result,result);
                end
                $display("");
            end
            
            case (source_mem)
                4: re_mem4_ext <= 1'b0;
                5: re_mem5_ext <= 1'b0;
            endcase
        end
    endtask
    
    //run nn_model task
    task run_nn_test;
        input [31:0] batch_size;
        input [31:0] test_mode;
        input [31:0] result_mem;
        begin
            mode <= test_mode;          //set batch mode
            repeat(5) @(posedge clk);
            
            batch_mode <= (batch_size == 16) ? 1'b1 : 1'b0;
            
            @(posedge clk);
            run <= 1'b1;
            @(posedge clk);
            run <= 1'b0;
            
            @(posedge clk);
            while (busy) begin
                @(posedge clk);
            end
            
            #100;
            copy_results_to_memory(batch_size, result_mem);//copy result to mem4 or 5 
            #100;
        end
    endtask
    
    // Performance monitoring
    integer cycle_count_8, cycle_count_16;
    
    //count cycles to check performance
    always @(posedge clk) begin
        if (run && batch_mode == 1'b0)
            cycle_count_8 <= 0;
        else if (run && batch_mode == 1'b1)
            cycle_count_16 <= 0;
        else if (busy && batch_mode == 1'b0)
            cycle_count_8 <= cycle_count_8 + 1;
        else if (busy && batch_mode == 1'b1)
            cycle_count_16 <= cycle_count_16 + 1;
    end
    
    // Main test sequence
    initial begin
        // Initialize signals
        clk <= 1'b0; rst <= 1'b0; run <= 1'b0; batch_mode <= 1'b0; mode <= 1'b0;
        we_X_ext <= 1'b0; re_Y_ext <= 1'b0;
        addr_X_ext <= 7'd0; addr_Y_ext <= 7'd0;
        din_X_ext <= 8'd0;
        
        we_mem4_ext <= 1'b0; we_mem5_ext <= 1'b0;      //init result mem we
        re_mem4_ext <= 1'b0; re_mem5_ext <= 1'b0;      //init result mem re
        addr_mem4_ext <= 7'd0; addr_mem5_ext <= 7'd0;  //init result mem addr
        
        re_ref8_ext <= 1'b0; re_ref16_ext <= 1'b0;     //init ref mem re
        addr_ref8_ext <= 7'd0; addr_ref16_ext <= 7'd0; //init ref mem addr
        
        // Reset sequence
        #100;
        rst <= 1'b1;
        #100;
        rst <= 1'b0;
        #100;
        
        $display("========================================");
        $display("Neural Network Accelerator Test Results");
        $display("========================================");
        
        // Test 1: 8-batch test
        $display("\nRunning 8-batch computation...");
        run_nn_test(8, 0, 4);
        
        // Test 2: 16-batch test  
        $display("\nRunning 16-batch computation...");
        run_nn_test(16, 1, 5);
        
        // Verify results against reference
        verify_results(8, 4, 8, "8-Batch Results vs Reference");    //compare mem4 with ref8
        verify_results(16, 5, 16, "16-Batch Results vs Reference");  //compare mem5 with ref16
        
        // Display memory structure overview
        $display("\nMemory Structure Overview:");
        $display("- U_mem_X_8batch:  Input data for 8-batch  (64 elements, 8-bit)");
        $display("- U_mem_X_16batch: Input data for 16-batch (128 elements, 8-bit)");
        $display("- U_mem_W1:        Weight matrix 1 (64 elements, 8-bit)");
        $display("- U_mem_W2:        Weight matrix 2 (64 elements, 8-bit)");
        $display("- U_mem_Y:         Temporary output buffer (16-bit)");
        $display("- U_mem4:          8-batch results storage (64 elements, 16-bit)");
        $display("- U_mem5:          16-batch results storage (128 elements, 16-bit)");
        $display("- U_mem_ref8:      8-batch reference data (64 elements, 16-bit)");
        $display("- U_mem_ref16:     16-batch reference data (128 elements, 16-bit)");
        
        $display("\n8-Batch Results (mem4 - 64 elements):");
        display_results(8, 4);//batch-8
        
        $display("\n16-Batch Results (mem5 - 128 elements):");
        display_results(16, 5);//batch-16
        
        $display("\nPerformance Summary:");
        $display("8-batch:  %0d cycles (%0d.%02d cycles/element)", 
                 cycle_count_8, cycle_count_8/64, ((cycle_count_8%64)*100)/64);
        $display("16-batch: %0d cycles (%0d.%02d cycles/element)", 
                 cycle_count_16, cycle_count_16/128, ((cycle_count_16%128)*100)/128);
    end
    // Timeout watchdog
    initial begin
        #3000000;
        $display("Simulation timeout");
        $finish();
    end
    
endmodule
