`timescale 1us/1ns

module m3_keypad_reader_tb;

    // ------------------------------------------------------------
    // Señales del testbench
    // ------------------------------------------------------------
    logic clk;
    logic rst_n;

    logic [3:0] rows;
    logic [3:0] cols;

    logic [3:0] key_code;
    logic       key_valid;

    // ------------------------------------------------------------
    // Instancia del DUT
    // ------------------------------------------------------------
    m3_keypad_reader dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .rows      (rows),
        .cols      (cols),
        .key_code  (key_code),
        .key_valid (key_valid)
    );

    // ------------------------------------------------------------
    // Reloj de simulación
    // Este reloj representa el clk_1khz que usaría el módulo.
    // Periodo = 1000 us => 1 kHz
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #500 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Tarea para esperar ciclos de reloj
    // ------------------------------------------------------------
    task automatic wait_cycles(input int cycles);
        begin
            repeat (cycles) @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // Tarea para presionar una tecla
    //
    // row_bit:
    // 0 = fila de 1,2,3,A
    // 1 = fila de 4,5,6,B
    // 2 = fila de 7,8,9,C
    // 3 = fila de *,0,#,D
    //
    // col_pattern:
    // columna activa esperada:
    // 1110 = columna 0
    // 1101 = columna 1
    // 1011 = columna 2
    // 0111 = columna 3
    // ------------------------------------------------------------
    task automatic press_key(
        input int         row_bit,
        input logic [3:0] col_pattern,
        input logic [3:0] expected_code,
        input string      key_name
    );

        int timeout;
        logic detected;

        begin
            detected = 1'b0;
            timeout  = 0;

            // Esperar a que el escáner llegue a la columna correcta
            while (cols != col_pattern && timeout < 100) begin
                @(posedge clk);
                timeout++;
            end

            if (timeout >= 100) begin
                $display("[ERROR] Timeout esperando columna para tecla %s", key_name);
            end

            // Presionar tecla: filas activas en bajo
            rows = 4'b1111;
            rows[row_bit] = 1'b0;

            // Esperar key_valid
            timeout = 0;
            while (!key_valid && timeout < 200) begin
                @(posedge clk);
                timeout++;
            end

            if (key_valid) begin
                detected = 1'b1;

                if (key_code == expected_code) begin
                    $display("[OK] Tecla %s detectada correctamente: key_code = %h", 
                             key_name, key_code);
                end 
                else begin
                    $display("[ERROR] Tecla %s: esperado = %h, obtenido = %h", 
                             key_name, expected_code, key_code);
                end
            end 
            else begin
                $display("[ERROR] Tecla %s no generó key_valid", key_name);
            end

            // Mantener presionada unos ciclos
            wait_cycles(10);

            // Soltar tecla
            rows = 4'b1111;

            // Esperar a que el sistema vuelva a reposo
            wait_cycles(20);
        end

    endtask

    // ------------------------------------------------------------
    // Secuencia principal de prueba
    // ------------------------------------------------------------
    initial begin
        $display("==========================================");
        $display(" Iniciando m3_keypad_reader_tb");
        $display("==========================================");

        // Estado inicial
        rst_n = 1'b0;
        rows  = 4'b1111;

        wait_cycles(5);

        rst_n = 1'b1;

        wait_cycles(10);

        // --------------------------------------------------------
        // Mapa físico del teclado:
        //
        //  1   2   3   A
        //  4   5   6   B
        //  7   8   9   C
        //  *   0   #   D
        //
        // Columna 0 -> cols = 1110
        // Columna 1 -> cols = 1101
        // Columna 2 -> cols = 1011
        // Columna 3 -> cols = 0111
        // --------------------------------------------------------

        // Fila 0
        press_key(0, 4'b1110, 4'h1, "1");
        press_key(0, 4'b1101, 4'h2, "2");
        press_key(0, 4'b1011, 4'h3, "3");
        press_key(0, 4'b0111, 4'hA, "A");

        // Fila 1
        press_key(1, 4'b1110, 4'h4, "4");
        press_key(1, 4'b1101, 4'h5, "5");
        press_key(1, 4'b1011, 4'h6, "6");
        press_key(1, 4'b0111, 4'hB, "B");

        // Fila 2
        press_key(2, 4'b1110, 4'h7, "7");
        press_key(2, 4'b1101, 4'h8, "8");
        press_key(2, 4'b1011, 4'h9, "9");
        press_key(2, 4'b0111, 4'hC, "C");

        // Fila 3
        press_key(3, 4'b1110, 4'hE, "*");
        press_key(3, 4'b1101, 4'h0, "0");
        press_key(3, 4'b1011, 4'hF, "#");
        press_key(3, 4'b0111, 4'hD, "D");

        $display("==========================================");
        $display(" Fin de m3_keypad_reader_tb");
        $display("==========================================");

        $finish;
    end

endmodule
