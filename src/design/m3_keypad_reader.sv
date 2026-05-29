module m3_keypad_reader (
    input  logic clk,       // Conectar al clk_1khz generado por m1_clk_divider
    input  logic rst_n,

    input  logic [3:0] rows,
    output logic [3:0] cols,

    output logic [3:0] key_code,
    output logic       key_valid
);

    // Si el reloj es de 1 kHz, 5 ciclos equivalen a 5 ms por columna.
    localparam SCAN_DELAY = 16'd5;

    // Códigos especiales para el teclado
    localparam KEY_A     = 4'hA;
    localparam KEY_B     = 4'hB;
    localparam KEY_C     = 4'hC;
    localparam KEY_D     = 4'hD;
    localparam KEY_STAR  = 4'hE; // Tecla *
    localparam KEY_HASH  = 4'hF; // Tecla #

    logic [3:0] rows_db;
    logic [3:0] rows_inv;          // 1 = tecla presionada
    logic [1:0] col_index;
    logic [15:0] scan_counter;

    logic key_pressed;
    logic key_pressed_prev;
    logic [3:0] key_code_comb;
    logic scan_enable;

    // Debounce de cada fila
    m2_DeBounce db0 (
        .clk(clk),
        .rst_n(rst_n),
        .sw_in(rows[0]),
        .sw_out(rows_db[0])
    );

    m2_DeBounce db1 (
        .clk(clk),
        .rst_n(rst_n),
        .sw_in(rows[1]),
        .sw_out(rows_db[1])
    );

    m2_DeBounce db2 (
        .clk(clk),
        .rst_n(rst_n),
        .sw_in(rows[2]),
        .sw_out(rows_db[2])
    );

    m2_DeBounce db3 (
        .clk(clk),
        .rst_n(rst_n),
        .sw_in(rows[3]),
        .sw_out(rows_db[3])
    );

    // El escaneo avanza solamente cuando no hay ninguna tecla presionada.
    // Se usa rows_db para trabajar con las señales ya filtradas.
    assign scan_enable = (rows_db == 4'b1111);

    // Contador de escaneo de columnas
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_counter <= 16'd0;
            col_index    <= 2'd0;
        end 
        else if (scan_enable) begin
            if (scan_counter >= SCAN_DELAY) begin
                scan_counter <= 16'd0;
                col_index    <= col_index + 1'b1;
            end 
            else begin
                scan_counter <= scan_counter + 1'b1;
            end
        end
    end

    // Activación de columnas.
    // Solo una columna se coloca en 0 a la vez.
    always_comb begin
        case (col_index)
            2'd0: cols = 4'b1110;
            2'd1: cols = 4'b1101;
            2'd2: cols = 4'b1011;
            2'd3: cols = 4'b0111;
            default: cols = 4'b1111;
        endcase
    end

    // Las filas vienen activas en bajo.
    // Al invertirlas, una tecla presionada se representa con 1.
    assign rows_inv    = ~rows_db;
    assign key_pressed = (rows_inv != 4'b0000);

    // Codificación del teclado:
    //
    //  1   2   3   A
    //  4   5   6   B
    //  7   8   9   C
    //  *   0   #   D
    //
    // Internamente:
    // * = 4'hE
    // # = 4'hF
    always_comb begin
        key_code_comb = 4'h0;

        case ({rows_inv, col_index})

            // Fila 0: 1, 2, 3, A
            6'b0001_00: key_code_comb = 4'h1;
            6'b0001_01: key_code_comb = 4'h2;
            6'b0001_10: key_code_comb = 4'h3;
            6'b0001_11: key_code_comb = KEY_A;

            // Fila 1: 4, 5, 6, B
            6'b0010_00: key_code_comb = 4'h4;
            6'b0010_01: key_code_comb = 4'h5;
            6'b0010_10: key_code_comb = 4'h6;
            6'b0010_11: key_code_comb = KEY_B;

            // Fila 2: 7, 8, 9, C
            6'b0100_00: key_code_comb = 4'h7;
            6'b0100_01: key_code_comb = 4'h8;
            6'b0100_10: key_code_comb = 4'h9;
            6'b0100_11: key_code_comb = KEY_C;

            // Fila 3: *, 0, #, D
            6'b1000_00: key_code_comb = KEY_STAR;
            6'b1000_01: key_code_comb = 4'h0;
            6'b1000_10: key_code_comb = KEY_HASH;
            6'b1000_11: key_code_comb = KEY_D;

            default: key_code_comb = 4'h0;

        endcase
    end

    // Generación de pulso key_valid.
    // key_valid dura un ciclo cuando se detecta una nueva tecla presionada.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_pressed_prev <= 1'b0;
            key_valid        <= 1'b0;
            key_code         <= 4'h0;
        end 
        else begin
            key_pressed_prev <= key_pressed;

            key_valid <= key_pressed & ~key_pressed_prev;

            if (key_pressed & ~key_pressed_prev) begin
                key_code <= key_code_comb;
            end
        end
    end

endmodule
