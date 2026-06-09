module m8_divisor (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       valid,
    input  logic [5:0] dividend,
    input  logic [3:0] divisor,

    output logic       done,
    output logic [5:0] quotient,
    output logic [3:0] remainder
);

    localparam ST_IDLE = 2'd0;
    localparam ST_RUN  = 2'd1;

    logic [1:0] state;

    logic [5:0] dividend_reg;
    logic [3:0] divisor_reg;

    logic [5:0] quotient_reg;
    logic [5:0] remainder_reg;

    logic [2:0] bit_index;

    logic [5:0] rem_shift;
    logic [5:0] rem_next;
    logic [5:0] quotient_next;
    logic       can_subtract;

    // ============================================================
    // Lógica combinacional de división shift-and-subtract
    // ============================================================

    always @(*) begin
        // Valor por defecto
        rem_shift     = 6'd0;
        rem_next      = 6'd0;
        quotient_next = quotient_reg;
        can_subtract  = 1'b0;

        // Baja el bit actual del dividendo hacia el residuo parcial
        rem_shift = {remainder_reg[4:0], dividend_reg[bit_index]};

        // Comparación directa y segura
        if (rem_shift >= {2'b00, divisor_reg}) begin
            can_subtract = 1'b1;
            rem_next     = rem_shift - {2'b00, divisor_reg};
        end
        else begin
            can_subtract = 1'b0;
            rem_next     = rem_shift;
        end

        quotient_next = quotient_reg;
        quotient_next[bit_index] = can_subtract;
    end

    // ============================================================
    // FSM principal
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_IDLE;

            dividend_reg  <= 6'd0;
            divisor_reg   <= 4'd0;

            quotient_reg  <= 6'd0;
            remainder_reg <= 6'd0;

            quotient      <= 6'd0;
            remainder     <= 4'd0;

            bit_index     <= 3'd0;
            done          <= 1'b0;
        end
        else begin
            done <= 1'b0;

            case (state)

                ST_IDLE: begin
                    if (valid) begin

                        // Protección división entre cero
                        if (divisor == 4'd0) begin
                            quotient  <= 6'd0;
                            remainder <= 4'd0;
                            done      <= 1'b1;
                            state     <= ST_IDLE;
                        end

                        else begin
                            dividend_reg  <= dividend;
                            divisor_reg   <= divisor;

                            quotient_reg  <= 6'd0;
                            remainder_reg <= 6'd0;

                            bit_index     <= 3'd5;
                            state         <= ST_RUN;
                        end
                    end
                end

                ST_RUN: begin
                    remainder_reg <= rem_next;
                    quotient_reg  <= quotient_next;

                    if (bit_index == 3'd0) begin
                        quotient  <= quotient_next;

                        // El residuo máximo es menor que el divisor.
                        // Como divisor es de 4 bits, el residuo cabe en 4 bits.
                        remainder <= rem_next[3:0];

                        done      <= 1'b1;
                        state     <= ST_IDLE;
                    end
                    else begin
                        bit_index <= bit_index - 1'b1;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end

            endcase
        end
    end

endmodule