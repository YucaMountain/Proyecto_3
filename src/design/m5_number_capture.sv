module m5_number_capture #(
    parameter int WIDTH      = 6,
    parameter int MAX_VALUE  = 63,
    parameter int MAX_DIGITS = 2
)(
    input  logic clk,
    input  logic rst_n,

    input  logic [3:0] key_code,
    input  logic       key_valid,

    input  logic       enable,
    input  logic       clear,

    output logic [WIDTH-1:0] number,
    output logic             digit_done,
    output logic             overflow
);

    logic [2:0] digit_count;
    logic [WIDTH+3:0] next_number;

    // Cálculo tentativo del nuevo número
    always_comb begin
        next_number = (number * 10) + key_code;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            number      <= '0;
            digit_count <= 3'd0;
            digit_done  <= 1'b0;
            overflow    <= 1'b0;
        end 
        else begin
            digit_done <= 1'b0;

            // Limpia la captura actual
            if (clear) begin
                number      <= '0;
                digit_count <= 3'd0;
                overflow    <= 1'b0;
            end

            // Captura solamente si el módulo está habilitado,
            // hay una tecla válida y la tecla es numérica
            else if (enable && key_valid && key_code <= 4'd9) begin

                if (digit_count < MAX_DIGITS) begin

                    // Solo acepta el nuevo número si está dentro del rango permitido
                    if (next_number <= MAX_VALUE) begin
                        number      <= next_number[WIDTH-1:0];
                        digit_count <= digit_count + 1'b1;
                        digit_done  <= 1'b1;
                        overflow    <= 1'b0;
                    end 
                    else begin
                        overflow <= 1'b1;
                    end

                end
            end
        end
    end

endmodule
