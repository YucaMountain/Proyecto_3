module top_module (
    input  logic clk,        // Reloj principal de 27 MHz
    input  logic rst_n,      // Reset activo en bajo

    input  logic [3:0] rows, // Filas del teclado
    output logic [3:0] cols, // Columnas del teclado

    output logic [6:0] seg,  // Segmentos del display
    output logic [3:0] an    // Selector de dígitos
);

    // ------------------------------------------------------------
    // Señales internas
    // ------------------------------------------------------------

    logic clk_1khz;

    logic [3:0] key_code;
    logic       key_valid;

    logic [15:0] display_data;

    logic        m4_clear;
    logic        m4_load;
    logic [15:0] m4_result_data;

    // ------------------------------------------------------------
    // m1: Divisor de reloj
    // Genera reloj de 1 kHz a partir del reloj principal de 27 MHz
    // ------------------------------------------------------------

    m1_clk_divider u_m1_clk_divider (
        .clk_in  (clk),
        .rst_n   (rst_n),
        .clk_out (clk_1khz)
    );

    // ------------------------------------------------------------
    // m3: Lector de teclado matricial
    // Entrega key_code y key_valid
    // ------------------------------------------------------------

    m3_keypad_reader u_m3_keypad_reader (
        .clk       (clk_1khz),
        .rst_n     (rst_n),

        .rows      (rows),
        .cols      (cols),

        .key_code  (key_code),
        .key_valid (key_valid)
    );

    // ------------------------------------------------------------
    // m4: Controlador de datos para display
    // Muestra números ingresados o resultados cargados desde m7
    // ------------------------------------------------------------

    m4_display_controller u_m4_display_controller (
        .clk          (clk_1khz),
        .rst_n        (rst_n),

        .key_code     (key_code),
        .key_valid    (key_valid),

        .force_reset  (m4_clear),
        .force_load   (m4_load),
        .data_to_load (m4_result_data),

        .display_data (display_data)
    );

    // ------------------------------------------------------------
    // m7: Control principal de la calculadora/división
    // Dentro de este módulo se instancia m8_divisor
    // ------------------------------------------------------------

    m7_calculadora u_m7_calculadora (
        .clk             (clk_1khz),
        .rst_n           (rst_n),

        .key_code        (key_code),
        .key_valid       (key_valid),
        .current_display (display_data),

        .m4_clear        (m4_clear),
        .m4_load         (m4_load),
        .m4_result_data  (m4_result_data)
    );

    // ------------------------------------------------------------
    // m6: Driver físico de displays de 7 segmentos
    // Recibe los 4 dígitos desde m4
    // ------------------------------------------------------------

    m6_seven_segment_driver u_m6_seven_segment_driver (
        .clk      (clk_1khz),
        .rst_n    (rst_n),

        .hex_data (display_data),

        .seg      (seg),
        .an       (an)
    );

endmodule
