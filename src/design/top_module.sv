module top_module (
    input  logic       clk,       // Reloj 27 MHz de la placa
    input  logic       rst_n,     // Botón de reset físico
    input  logic [3:0] rows,      // Teclado: Filas
    output logic [3:0] cols,      // Teclado: Columnas
    output logic [6:0] seg,       // Display: Segmentos
    output logic [3:0] an         // Display: Ánodos/Transistores
);

    // ==============================================================================
    // CABLES INTERNOS (Señales de interconexión)
    // ==============================================================================
    
    logic clk_1khz;
    logic [3:0] key_code_wire;
    logic       key_valid_wire;
    
    // Cable que lleva la imagen de la pantalla (Va de m4 hacia m6 y m7)
    logic [15:0] display_data_wire;

    // Cables: La comunicación privada de m7 hacia m4
    logic        m7_to_m4_clear; // Señal de borrado
    logic        m7_to_m4_load;  // Señal de cargar resultado
    logic [15:0] m7_to_m4_data;  // El número del resultado de la operación

    // NUEVOS CABLES: Comunicación entre Calculadora (m7) y Divisor (m8)
    logic       div_valid_wire;
    logic       div_done_wire;
    logic [5:0] dividend_wire;
    logic [3:0] divisor_wire;
    logic [5:0] quotient_wire;
    logic [3:0] remainder_wire;

    // ==============================================================================
    // INSTANCIAS DE HARDWARE
    // ==============================================================================

    // 1. DIVISOR DE RELOJ
    m1_clk_divider u_clk_div (
        .clk_in  (clk),
        .rst_n   (rst_n),
        .clk_out (clk_1khz)
    );

    // 2. LECTOR DE TECLADO
    m3_keypad_reader u_keypad (
        .clk       (clk_1khz),
        .rst_n     (rst_n),
        .rows      (rows),
        .cols      (cols),
        .key_code  (key_code_wire),
        .key_valid (key_valid_wire)
    );

    // 3. CONTROLADOR DE PANTALLA
    m4_display_controller u_controller (
        .clk          (clk_1khz),
        .rst_n        (rst_n),
        .key_code     (key_code_wire),
        .key_valid    (key_valid_wire),
        
        // Entradas de control que vienen del m7
        .force_reset  (m7_to_m4_clear), 
        .force_load   (m7_to_m4_load),  
        .data_to_load (m7_to_m4_data),  
        
        // Salida hacia el display
        .display_data (display_data_wire)
    );

    // 4. CALCULADORA (El Cerebro)
    m7_calculadora u_calculadora (
        .clk             (clk_1khz),
        .rst_n           (rst_n),
        .key_code        (key_code_wire),
        .key_valid       (key_valid_wire),
        
        // "Mira" lo que hay en el cable del display
        .current_display (display_data_wire), 
        
        // Envía órdenes por los cables hacia el m4
        .m4_clear        (m7_to_m4_clear),
        .m4_load         (m7_to_m4_load),
        .m4_result_data  (m7_to_m4_data),

        // NUEVO: Puertos conectados al coprocesador de división (m8)
        .div_valid       (div_valid_wire),
        .dividend_out    (dividend_wire),
        .divisor_out     (divisor_wire),
        .div_done        (div_done_wire),
        .quotient_in     (quotient_wire),
        .remainder_in    (remainder_wire)
    );

    // 5. DRIVER FÍSICO DEL DISPLAY
    m6_seven_segment_driver u_display (
        .clk      (clk_1khz),
        .rst_n    (rst_n),
        .hex_data (display_data_wire),
        .seg      (seg),
        .an       (an)
    );

    // 6. DIVISOR MATEMÁTICO (Coprocesador)
    m8_divisor u_divisor (
        .clk       (clk_1khz),
        .rst_n     (rst_n),
        
        // Entradas desde la calculadora (m7)
        .valid     (div_valid_wire),
        .dividend  (dividend_wire),
        .divisor   (divisor_wire),
        
        // Salidas hacia la calculadora (m7)
        .done      (div_done_wire),
        .quotient  (quotient_wire),
        .remainder (remainder_wire)
    );

endmodule