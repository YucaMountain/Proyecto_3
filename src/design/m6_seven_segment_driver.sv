module m6_seven_segment_driver (
    input  logic        clk,      // Reloj lento para multiplexado (ej. 1KHz)
    input  logic        rst_n,
    input  logic [15:0] hex_data, // 16 bits de datos (4 dígitos del controlador)
    output logic [6:0]  seg,      // g, f, e, d, c, b, a (Activo en BAJO para Ánodo Común)
    output logic [3:0]  an        // Selector de dígito (Activo en ALTO para transistores NPN)
);

    // Contador para el multiplexado
    logic [1:0] mux_counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mux_counter <= 2'b00;
        else
            mux_counter <= mux_counter + 1'b1;
    end

    // Selecciona el dígito hexadecimal actual para mostrar
    logic [3:0] current_hex_digit;
    always_comb begin
        case (mux_counter)
            2'b00: current_hex_digit = hex_data[3:0];   // Dígito 0 (Derecha)
            2'b01: current_hex_digit = hex_data[7:4];   // Dígito 1
            2'b10: current_hex_digit = hex_data[11:8];  // Dígito 2
            2'b11: current_hex_digit = hex_data[15:12]; // Dígito 3 (Izquierda)
        endcase
    end

    // Selector de ánodos (Transistores NPN - Activos en ALTO)
    always_comb begin
        an = 4'b0000; // Por defecto todos apagados
        an[mux_counter] = 1'b1; // Enciende solo el dígito actual
    end

    // Decodificador de 7 segmentos (Lógica Invertida para Ánodo Común)
    // Orden de los bits: seg = {g, f, e, d, c, b, a}
    always_comb begin
        case (current_hex_digit)
            4'h0: seg = 7'b0111111; 
            4'h1: seg = 7'b0000110; 
            4'h2: seg = 7'b1011011; 
            4'h3: seg = 7'b1001111; 
            4'h4: seg = 7'b1100110; 
            4'h5: seg = 7'b1101101; 
            4'h6: seg = 7'b1111101; 
            4'h7: seg = 7'b0000111; 
            4'h8: seg = 7'b1111111; 
            4'h9: seg = 7'b1101111; 
            4'hA: seg = 7'b1110111; 
            4'hB: seg = 7'b1111100; 
            4'hC: seg = 7'b1000000;  //Aqui se cambió el display para en vez de mostrar una "C" muestre un guion "-" ya que nuestro C funciona como un full clear
            4'hD: seg = 7'b1011110; 
            4'hE: seg = 7'b1111001; 
            4'hF: seg = 7'b1110001; 
            default: seg = 7'b1000000; // Todos los segmentos apagados
        endcase
    end

endmodule