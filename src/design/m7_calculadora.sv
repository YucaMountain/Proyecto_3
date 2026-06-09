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

    localparam ST_IDLE           = 4'd0;
    localparam ST_START_DIV      = 4'd1;
    localparam ST_SEND_VALID     = 4'd2;
    localparam ST_WAIT_DONE      = 4'd3;
    localparam ST_CAPTURE_RESULT = 4'd4;
    localparam ST_BCD_CONV       = 4'd5;
    localparam ST_LOAD_RES       = 4'd6;

    logic [3:0] state;

    logic [5:0] reg_A;
    logic [3:0] reg_B;

    logic [5:0] last_quotient;
    logic [3:0] last_remainder;

    logic [5:0] temp_val;
    logic [3:0] b1;
    logic [3:0] b0;

    // ------------------------------------------------------------
    // Lectura de current_display en formato normal:
    //
    // CCC5 = 5
    // CC15 = 15
    // CC50 = 50
    // CC48 = 48
    // ------------------------------------------------------------

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

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_A          <= 6'd0;
            reg_B          <= 4'd0;

            last_quotient  <= 6'd0;
            last_remainder <= 4'd0;

            temp_val       <= 6'd0;
            b1             <= 4'hC;
            b0             <= 4'h0;

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

                ST_IDLE: begin
                    if (key_valid) begin

                        // Guardar dividendo
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

                        // Guardar divisor
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

                        // Limpiar todo
                        else if (key_code == KEY_C) begin
                            reg_A          <= 6'd0;
                            reg_B          <= 4'd0;
                            last_quotient  <= 6'd0;
                            last_remainder <= 4'd0;
                            temp_val       <= 6'd0;
                            m4_clear       <= 1'b1;
                        end

                        // Ejecutar división
                        else if (key_code == KEY_D) begin
                            state <= ST_START_DIV;
                        end

                        // Mostrar cociente
                        else if (key_code == KEY_STAR) begin
                            temp_val <= last_quotient;
                            state    <= ST_BCD_CONV;
                        end

                        // Mostrar residuo
                        else if (key_code == KEY_HASH) begin
                            temp_val <= {2'd0, last_remainder};
                            state    <= ST_BCD_CONV;
                        end
                    end
                end

                // Colocar operandos estables
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

                // Mandar valid un ciclo después
                ST_SEND_VALID: begin
                    div_valid <= 1'b1;
                    state     <= ST_WAIT_DONE;
                end

                // Esperar done del divisor
                ST_WAIT_DONE: begin
                    if (div_done) begin
                        state <= ST_CAPTURE_RESULT;
                    end
                end

                // Capturar resultado un ciclo después de done
                ST_CAPTURE_RESULT: begin
                    last_quotient  <= quotient_in;
                    last_remainder <= remainder_in;
                    temp_val       <= quotient_in;
                    state          <= ST_BCD_CONV;
                end

                // Conversión binario a decimal para 0 a 63
                ST_BCD_CONV: begin
                    if      (temp_val >= 6'd60) begin b1 <= 4'd6; b0 <= temp_val - 6'd60; end
                    else if (temp_val >= 6'd50) begin b1 <= 4'd5; b0 <= temp_val - 6'd50; end
                    else if (temp_val >= 6'd40) begin b1 <= 4'd4; b0 <= temp_val - 6'd40; end
                    else if (temp_val >= 6'd30) begin b1 <= 4'd3; b0 <= temp_val - 6'd30; end
                    else if (temp_val >= 6'd20) begin b1 <= 4'd2; b0 <= temp_val - 6'd20; end
                    else if (temp_val >= 6'd10) begin b1 <= 4'd1; b0 <= temp_val - 6'd10; end
                    else                         begin b1 <= 4'hC; b0 <= temp_val[3:0]; end

                    state <= ST_LOAD_RES;
                end

                // Cargar resultado hacia m4
                ST_LOAD_RES: begin
                    m4_result_data <= {4'hC, 4'hC, b1, b0};
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
