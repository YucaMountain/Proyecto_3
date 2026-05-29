module m1_clk_divider #(
    parameter COUNTER_MAX = 13500 // 27,000,000 / (1,000 * 2)
)(
    input  logic clk_in,   // Reloj de 27MHz (Pin 52)
    input  logic rst_n,    // Reset activo en bajo
    output logic clk_out   // Reloj de 1kHz resultante
);

    logic [15:0] counter;

    always_ff @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
            clk_out <= 1'b0;
        end else begin
            if (counter >= (COUNTER_MAX - 1)) begin
                counter <= '0;
                clk_out <= ~clk_out; // Invierte la señal para crear el pulso
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end

endmodule