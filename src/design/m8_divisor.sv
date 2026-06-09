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
    logic [4:0] remainder_reg;
    logic [2:0] bit_index;

    logic [4:0] rem_shift;
    logic [4:0] rem_next;
    logic [5:0] quotient_next;
    logic       can_subtract;

    // LA MAGIA: Un cable de 6 bits para atrapar el "Signo Negativo"
    logic [5:0] sub_result;

    // Lógica del Algoritmo de División (Combinacional)
    always_comb begin
        rem_shift = {remainder_reg[3:0], dividend_reg[bit_index]};

        // Restamos agregando ceros a la izquierda para evitar desbordamientos
        // Si rem_shift es menor que divisor_reg, el resultado será negativo.
        sub_result = {1'b0, rem_shift} - {2'b00, divisor_reg};

        // En binario, el bit 5 (el de más a la izquierda) nos dice el signo:
        // Si el bit 5 es '0' -> Resultado es Positivo o Cero (Sí cabía el divisor)
        // Si el bit 5 es '1' -> Resultado es Negativo (No cabía el divisor)
        if (sub_result[5] == 1'b0) begin
            can_subtract = 1'b1;
            rem_next     = sub_result[4:0]; // Aceptamos la resta
        end 
        else begin
            can_subtract = 1'b0;
            rem_next     = rem_shift;       // Descartamos la resta, nos quedamos igual
        end

        quotient_next = quotient_reg;
        quotient_next[bit_index] = can_subtract;
    end

    // Máquina de Estados (Secuencial)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_IDLE;
            dividend_reg  <= 6'd0;
            divisor_reg   <= 4'd0;
            quotient_reg  <= 6'd0;
            remainder_reg <= 5'd0;
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
                            remainder_reg <= 5'd0;
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