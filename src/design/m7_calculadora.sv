module m7_calculadora (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [3:0]  key_code,
    input  logic        key_valid,
    input  logic [15:0] current_display,

    output logic        m4_clear,
    output logic        m4_load,
    output logic [15:0] m4_result_data,

    output logic        div_valid,
    output logic [5:0]  dividend_out,
    output logic [3:0]  divisor_out,

    input  logic        div_done,
    input  logic [5:0]  quotient_in,
    input  logic [3:0]  remainder_in
);

    localparam KEY_A    = 4'hA;
    localparam KEY_B    = 4'hB;
    localparam KEY_C    = 4'hC;
    localparam KEY_D    = 4'hD;
    localparam KEY_STAR = 4'hE; // *
    localparam KEY_HASH = 4'hF; // #

    localparam ST_IDLE           = 3'd0;
    localparam ST_START_DIV      = 3'd1;
    localparam ST_SEND_VALID     = 3'd2;
    localparam ST_WAIT_DONE      = 3'd3;
    localparam ST_CAPTURE_RESULT = 3'd4;

    logic [2:0] state;

    logic [5:0] reg_A;
    logic [3:0] reg_B;

    logic [5:0] last_quotient;
    logic [3:0] last_remainder;

    // ============================================================
    // Lectura de current_display en formato normal
    //
    // CCC5 = 5
    // CC15 = 15
    // CC58 = 58
    // ============================================================

    logic [13:0] d3;
    logic [13:0] d2;
    logic [13:0] d1;
    logic [13:0] d0;
    logic [13:0] val_en_pantalla;

    assign d3 = (current_display[15:12] < 4'd10) ? {10'd0, current_display[15:12]} : 14'd0;
    assign d2 = (current_display[11:8]  < 4'd10) ? {10'd0, current_display[11:8]}  : 14'd0;
    assign d1 = (current_display[7:4]   < 4'd10) ? {10'd0, current_display[7:4]}   : 14'd0;
    assign d0 = (current_display[3:0]   < 4'd10) ? {10'd0, current_display[3:0]}   : 14'd0;

    assign val_en_pantalla = (d3 * 14'd1000) +
                              (d2 * 14'd100)  +
                              (d1 * 14'd10)   +
                               d0;

    // ============================================================
    // Función para convertir binario 0-63 a formato display
    //
    // 3  -> CCC3
    // 5  -> CCC5
    // 10 -> CC10
    // 11 -> CC11
    // ============================================================

    function automatic logic [15:0] bin_to_display(input logic [5:0] value);
        logic [3:0] tens;
        logic [3:0] ones;
        begin
            if      (value >= 6'd60) begin
                tens = 4'd6;
                ones = value - 6'd60;
            end
            else if (value >= 6'd50) begin
                tens = 4'd5;
                ones = value - 6'd50;
            end
            else if (value >= 6'd40) begin
                tens = 4'd4;
                ones = value - 6'd40;
            end
            else if (value >= 6'd30) begin
                tens = 4'd3;
                ones = value - 6'd30;
            end
            else if (value >= 6'd20) begin
                tens = 4'd2;
                ones = value - 6'd20;
            end
            else if (value >= 6'd10) begin
                tens = 4'd1;
                ones = value - 6'd10;
            end
            else begin
                tens = 4'hC;
                ones = value[3:0];
            end

            bin_to_display = {4'hC, 4'hC, tens, ones};
        end
    endfunction

    // ============================================================
    // FSM principal
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_A          <= 6'd0;
            reg_B          <= 4'd0;

            last_quotient  <= 6'd0;
            last_remainder <= 4'd0;

            m4_clear       <= 1'b0;
            m4_load        <= 1'b0;
            m4_result_data <= 16'hCCCC;

            div_valid      <= 1'b0;
            dividend_out   <= 6'd0;
            divisor_out    <= 4'd0;

            state          <= ST_IDLE;
        end
        else begin
            m4_clear  <= 1'b0;
            m4_load   <= 1'b0;
            div_valid <= 1'b0;

            case (state)

                // ====================================================
                // Espera de teclas
                // ====================================================
                ST_IDLE: begin
                    if (key_valid) begin

                        // --------------------------------------------
                        // A: guardar dividendo
                        // --------------------------------------------
                        if (key_code == KEY_A) begin
                            if (val_en_pantalla <= 14'd63) begin
                                reg_A    <= val_en_pantalla[5:0];
                                m4_clear <= 1'b1;
                            end
                            else begin
                                m4_result_data <= 16'hCEEE;
                                m4_load        <= 1'b1;
                            end
                        end

                        // --------------------------------------------
                        // B: guardar divisor
                        // --------------------------------------------
                        else if (key_code == KEY_B) begin
                            if (val_en_pantalla <= 14'd15) begin
                                reg_B    <= val_en_pantalla[3:0];
                                m4_clear <= 1'b1;
                            end
                            else begin
                                m4_result_data <= 16'hCEEE;
                                m4_load        <= 1'b1;
                            end
                        end

                        // --------------------------------------------
                        // C: limpiar todo
                        // --------------------------------------------
                        else if (key_code == KEY_C) begin
                            reg_A          <= 6'd0;
                            reg_B          <= 4'd0;
                            last_quotient  <= 6'd0;
                            last_remainder <= 4'd0;

                            m4_clear       <= 1'b1;
                        end

                        // --------------------------------------------
                        // D: ejecutar división
                        // Después de calcular muestra cociente
                        // --------------------------------------------
                        else if (key_code == KEY_D) begin
                            state <= ST_START_DIV;
                        end

                        // --------------------------------------------
                        // *: mostrar residuo
                        // --------------------------------------------
                        else if (key_code == KEY_STAR) begin
                            m4_result_data <= bin_to_display({2'd0, last_remainder});
                            m4_load        <= 1'b1;
                        end

                        // --------------------------------------------
                        // #: mostrar cociente
                        // --------------------------------------------
                        else if (key_code == KEY_HASH) begin
                            m4_result_data <= bin_to_display(last_quotient);
                            m4_load        <= 1'b1;
                        end
                    end
                end

                // ====================================================
                // Colocar operandos para m8
                // ====================================================
                ST_START_DIV: begin
                    if (reg_B == 4'd0) begin
                        m4_result_data <= 16'hCEEE;
                        m4_load        <= 1'b1;
                        state          <= ST_IDLE;
                    end
                    else begin
                        dividend_out <= reg_A;
                        divisor_out  <= reg_B;
                        state        <= ST_SEND_VALID;
                    end
                end

                // ====================================================
                // Enviar valid un ciclo después
                // ====================================================
                ST_SEND_VALID: begin
                    div_valid <= 1'b1;
                    state     <= ST_WAIT_DONE;
                end

                // ====================================================
                // Esperar done de m8
                // ====================================================
                ST_WAIT_DONE: begin
                    if (div_done) begin
                        state <= ST_CAPTURE_RESULT;
                    end
                end

                // ====================================================
                // Capturar resultado y mostrar cociente
                // ====================================================
                ST_CAPTURE_RESULT: begin
                    last_quotient  <= quotient_in;
                    last_remainder <= remainder_in;

                    // Después de presionar D, muestra cociente
                    m4_result_data <= bin_to_display(quotient_in);
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