module m3_keypad_reader (
    input  logic clk,       // Conectar al clk_1khz generado por m1_ClockDivider
    input  logic rst_n,
    input  logic [3:0] rows,
    output logic [3:0] cols,
    output logic [3:0] key_code,
    output logic       key_valid
);

    // Si el reloj es de 1kHz, 5 ciclos = 5ms de tiempo de escaneo por columna, ideal para un teclado numpad
    localparam SCAN_DELAY = 16'd5;  
    
    // Señales internas
    logic [3:0] rows_db;
    logic [3:0] rows_inv; // Señal invertida para facilitar la lectura (1 = presionado)
    logic [1:0] col_index;
    logic [15:0] scan_counter;
    logic key_pressed;
    logic key_pressed_prev;
    logic [3:0] key_code_comb;
    logic scan_enable;
    
    
    // Debounce en filas gracias al módulo m2_DeBounce
    
    m2_DeBounce db0 (.clk(clk), .rst_n(rst_n), .sw_in(rows[0]), .sw_out(rows_db[0]));
    m2_DeBounce db1 (.clk(clk), .rst_n(rst_n), .sw_in(rows[1]), .sw_out(rows_db[1]));
    m2_DeBounce db2 (.clk(clk), .rst_n(rst_n), .sw_in(rows[2]), .sw_out(rows_db[2]));
    m2_DeBounce db3 (.clk(clk), .rst_n(rst_n), .sw_in(rows[3]), .sw_out(rows_db[3]));

    
    // Escaneo de columnas 
    // Pausa el escáner si detecta cualquier fila en '0' (presión física detectada)
    // Esto da tiempo para que los debouncers hagan su trabajo sin cambiar de columna
    assign scan_enable = (rows == 4'b1111); 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_counter <= 0;
            col_index <= 0;
        end else if (scan_enable) begin
            if (scan_counter >= SCAN_DELAY) begin
                scan_counter <= 0;
                col_index <= col_index + 1'b1;
            end else begin
                scan_counter <= scan_counter + 1'b1;
            end
        end
    end

    // Rotar el '0' por las columnas

    always_comb begin
        cols = 4'b1111;
        cols[col_index] = 1'b0;
    end

    
    // Detección de tecla presionada (Lógica Positiva)
    // Invertimos el debouncer: Ahora si un botón se presiona, su bit será '1'

    assign rows_inv = ~rows_db; 
    assign key_pressed = (rows_inv != 4'b0000);

    
    // Codificación combinacional

    always_comb begin
        key_code_comb = 4'h0; // Valor por defecto
        
        case ({rows_inv, col_index})
            // Fila 0 (1, 2, 3, A)
            6'b0001_00: key_code_comb = 4'h1;
            6'b0001_01: key_code_comb = 4'h2;
            6'b0001_10: key_code_comb = 4'h3;
            6'b0001_11: key_code_comb = 4'hA;
            
            // Fila 1 (4, 5, 6, B)
            6'b0010_00: key_code_comb = 4'h4;
            6'b0010_01: key_code_comb = 4'h5;
            6'b0010_10: key_code_comb = 4'h6;
            6'b0010_11: key_code_comb = 4'hB;
            
            // Fila 2 (7, 8, 9, C)
            6'b0100_00: key_code_comb = 4'h7;
            6'b0100_01: key_code_comb = 4'h8;
            6'b0100_10: key_code_comb = 4'h9;
            6'b0100_11: key_code_comb = 4'hC;
            
            // Fila 3 (* -> E, 0, # -> F, D)
            6'b1000_00: key_code_comb = 4'hE;
            6'b1000_01: key_code_comb = 4'h0;
            6'b1000_10: key_code_comb = 4'hF;
            6'b1000_11: key_code_comb = 4'hD;
            
            default: key_code_comb = 4'h0;
        endcase
    end

    
    // Generar pulso de key_valid y registrar código
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_pressed_prev <= 0;
            key_valid <= 0;
            key_code <= 0;
        end else begin
            key_pressed_prev <= key_pressed;
            
            // Genera un pulso de 1 solo ciclo de reloj cuando se presiona la tecla
            key_valid <= key_pressed & ~key_pressed_prev;
            
            // Guarda el valor solo en el instante en que se validó la presión
            if (key_pressed & ~key_pressed_prev) begin
                key_code <= key_code_comb;
            end
        end
    end

endmodule