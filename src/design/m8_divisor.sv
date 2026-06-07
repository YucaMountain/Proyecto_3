module m8_divisor (
    input  logic       clk,
    input  logic       rst_n,

    // Punto 1 y 2: Recibe A (6 bits) y B (4 bits) ya en binario, y una bandera valid
    input  logic       valid,
    input  logic [5:0] dividend, // A
    input  logic [3:0] divisor,  // B

    // Punto 3: Bandera done y resultados estables
    output logic       done,
    output logic [5:0] quotient, // Q
    output logic [3:0] remainder // R (Final)
);

    localparam ST_IDLE = 2'd0;
    localparam ST_RUN  = 2'd1;

    logic [1:0] state;

    logic [5:0] dividend_reg; // A interno
    logic [3:0] divisor_reg;  // B interno
    logic [5:0] quotient_reg; // Q interno
    logic [4:0] remainder_reg;// R' interno (5 bits para permitir el shift)
    logic [2:0] bit_index;    // i (Contador del ciclo for)

    // Señales combinacionales para la resta
    logic [4:0] rem_shift;    // R temporal
    logic [4:0] rem_next;
    logic [5:0] quotient_next;
    logic       can_subtract;

    // ==============================================================================
    // LÓGICA COMBINACIONAL: Implementación del algoritmo de la "image_84dac7.png"
    // ==============================================================================
    always_comb begin
        // Algoritmo: R = {R' << 1, A_i}
        // Desplaza el residuo e introduce el bit actual del dividendo
        rem_shift = {remainder_reg[3:0], dividend_reg[bit_index]};

        // Algoritmo: D = R - B 
        // En hardware no usamos D < 0, simplemente preguntamos si R >= B (es más eficiente)
        if (rem_shift >= {1'b0, divisor_reg}) begin
            can_subtract = 1'b1;
            rem_next = rem_shift - {1'b0, divisor_reg}; // Algoritmo: else -> R' = D
        end 
        else begin
            can_subtract = 1'b0;
            rem_next = rem_shift;                       // Algoritmo: if D < 0 -> R' = R
        end

        // Algoritmo: Q_i = 1 o Q_i = 0
        quotient_next = quotient_reg;
        quotient_next[bit_index] = can_subtract;
    end

    // ==============================================================================
    // LÓGICA SECUENCIAL (Sincrónica): Control de estados y ciclo FOR
    // ==============================================================================
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
            done <= 1'b0; // La bandera done solo durará 1 ciclo de reloj

            case (state)

                // ESTADO DE ESPERA
                ST_IDLE: begin
                    if (valid) begin
                        if (divisor == 4'd0) begin // Protección División por cero
                            quotient  <= 6'd0;
                            remainder <= 4'd0;
                            done      <= 1'b1;
                            state     <= ST_IDLE;
                        end 
                        else begin
                            dividend_reg  <= dividend;
                            divisor_reg   <= divisor;
                            quotient_reg  <= 6'd0;
                            
                            // Algoritmo: R' = 0
                            remainder_reg <= 5'd0;
                            
                            // Algoritmo: for i = N-1 to 0 (Como A es de 6 bits, N=6. Iniciamos en 5)
                            bit_index     <= 3'd5; 
                            state         <= ST_RUN;
                        end
                    end
                end

                // ESTADO DE CÁLCULO (Equivalente al ciclo FOR de la imagen)
                ST_RUN: begin
                    // Algoritmo: R = R' (Se guardan los resultados temporales)
                    remainder_reg <= rem_next;
                    quotient_reg  <= quotient_next;

                    // Si ya llegamos a i = 0, terminamos el for
                    if (bit_index == 3'd0) begin
                        quotient  <= quotient_next;       // Salida final estable
                        remainder <= rem_next[3:0];       // Salida final estable
                        done      <= 1'b1;                // Levanta bandera done
                        state     <= ST_IDLE;
                    end 
                    else begin
                        // Algoritmo: Siguiente paso del ciclo for (decrementa i)
                        bit_index <= bit_index - 1'b1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule