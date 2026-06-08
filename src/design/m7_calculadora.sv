module m7_calculadora (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [3:0]  key_code,
    input  logic        key_valid,
    input  logic [15:0] current_display,

    // Salidas hacia el controlador de pantalla (m4)
    output logic        m4_clear,
    output logic        m4_load,
    output logic [15:0] m4_result_data,

    // Comunicación con el divisor (m8) - Conectados en el Top Module
    output logic        div_valid,
    output logic [5:0]  dividend_out,
    output logic [3:0]  divisor_out,
    input  logic        div_done,
    input  logic [5:0]  quotient_in,
    input  logic [3:0]  remainder_in
);

    // ------------------------------------------------------------
    // Registros internos con los límites solicitados
    // ------------------------------------------------------------
    logic [5:0] reg_A; // Dividendo: Max 6 bits (63)
    logic [3:0] reg_B; // Divisor:   Max 4 bits (15)

    // Máquina de estados
    localparam ST_IDLE       = 3'd0;
    localparam ST_START_DIV  = 3'd1;
    localparam ST_WAIT_DONE  = 3'd2;
    localparam ST_BCD_CONV   = 3'd3;
    localparam ST_LOAD_RES   = 3'd4;

    logic [2:0] state;
    
    // Variables de conversión BCD
    logic [5:0] temp_val;
    logic [3:0] b1, b0;

    // ------------------------------------------------------------
    // FÓRMULA BLINDADA: Conversión de Pantalla (BCD) a Binario
    // Usamos 14 bits para evitar cualquier desbordamiento matemático
    // ------------------------------------------------------------
    logic [13:0] d3, d2, d1, d0;
    logic [13:0] val_en_pantalla;

    always_comb begin
        // Extraemos cada dígito y lo convertimos a 0 si no es un número válido (0-9)
        d3 = (current_display[15:12] < 10) ? {10'd0, current_display[15:12]} : 14'd0;
        d2 = (current_display[11:8]  < 10) ? {10'd0, current_display[11:8]}  : 14'd0;
        d1 = (current_display[7:4]   < 10) ? {10'd0, current_display[7:4]}   : 14'd0;
        d0 = (current_display[3:0]   < 10) ? {10'd0, current_display[3:0]}   : 14'd0;

        // Suma final asegurada a 14 bits
        val_en_pantalla = (d3 * 14'd1000) + (d2 * 14'd100) + (d1 * 14'd10) + d0;
    end

    // ------------------------------------------------------------
    // Lógica del cerebro (FSM)
    // ------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_A          <= 6'd0;
            reg_B          <= 4'd0;
            m4_clear       <= 1'b0;
            m4_load        <= 1'b0;
            m4_result_data <= 16'hCCCC;
            div_valid      <= 1'b0;
            dividend_out   <= 6'd0;
            divisor_out    <= 4'd0;
            state          <= ST_IDLE;
        end else begin
            // Valores por defecto para evitar latches o comandos repetidos
            m4_clear  <= 1'b0;
            m4_load   <= 1'b0;
            div_valid <= 1'b0;

            case (state)
                // Espera de comandos
                ST_IDLE: begin
                    if (key_valid) begin
                        
                        // Tecla A: Guardar Dividendo
                        if (key_code == 4'hA) begin
                            if (val_en_pantalla <= 14'd63) begin 
                                reg_A    <= val_en_pantalla[5:0]; 
                                m4_clear <= 1'b1; 
                            end else begin
                                // ¡DIAGNÓSTICO! Si es mayor a 63, muestra "EEE"
                                m4_result_data <= 16'hCEEE; 
                                m4_load        <= 1'b1;
                            end
                        end
                        
                        // Tecla B: Guardar Divisor
                        else if (key_code == 4'hB) begin
                            if (val_en_pantalla <= 14'd15) begin 
                                reg_B    <= val_en_pantalla[3:0]; 
                                m4_clear <= 1'b1; 
                            end else begin
                                // ¡DIAGNÓSTICO! Si es mayor a 15, muestra "EEE"
                                m4_result_data <= 16'hCEEE; 
                                m4_load        <= 1'b1;
                            end
                        end
                        
                        // Tecla C: Borrar todo
                        else if (key_code == 4'hC) begin 
                            reg_A    <= 6'd0; 
                            reg_B    <= 4'd0; 
                            m4_clear <= 1'b1; 
                        end
                        
                        // Tecla D: Dividir
                        else if (key_code == 4'hD) begin 
                            state <= ST_START_DIV; 
                        end
                    end
                end

                // Iniciar Coprocesador Matemático m8
                ST_START_DIV: begin
                    if (reg_B == 4'd0) begin // Protección división por cero
                        m4_result_data <= 16'hCEEE; 
                        m4_load        <= 1'b1;
                        state          <= ST_IDLE;
                    end else begin
                        dividend_out <= reg_A;
                        divisor_out  <= reg_B;
                        div_valid    <= 1'b1;
                        state        <= ST_WAIT_DONE;
                    end
                end

                // Esperar resultado de m8
                ST_WAIT_DONE: begin
                    if (div_done) begin
                        temp_val <= quotient_in;
                        state    <= ST_BCD_CONV;
                    end
                end

                // Conversión BCD simple para 2 dígitos (Cociente máximo 63)
                ST_BCD_CONV: begin
                    if      (temp_val >= 6'd60) begin b1 <= 4'd6; b0 <= temp_val - 6'd60; end
                    else if (temp_val >= 6'd50) begin b1 <= 4'd5; b0 <= temp_val - 6'd50; end
                    else if (temp_val >= 6'd40) begin b1 <= 4'd4; b0 <= temp_val - 6'd40; end
                    else if (temp_val >= 6'd30) begin b1 <= 4'd3; b0 <= temp_val - 6'd30; end
                    else if (temp_val >= 6'd20) begin b1 <= 4'd2; b0 <= temp_val - 6'd20; end
                    else if (temp_val >= 6'd10) begin b1 <= 4'd1; b0 <= temp_val - 6'd10; end
                    else                        begin b1 <= 4'hC; b0 <= temp_val[3:0]; end // 4'hC = Espacio
                    state <= ST_LOAD_RES;
                end

                // Cargar resultado a pantalla
                ST_LOAD_RES: begin
                    m4_result_data <= {4'hC, 4'hC, b1, b0};
                    m4_load        <= 1'b1;
                    state          <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule