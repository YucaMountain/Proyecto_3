module m4_display_controller (
    input  logic clk,
    input  logic rst_n,

    // Señales provenientes del teclado
    input  logic [3:0] key_code,
    input  logic       key_valid,

    // Señales de control desde m7_calculadora
    input  logic        force_reset,
    input  logic        force_load,
    input  logic [15:0] data_to_load,

    // Dato final que se envía al driver de 7 segmentos
    output logic [15:0] display_data
);

    // Cuenta cuántos dígitos se han ingresado en pantalla
    logic [1:0] digit_count;

    always_ff @(posedge clk or negedge rst_n) begin

        // Reset físico del sistema
        if (!rst_n) begin
            display_data <= 16'hCCCC; 
            digit_count  <= 2'b00;
        end 

        // Reset forzado desde m7_calculadora
        // Se usa para limpiar pantalla al iniciar una nueva operación
        else if (force_reset) begin
            display_data <= 16'hCCCC; 
            digit_count  <= 2'b00;
        end 

        // Carga forzada desde m7_calculadora
        // En el Proyecto III puede cargar:
        // - dividendo capturado
        // - divisor capturado
        // - cociente
        // - residuo
        // - código de error
        else if (force_load) begin
            display_data <= data_to_load;
            digit_count  <= 2'b11; 
        end 

        // Ingreso normal desde teclado
        else if (key_valid) begin

            // Solo se aceptan teclas numéricas: 0,1,2,3,4,5,6,7,8,9
            if (key_code == 4'h0 || key_code == 4'h1 || key_code == 4'h2 || 
                key_code == 4'h3 || key_code == 4'h4 || key_code == 4'h5 || 
                key_code == 4'h6 || key_code == 4'h7 || key_code == 4'h8 || 
                key_code == 4'h9) begin

                // Se permite ingresar hasta 3 dígitos
                if (digit_count < 3) begin
                    display_data <= {key_code, display_data[15:4]};
                    digit_count  <= digit_count + 1'b1;
                end
            end 

            // Tecla C: borrar pantalla
            else if (key_code == 4'hC) begin
                display_data <= 16'hCCCC;
                digit_count  <= 2'b00;
            end
        end
    end

endmodule
