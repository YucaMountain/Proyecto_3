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

    // Estados internos
    localparam ST_IDLE = 2'd0;
    localparam ST_RUN  = 2'd1;

    logic [1:0] state;

    // Registros internos para la operación
    logic [5:0] dividend_reg;
    logic [3:0] divisor_reg;
    logic [5:0] quotient_reg;
    logic [4:0] remainder_reg;
    logic [2:0] bit_index;

    // Señales combinacionales
    logic [4:0] rem_shift;
    logic [4:0] rem_next;
    logic [5:0] quotient_next;
    logic       can_subtract;

    // ------------------------------------------------------------------
    // Bloque Combinacional: Lógica de resta iterativa (Shift-and-Subtract)
    // ------------------------------------------------------------------
    always_comb begin
        // Desplaza el residuo temporal 1 bit a la izquierda y baja el bit actual del dividendo
        rem_shift = {remainder_reg[3:0], dividend_reg[bit_index]};

        // Compara si el divisor cabe en el residuo temporal
        if (rem_shift >= {1'b0, divisor_reg}) begin
            can_subtract = 1'b1;
            rem_next = rem_shift - {1'b0, divisor_reg}; // Se realiza la resta
        end 
        else begin
            can_subtract = 1'b0;
            rem_next = rem_shift;                       // Se mantiene igual
        end

        // Actualiza el bit correspondiente en el cociente temporal
        quotient_next = quotient_reg;
        quotient_next[bit_index] = can_subtract;
    end

    // ------------------------------------------------------------------
    // Bloque Secuencial: Control de la Máquina de Estados
    // ------------------------------------------------------------------
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
            done <= 1'b0; // Pulso por defecto, solo dura 1 ciclo cuando termina

            case (state)
                ST_IDLE: begin
                    if (valid) begin
                        // Protección contra división por cero (Requerido por el Testbench)
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
                            bit_index     <= 3'd5; // N-1 (Empezamos desde el bit 5)
                            state         <= ST_RUN;
                        end
                    end
                end

                ST_RUN: begin
                    // Guardamos los valores de la lógica combinacional
                    remainder_reg <= rem_next;
                    quotient_reg  <= quotient_next;

                    if (bit_index == 3'd0) begin
                        // Terminamos el último bit, publicamos resultados
                        quotient  <= quotient_next;
                        remainder <= rem_next[3:0];
                        done      <= 1'b1;
                        state     <= ST_IDLE;
                    end 
                    else begin
                        // Pasamos al siguiente bit
                        bit_index <= bit_index - 1'b1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
