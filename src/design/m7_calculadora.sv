module m7_calculadora (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [3:0]  key_code,
    input  logic        key_valid,
    input  logic [15:0] current_display,

    output logic        m4_clear,        
    output logic        m4_load,         
    output logic [15:0] m4_result_data   
);
    // Registros para almacenar los operandos A y B
    logic [10:0] reg_A, reg_B;
    logic [2:0]  state; 
    
    logic [11:0] suma, temp_val;
    logic [3:0]  b3, b2, b1, b0;

    logic [10:0] val_en_pantalla;

    // Convertir el valor mostrado en la pantalla a un número binario para cálculos.
    assign val_en_pantalla = ((current_display[7:4]   < 10) ? {7'd0, current_display[7:4]}   : 11'd0) * 11'd100 + 
                             ((current_display[11:8]  < 10) ? {7'd0, current_display[11:8]}  : 11'd0) * 11'd10  + 
                             ((current_display[15:12] < 10) ? {7'd0, current_display[15:12]} : 11'd0);


    // Lógica principal de la calculadora
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_A <= 0;
            reg_B <= 0;
            m4_clear <= 0;
            m4_load  <= 0;
            m4_result_data <= 16'hCCCC;
            state <= 3'd0;
            suma <= 0;
            temp_val <= 0;
            b3 <= 0; b2 <= 0; b1 <= 0; b0 <= 0;
        end else begin
            m4_clear <= 0;
            m4_load  <= 0;

            case (state)
                3'd0: begin
                    if (key_valid) begin 
                        if (key_code == 4'hA) begin
                            reg_A <= val_en_pantalla;
                            m4_clear <= 1; 
                        end 
                        else if (key_code == 4'hB) begin
                            reg_B <= val_en_pantalla;
                            m4_clear <= 1; 
                        end 
                        else if (key_code == 4'hD) begin
                            state <= 3'd1; 
                        end
                        else if (key_code == 4'hC) begin
                            reg_A <= 0;
                            reg_B <= 0;
                        end
                    end
                end

                // Estado de cálculo: Realiza la suma de A y B

                3'd1: begin
                    suma <= reg_A + reg_B;
                    state <= 3'd2;
                end

                
                //  Estado de conversión: Convierte la suma (en binario) a formato BCD para mostrar en la pantalla.

                3'd2: begin
                    if (suma > 12'd999) begin // Equivalente a >= 1000
                        b3 <= 4'd1; temp_val <= suma - 12'd1000;
                    end else begin
                        b3 <= 4'd0; temp_val <= suma;
                    end
                    state <= 3'd3;
                end

                // Estado de extracción de dígitos: Extrae los dígitos BCD uno por uno para formar el resultado final.

                3'd3: begin
                    if      (temp_val > 12'd899) begin b2 <= 4'd9; temp_val <= temp_val - 12'd900; end
                    else if (temp_val > 12'd799) begin b2 <= 4'd8; temp_val <= temp_val - 12'd800; end
                    else if (temp_val > 12'd699) begin b2 <= 4'd7; temp_val <= temp_val - 12'd700; end
                    else if (temp_val > 12'd599) begin b2 <= 4'd6; temp_val <= temp_val - 12'd600; end
                    else if (temp_val > 12'd499) begin b2 <= 4'd5; temp_val <= temp_val - 12'd500; end
                    else if (temp_val > 12'd399) begin b2 <= 4'd4; temp_val <= temp_val - 12'd400; end
                    else if (temp_val > 12'd299) begin b2 <= 4'd3; temp_val <= temp_val - 12'd300; end
                    else if (temp_val > 12'd199) begin b2 <= 4'd2; temp_val <= temp_val - 12'd200; end
                    else if (temp_val > 12'd99)  begin b2 <= 4'd1; temp_val <= temp_val - 12'd100; end
                    else                         begin b2 <= 4'd0; end
                    state <= 3'd4;
                end

                // Estado final: Asigna los dígitos BCD a la salida para mostrar el resultado en la pantalla.

                3'd4: begin
                    if      (temp_val > 12'd89)  begin b1 <= 4'd9; b0 <= temp_val - 12'd90; end
                    else if (temp_val > 12'd79)  begin b1 <= 4'd8; b0 <= temp_val - 12'd80; end
                    else if (temp_val > 12'd69)  begin b1 <= 4'd7; b0 <= temp_val - 12'd70; end
                    else if (temp_val > 12'd59)  begin b1 <= 4'd6; b0 <= temp_val - 12'd60; end
                    else if (temp_val > 12'd49)  begin b1 <= 4'd5; b0 <= temp_val - 12'd50; end
                    else if (temp_val > 12'd39)  begin b1 <= 4'd4; b0 <= temp_val - 12'd40; end
                    else if (temp_val > 12'd29)  begin b1 <= 4'd3; b0 <= temp_val - 12'd30; end
                    else if (temp_val > 12'd19)  begin b1 <= 4'd2; b0 <= temp_val - 12'd20; end
                    else if (temp_val > 12'd9)   begin b1 <= 4'd1; b0 <= temp_val - 12'd10; end
                    else                         begin b1 <= 4'd0; b0 <= temp_val; end
                    state <= 3'd5;
                end

                3'd5: begin
                    m4_result_data <= {b0[3:0], b1[3:0], b2[3:0], (b3 > 0 ? 4'h1 : 4'hC)};
                    m4_load <= 1;  
                    state <= 3'd0; 
                end
                
                default: state <= 3'd0;
            endcase
        end
    end
endmodule