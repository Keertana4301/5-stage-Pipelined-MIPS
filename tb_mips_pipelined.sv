`timescale 1ns/1ps

module tb_mips_pipelined;

    logic clk;
    logic rst;

    int   errors = 0;
    int   checks = 0;

    mips_pipelined_top dut(
        .clk(clk),
        .rst(rst)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic check_reg(input int idx, input logic [31:0] expected, input string name);
        checks++;
        if (dut.REGFILE.reg_array[idx] !== expected) begin
            errors++;
            $display("[FAIL] %-4s (reg %0d) = %0d (0x%08h), expected %0d (0x%08h)",
                       name, idx, dut.REGFILE.reg_array[idx], dut.REGFILE.reg_array[idx],
                       expected, expected);
        end else begin
            $display("[PASS] %-4s (reg %0d) = %0d", name, idx, dut.REGFILE.reg_array[idx]);
        end
    endtask

    task automatic check_mem(input int word_idx, input logic [31:0] expected, input string name);
        checks++;
        if (dut.DMEM.ram[word_idx] !== expected) begin
            errors++;
            $display("[FAIL] %-10s (mem[%0d]) = %0d, expected %0d",
                       name, word_idx, dut.DMEM.ram[word_idx], expected);
        end else begin
            $display("[PASS] %-10s (mem[%0d]) = %0d", name, word_idx, dut.DMEM.ram[word_idx]);
        end
    endtask

    initial begin
        $display("==============================================");
        $display(" Pipelined MIPS Testbench");
        $display("==============================================");

        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;

        repeat (80) @(posedge clk);

        $display("----------------------------------------------");
        $display(" Checking architectural register state");
        $display("----------------------------------------------");
        check_reg(1,  32'd5,   "$1");
        check_reg(2,  32'd10,  "$2");
        check_reg(3,  32'd15,  "$3");
        check_reg(4,  32'd15,  "$4");
        check_reg(5,  32'd20,  "$5");
        check_reg(6,  32'd0,   "$6");
        check_reg(7,  32'd0,   "$7");
        check_reg(8,  32'd42,  "$8");
        check_reg(9,  32'd0,   "$9");
        check_reg(10, 32'd55,  "$10");
        check_reg(11, 32'd111, "$11");

        $display("----------------------------------------------");
        $display(" Checking data memory state");
        $display("----------------------------------------------");
        check_mem(0, 32'd15, "mem[0]");

        $display("==============================================");
        if (errors == 0)
            $display(" RESULT: ALL %0d CHECKS PASSED", checks);
        else
            $display(" RESULT: %0d / %0d CHECKS FAILED", errors, checks);
        $display("==============================================");

        $finish;
    end

    initial begin
        #2000;
        $display("[TIMEOUT] Simulation did not finish in time");
        $finish;
    end

endmodule
