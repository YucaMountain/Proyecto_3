module m4_display_controller (
    input  logic clk,
    input  logic rst_n,
    input  logic [3:0] key_code,
    input  logic       key_valid,
    
    input  logic        force_reset, 
    input  logic        force_load,
    input  logic [15:0] data_to_load,

    output logic [15:0] display_data 
);

    logic [1:0] digit_count;

    always_ff @(posedge clk or negedge rst_n) begin
        // Reset físico
        if (!rst_n) begin
            display_data <= 16'hCCCC; 
            digit_count  <= 2'b00;
        end 
        // Reset forzado desde m7_calculadora (Tecla A o B)
        else if (force_reset) begin
            display_data <= 16'hCCCC; 
            digit_count  <= 2'b00;
        end 
        // 3. Carga del resultado desde m7_calculadora (Tecla D)
        else if (force_load) begin
            display_data <= data_to_load;
            digit_count  <= 2'b11; 
        end 
        // 4. Teclado normal
        else if (key_valid) begin
            
            // LÓGICA EXPLÍCITA: Solo entra si es exactamente uno de estos números. Utilizando compuertas OR para claridad.
            if (key_code == 4'h0 || key_code == 4'h1 || key_code == 4'h2 || 
                key_code == 4'h3 || key_code == 4'h4 || key_code == 4'h5 || 
                key_code == 4'h6 || key_code == 4'h7 || key_code == 4'h8 || 
                key_code == 4'h9) begin
                
                if (digit_count < 3) begin
                    display_data <= {key_code, display_data[15:4]};
                    digit_count  <= digit_count + 1'b1;
                end
            end 
            
            // Lógica para borrar (Tecla C)
            else if (key_code == 4'hC) begin
                 display_data <= 16'hCCCC;
                 digit_count  <= 2'b00;
            end
            
        end
    end
endmodule