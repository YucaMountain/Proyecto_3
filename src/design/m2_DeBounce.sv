module m2_DeBounce (
    input  logic clk,      // Usaremos el clk de 1kHz generado en el módulo |m1_ClockDivider
    input  logic rst_n,
    input  logic sw_in,    // Señal ruidosa de la fila del teclado
    output logic sw_out    // Señal limpia y estable
);

    // Con el clk a 1kHz, 20 ciclos equivalen a 20ms de estabilidad
    logic [4:0] count;
    logic sync_0, sync_1; // Sincronizadores para evitar metaestabilidad o errores

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_0 <= 1'b1; // Las filas tienen resistencias Pull-up internas (inactivas en 1)
            sync_1 <= 1'b1;
            sw_out <= 1'b1;
            count  <= '0;
        end else begin
            // Sincronización para evitar problemas de timing asíncrono
            sync_0 <= sw_in;
            sync_1 <= sync_0;

            // Verificación de estabilidad
            if (sync_1 == sw_out) begin
                count <= '0; // Si la señal es igual a la última estable, reinicia contador
            end else begin
                count <= count + 1'b1;
                if (count == 5'd20) begin // Si se mantiene diferente por 20ms
                    sw_out <= sync_1;    // Actualiza la salida estable
                    count  <= '0;
                end
            end
        end
    end

endmodule