module m7_calculadora (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [3:0]  key_code,
    input  logic        key_valid,
    input  logic [15:0] current_display,

    // Señales que vienen de la unidad de división
    input  logic        div_done,
    input  logic [5:0]  div_quotient,
    input  logic [3:0]  div_remainder,

    // Señales hacia la unidad de división
    output logic        div_valid,
    output logic [5:0]  dividend_A,
    output logic [3:0]  divisor_B,

    // Señales hacia m4_display_controller
    output logic        m4_clear,
    output logic        m4_load,
    output logic [15:0] m4_result_data
);

    // Códigos del teclado
    localparam KEY_A     = 4'hA;
    localparam KEY_B     = 4'hB;
    localparam KEY_C     = 4'hC;
    localparam KEY_D     = 4'hD;
    localparam KEY_STAR  = 4'hE; // *
    localparam KEY_HASH  = 4'hF; // #

    // Estados
    localparam ST_IDLE        = 3'd0;
    localparam ST_START_DIV   = 3'd1;
    localparam ST_WAIT_DONE   = 3'd2;
    localparam ST_SELECT_RES  = 3'd3;
    localparam ST_BCD_HUND    = 3'd4;
    localparam ST_BCD_TENS    = 3'd5;
    localparam ST_LOAD_RESULT = 3'd6;

    logic [2:0] state;

    // Registros internos para almacenar dividendo y divisor
    logic [5:0] reg_A;
    logic [3:0] reg_B;

    // 0 = mostrar cociente, 1 = mostrar residuo
    logic show_remainder;

    // Valor numérico leído desde la pantalla
    logic [10:0] val_en_pantalla;

    // Resultado seleccionado para mostrar
    logic [7:0] result_to_show;
    logic [7:0] temp_val;

    // Dígitos BCD
    logic [3:0] b3;
    logic [3:0] b2;
    logic [3:0] b1;
    logic [3:0] b0;

    // Conversión de la pantalla actual a número binario.
    // Se conserva el orden usado en el Proyecto II.
    assign val_en_pantalla =
        ((current_display[7:4]   < 10) ? {7'd0, current_display[7:4]}   : 11'd0) * 11'd100 +
        ((current_display[11:8]  < 10) ? {7'd0, current_display[11:8]}  : 11'd0) * 11'd10  +
        ((current_display[15:12] < 10) ? {7'd0, current_display[15:12]} : 11'd0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_A          <= 6'd0;
            reg_B          <= 4'd0;

            dividend_A     <= 6'd0;
            divisor_B      <= 4'd0;
            div_valid      <= 1'b0;

            m4_clear       <= 1'b0;
            m4_load        <= 1'b0;
            m4_result_data <= 16'hCCCC;

            show_remainder <= 1'b0;

            result_to_show <= 8'd0;
            temp_val       <= 8'd0;

            b3 <= 4'hC;
            b2 <= 4'hC;
            b1 <= 4'hC;
            b0 <= 4'hC;

            state <= ST_IDLE;
        end 
        else begin
            // Pulsos por defecto
            m4_clear  <= 1'b0;
            m4_load   <= 1'b0;
            div_valid <= 1'b0;

            case (state)

                // ----------------------------------------------------
                // Estado principal: espera teclas de control
                // ----------------------------------------------------
                ST_IDLE: begin
                    if (key_valid) begin

                        // A: guardar valor en pantalla como dividendo
                        if (key_code == KEY_A) begin
                            if (val_en_pantalla <= 11'd63) begin
                                reg_A      <= val_en_pantalla[5:0];
                                dividend_A <= val_en_pantalla[5:0];
                            end

                            m4_clear <= 1'b1;
                        end

                        // B: guardar valor en pantalla como divisor
                        else if (key_code == KEY_B) begin
                            if (val_en_pantalla <= 11'd15) begin
                                reg_B     <= val_en_pantalla[3:0];
                                divisor_B <= val_en_pantalla[3:0];
                            end

                            m4_clear <= 1'b1;
                        end

                        // C: borrar operación completa
                        else if (key_code == KEY_C) begin
                            reg_A          <= 6'd0;
                            reg_B          <= 4'd0;
                            dividend_A     <= 6'd0;
                            divisor_B      <= 4'd0;
                            show_remainder <= 1'b0;

                            m4_clear <= 1'b1;
                        end

                        // D: ejecutar división
                        else if (key_code == KEY_D) begin
                            state <= ST_START_DIV;
                        end

                        // *: mostrar cociente
                        else if (key_code == KEY_STAR) begin
                            show_remainder <= 1'b0;
                            state <= ST_SELECT_RES;
                        end

                        // #: mostrar residuo
                        else if (key_code == KEY_HASH) begin
                            show_remainder <= 1'b1;
                            state <= ST_SELECT_RES;
                        end
                    end
                end

                // ----------------------------------------------------
                // Iniciar división
                // ----------------------------------------------------
                ST_START_DIV: begin
                    dividend_A <= reg_A;
                    divisor_B  <= reg_B;

                    // División entre cero
                    if (reg_B == 4'd0) begin
                        // CEEE puede interpretarse como "EEE" con primer dígito apagado.
                        // Depende de que el driver de 7 segmentos tenga definido E.
                        m4_result_data <= 16'hCEEE;
                        m4_load        <= 1'b1;
                        state          <= ST_IDLE;
                    end
                    else begin
                        div_valid <= 1'b1;
                        state     <= ST_WAIT_DONE;
                    end
                end

                // ----------------------------------------------------
                // Esperar resultado estable del divisor
                // ----------------------------------------------------
                ST_WAIT_DONE: begin
                    if (div_done) begin
                        state <= ST_SELECT_RES;
                    end
                end

                // ----------------------------------------------------
                // Seleccionar cociente o residuo
                // ----------------------------------------------------
                ST_SELECT_RES: begin
                    if (show_remainder) begin
                        result_to_show <= {4'd0, div_remainder};
                    end
                    else begin
                        result_to_show <= {2'd0, div_quotient};
                    end

                    state <= ST_BCD_HUND;
                end

                // ----------------------------------------------------
                // Conversión simple a BCD: centenas
                // Para este proyecto el resultado máximo es pequeño,
                // pero se deja soporte hasta 3 dígitos.
                // ----------------------------------------------------
                ST_BCD_HUND: begin
                    b3 <= 4'hC;

                    if (result_to_show >= 8'd100) begin
                        b2       <= result_to_show / 8'd100;
                        temp_val <= result_to_show % 8'd100;
                    end
                    else begin
                        b2       <= 4'hC;
                        temp_val <= result_to_show;
                    end

                    state <= ST_BCD_TENS;
                end

                // ----------------------------------------------------
                // Conversión simple a BCD: decenas y unidades
                // ----------------------------------------------------
                ST_BCD_TENS: begin
                    if (temp_val >= 8'd10) begin
                        b1 <= temp_val / 8'd10;
                        b0 <= temp_val % 8'd10;
                    end
                    else begin
                        b1 <= 4'hC;
                        b0 <= temp_val[3:0];
                    end

                    state <= ST_LOAD_RESULT;
                end

                // ----------------------------------------------------
                // Cargar resultado al display controller
                // ----------------------------------------------------
                ST_LOAD_RESULT: begin
                    m4_result_data <= {b0, b1, b2, b3};
                    m4_load        <= 1'b1;
                    state          <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                end

            endcase
        end
    end

endmodule
