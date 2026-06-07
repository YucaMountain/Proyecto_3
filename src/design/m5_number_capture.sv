module m5_number_capture (
    input  logic clk,
    input  logic rst_n,

    input  logic [3:0] key_code,
    input  logic       key_valid,

    input  logic       enable,      

    output logic [13:0] number, // Ampliado a 14 bits para soportar hasta 9999
    output logic       done
);

    logic [2:0] digit_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            number <= 14'd0;
            digit_count <= 3'd0;
            done <= 1'b0;
        end else begin
            done <= 1'b0; // Pulso por defecto en 0

            if (enable && key_valid && key_code <= 4'd9) begin
                
                // Si aún no hemos llegado a 4 dígitos
                if (digit_count < 3'd4) begin
                    // Actualiza el número instantáneamente
                    number <= (number * 10) + key_code;
                    digit_count <= digit_count + 1'b1;
                    done <= 1'b1; // Emite pulso de confirmación
                end
                
                // Si ya se han ingresado 3 dígitos, ignora entradas adicionales
            end
        end
    end

endmodule