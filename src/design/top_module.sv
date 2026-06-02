module top_module (
    input  logic       clk,       // Reloj principal de 27 MHz de la Tang Nano 9K (Pin 52)
    input  logic       rst_n,     // Botón de reset físico (activo en bajo)
    
    // Periféricos externos
    input  logic [3:0] rows,      // Entradas desde las filas del teclado matricial
    output logic [3:0] cols,      // Salidas hacia las columnas del teclado
    output logic [6:0] seg,       // Salidas hacia los segmentos del display (g,f,e,d,c,b,a)
    output logic [3:0] an         // Salidas para conmutar los ánodos del display multiplexado
);

    // ==============================================================================
    // CABLES INTERNOS (Señales de interconexión entre módulos)
    // ==============================================================================
    
    // Reloj secundario
    logic clk_1khz;
    
    // Buses de datos del teclado
    logic [3:0] key_code_wire;
    logic       key_valid_wire;
    
    // Bus principal de video/pantalla
    logic [15:0] display_data_wire;

    // Bus privado de control (De la Calculadora hacia el Controlador de Pantalla)
    logic        m7_to_m4_clear; // Orden de borrar pantalla
    logic        m7_to_m4_load;  // Orden de forzar la carga de un resultado
    logic [15:0] m7_to_m4_data;  // El valor del resultado (Cociente/Residuo/Error)

    // ==============================================================================
    // INSTANCIACIÓN DE LOS SUBMÓDULOS (El Hardware)
    // ==============================================================================

    // 1. DIVISOR DE RELOJ: Reduce 27MHz a 1kHz para estabilizar rebotes y displays
    m1_clk_divider u_clk_div (
        .clk_in  (clk),
        .rst_n   (rst_n),
        .clk_out (clk_1khz)
    );

    // 2. LECTOR DE TECLADO: Escanea pines físicos y genera un código limpio y un pulso
    m3_keypad_reader u_keypad (
        .clk       (clk_1khz),
        .rst_n     (rst_n),
        .rows      (rows),
        .cols      (cols),
        .key_code  (key_code_wire),
        .key_valid (key_valid_wire)
    );

    // 3. CONTROLADOR DE PANTALLA: Administra qué números se dibujan en los 4 dígitos
    m4_display_controller u_controller (
        .clk          (clk_1khz),
        .rst_n        (rst_n),
        
        // Entradas desde el usuario (teclado)
        .key_code     (key_code_wire),
        .key_valid    (key_valid_wire),
        
        // Entradas de control automático (desde m7)
        .force_reset  (m7_to_m4_clear),
        .force_load   (m7_to_m4_load),
        .data_to_load (m7_to_m4_data),
        
        // Salida hacia el bus de video
        .display_data (display_data_wire)
    );

    // 4. CALCULADORA (El Cerebro): FSM que lee, decide y ejecuta la división
    // Nota: El submódulo m8_divisor vive dentro de esta caja.
    m7_calculadora u_calculadora (
        .clk             (clk_1khz),
        .rst_n           (rst_n),
        
        // Escucha qué teclea el usuario
        .key_code        (key_code_wire),
        .key_valid       (key_valid_wire),
        
        // "Mira" lo que hay actualmente en pantalla para saber qué operar
        .current_display (display_data_wire),
        
        // Cables de mando para sobreescribir la pantalla al terminar
        .m4_clear        (m7_to_m4_clear),
        .m4_load         (m7_to_m4_load),
        .m4_result_data  (m7_to_m4_data)
    );

    // 5. DRIVER DEL DISPLAY: Convierte el bus de video (16-bits) a señales eléctricas multiplexadas
    m6_seven_segment_driver u_display (
        .clk      (clk_1khz),
        .rst_n    (rst_n),
        .hex_data (display_data_wire),
        .seg      (seg),
        .an       (an)
    );

endmodule