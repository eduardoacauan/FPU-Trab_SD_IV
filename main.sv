import States::*;

module FPU (
   input  logic  [31:0]  op_A_in,
   input  logic  [31:0]  op_B_in,
   input  logic          clock,
   output logic  [31:0]  data_out,
   output State_e        state_out,
   input  logic          reset,
   input  logic          calc
);

logic [31:0] result_reg;
logic [5:0]  expResultado;
logic        inexact_flag, overflow_flag, underflow_flag;

localparam int BIAS = 31;

// ===================== FUNÇÃO SOMA =====================
function automatic bit [31:0] Sum(input bit [31:0] a, b,
                                  output bit inexact,
                                  output bit overflow,
                                  output bit underflow);
    bit sign = a[31];
    int signed expA_real = a[30:25] - BIAS;
    int signed expB_real = b[30:25] - BIAS;
    int signed final_exp_real;
    int diff;
    bit [26:0] mantA, mantB, mantRes;

    inexact = 0;
    overflow = 0;
    underflow = 0;

    mantA = (a[30:25] == 0) ? {1'b0, a[24:0]} : {1'b1, a[24:0]};
    mantB = (b[30:25] == 0) ? {1'b0, b[24:0]} : {1'b1, b[24:0]};

    if (expA_real > expB_real) begin
        diff = expA_real - expB_real;
        final_exp_real = expA_real;
        if (diff > 26) begin
            mantB = 0;
            inexact = 1;
        end else begin
            for (int i = 0; i < diff; i++) if (mantB[i]) inexact = 1;
            mantB = mantB >> diff;
        end
    end else begin
        diff = expB_real - expA_real;
        final_exp_real = expB_real;
        if (diff > 26) begin
            mantA = 0;
            inexact = 1;
        end else begin
            for (int i = 0; i < diff; i++) if (mantA[i]) inexact = 1;
            mantA = mantA >> diff;
        end
    end

    mantRes = mantA + mantB;

    if (mantRes[26]) begin
        inexact |= mantRes[0];
        mantRes = mantRes >> 1;
        final_exp_real += 1;
    end else begin
        while (mantRes[25] == 0 && final_exp_real > -BIAS) begin
            mantRes = mantRes << 1;
            final_exp_real -= 1;
        end
    end

    if (final_exp_real + BIAS >= 64) begin
        overflow = 1;
        return {sign, 6'b111111, 25'b0};
    end
    if (final_exp_real + BIAS <= 0) begin
        underflow = 1;
        return {sign, 6'b000000, 25'b0};
    end

    return {sign, final_exp_real[5:0] + BIAS, mantRes[24:0]};
endfunction

// ===================== FUNÇÃO SUBTRAÇÃO =====================
function automatic bit [31:0] Sub(input bit [31:0] a, b,
                                  output bit inexact,
                                  output bit overflow,
                                  output bit underflow);
    bit signA = a[31], signB = b[31];
    bit [5:0] expA = a[30:25], expB = b[30:25];
    int signed expA_real = expA - BIAS;
    int signed expB_real = expB - BIAS;
    int signed expRes_real;
    bit [25:0] mantA, mantB, mantRes;
    bit signRes;
    int shift, zeros;

    inexact = 0;
    overflow = 0;
    underflow = 0;

    mantA = (expA == 0) ? {1'b0, a[24:0]} : {1'b1, a[24:0]};
    mantB = (expB == 0) ? {1'b0, b[24:0]} : {1'b1, b[24:0]};

    if (expA_real > expB_real) begin
        shift = expA_real - expB_real;
        expRes_real = expA_real;
        if (shift > 26) begin
            mantB = 0;
            inexact = 1;
        end else begin
            for (int i = 0; i < shift; i++) if (mantB[i]) inexact = 1;
            mantB >>= shift;
        end
        signRes = signA;
    end else begin
        shift = expB_real - expA_real;
        expRes_real = expB_real;
        if (shift > 26) begin
            mantA = 0;
            inexact = 1;
        end else begin
            for (int i = 0; i < shift; i++) if (mantA[i]) inexact = 1;
            mantA >>= shift;
        end
        signRes = ~signB;
    end

    if (mantA >= mantB) begin
        mantRes = mantA - mantB;
    end else begin
        mantRes = mantB - mantA;
        signRes = ~signRes;
    end

    if (mantRes == 0) return 32'b0;

    zeros = 0;
    for (int i = 25; i >= 0; i--) begin
        if (mantRes[i]) break;
        zeros++;
    end

    mantRes <<= zeros;
    expRes_real -= zeros;
    if (zeros > 0) inexact = 1;

    if (expRes_real + BIAS >= 64) begin
        overflow = 1;
        return {signRes, 6'b111111, 25'b0};
    end
    if (expRes_real + BIAS <= 0) begin
        underflow = 1;
        return {signRes, 6'b000000, 25'b0};
    end

    return {signRes, expRes_real[5:0] + BIAS, mantRes[24:0]};
endfunction

// ===================== CONTROLADOR =====================
always_ff @(posedge clock) begin
    if (!reset) begin
        data_out   <= 32'b0;
        state_out  <= EXACT;
    end else if (calc) begin
        if (op_A_in[31] == op_B_in[31]) begin
            result_reg = Sum(op_A_in, op_B_in, inexact_flag, overflow_flag, underflow_flag);
        end else begin
            result_reg = Sub(op_A_in, op_B_in, inexact_flag, overflow_flag, underflow_flag);
        end

        data_out <= result_reg;

        if (overflow_flag)
            state_out <= OVERFLOW;
        else if (underflow_flag)
            state_out <= UNDERFLOW;
        else if (inexact_flag)
            state_out <= INEXACT;
        else
            state_out <= EXACT;
    end
end

endmodule

