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
    // Máximo permitido: 3 dígitos
    logic [1:0] digit_count;

    always_ff @(posedge clk or negedge rst_n) begin

        // Reset físico del sistema
        if (!rst_n) begin
            display_data <= 16'hCCCC;
            digit_count  <= 2'd0;
        end

        // Reset forzado desde m7_calculadora
        // Se usa para limpiar pantalla al iniciar una nueva operación
        else if (force_reset) begin
            display_data <= 16'hCCCC;
            digit_count  <= 2'd0;
        end

        // Carga forzada desde m7_calculadora
        // Se usa para mostrar cociente, residuo o error
        else if (force_load) begin
            display_data <= data_to_load;

            // Se marca como lleno para evitar que el usuario escriba encima
            // hasta que se limpie la pantalla
            digit_count <= 2'd3;
        end

        // Ingreso normal desde teclado
        else if (key_valid) begin

            // Tecla C: borrar pantalla
            if (key_code == 4'hC) begin
                display_data <= 16'hCCCC;
                digit_count  <= 2'd0;
            end

            // Solo se aceptan teclas numéricas: 0,1,2,3,4,5,6,7,8,9
            else if (key_code <= 4'd9) begin

                // Se permite ingresar hasta 3 dígitos
                if (digit_count < 2'd3) begin

                    // Desplaza hacia la izquierda y coloca el nuevo dígito
                    // en la posición de unidades.
                    //
                    // Ejemplo:
                    // CCCC + 1 -> CCC1
                    // CCC1 + 5 -> CC15
                    // CC15 + 3 -> C153
                    display_data <= {display_data[11:0], key_code};

                    digit_count <= digit_count + 1'b1;
                end
            end
        end
    end

endmodule
