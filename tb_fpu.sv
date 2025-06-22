// Essa testbench testa diversos casos, para averiguar como a FPU se comporta.
`timescale 1ns/1ps
import States::*;

module FPU_tb;
    logic [31:0] op_A_in, op_B_in, data_out;
    logic        calc, clock, reset;
    State_e      state_out;

    FPU dut ( // mapeia os inputs e outputs
        .op_A_in(op_A_in),
        .op_B_in(op_B_in),
        .clock(clock),
        .reset(reset),
        .data_out(data_out),
        .state_out(state_out),
        .calc(calc)
    );

    // Clock de 100khz
    initial begin
        clock = 0;
        forever #5000 clock = ~clock;
    end

    task automatic run_test(
        input [31:0] a,
        input [31:0] b,
        input string name
    );
        begin
            op_A_in = a;
            op_B_in = b;
            calc = 1;
            #10000;
            $display("%s => A: %b | B: %b | RES: %b | STATE: %s", 
                     name, a, b, data_out, state_out.name());
            calc = 0;
            #10000;
        end
    endtask

    initial begin
        reset = 0;
        #10000 reset = 1;

        // --------- TEST CASES ----------

        // Os estados nao estao funcionando direito

        run_test(32'b0_011111_1000000000000000000000000, // 1.5
                 32'b0_100000_0100000000000000000000000, // 2.5
                 "Exata: 1.5 + 2.5");

        run_test(32'b0_100001_0000000000000000000000000, // 4.0
                 32'b1_100000_0000000000000000000000000, // -2.0
                 "Exata: 4.0 - 2.0");

        run_test(32'b0_100001_0000000000000000000000000, // 4.0
                 32'b0_000000_0000000000000000000000000, // +0.0
                 "Neutro: 4.0 + 0");

        run_test(32'b0_100001_0000000000000000000000000, // 4.0
                 32'b1_100001_0000000000000000000000000, // -4.0
                 "Identidade: 4.0 + (-4.0)");

        run_test(32'b0_100000_1011001100110011001100110, // 3.4
                 32'b0_100001_0010011001100110011001100, // 4.6
                 "Inexata: 3.4 + 4.6");

        run_test(32'b0_000001_0000000000000000000000001, // ~1e-36
                 32'b0_000001_0000000000000000000000001, // ~1e-36
                 "Underflow");

        run_test(32'b0_111110_1111111111111111111111111,
                 32'b0_111110_1111111111111111111111111,
                 "Overflow");

        run_test(32'b0_100000_0000000000000000000000000, // 2.0
                 32'b1_100001_0000000000000000000000000, // -4.0
                 "Troca sinal: 2.0 - 4.0");

        run_test(32'b1_011111_0000000000000000000000000, // -1.0
                 32'b1_100000_1000000000000000000000000, // -3.0
                 "Negativos: -1.0 + -3.0");

        run_test(32'b0_011111_0000000000000000000000000, // 1.0
                 32'b1_011111_0000000000000000000000001, // -1.0000001
                 "Cancelamento: 1 - 1.0000001");

        $stop;
    end
endmodule
