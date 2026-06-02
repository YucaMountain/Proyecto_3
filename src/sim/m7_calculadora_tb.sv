`timescale 1ns/1ps

module m7_calculadora_tb;

    // ------------------------------------------------------------
    // Señales del testbench
    // ------------------------------------------------------------
    logic clk;
    logic rst_n;

    logic [3:0]  key_code;
    logic        key_valid;
    logic [15:0] current_display;

    logic        m4_clear;
    logic        m4_load;
    logic [15:0] m4_result_data;

    // ------------------------------------------------------------
    // Instancia del DUT
    // ------------------------------------------------------------
    m7_calculadora dut (
        .clk             (clk),
        .rst_n           (rst_n),

        .key_code        (key_code),
        .key_valid       (key_valid),
        .current_display (current_display),

        .m4_clear        (m4_clear),
        .m4_load         (m4_load),
        .m4_result_data  (m4_result_data)
    );

    // ------------------------------------------------------------
    // Reloj
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // Periodo = 10 ns
    end

    // ------------------------------------------------------------
    // Constantes de teclas
    // ------------------------------------------------------------
    localparam KEY_A     = 4'hA;
    localparam KEY_B     = 4'hB;
    localparam KEY_C     = 4'hC;
    localparam KEY_D     = 4'hD;
    localparam KEY_STAR  = 4'hE; // *
    localparam KEY_HASH  = 4'hF; // #

    // ------------------------------------------------------------
    // Esperar ciclos
    // ------------------------------------------------------------
    task automatic wait_cycles(input int cycles);
        begin
            repeat (cycles) @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // Presionar una tecla por un ciclo
    // ------------------------------------------------------------
    task automatic press_key(input logic [3:0] code);
        begin
            @(posedge clk);
            key_code  <= code;
            key_valid <= 1'b1;

            @(posedge clk);
            key_valid <= 1'b0;
            key_code  <= 4'h0;

            wait_cycles(1);
        end
    endtask

    // ------------------------------------------------------------
    // Esperar hasta que m7 cargue algo hacia m4
    // ------------------------------------------------------------
    task automatic wait_m4_load;
        int timeout;
        begin
            timeout = 0;

            while (!m4_load && timeout < 100) begin
                @(posedge clk);
                timeout++;
            end

            if (timeout >= 100) begin
                $display("[ERROR] Timeout esperando m4_load");
            end
        end
    endtask

    // ------------------------------------------------------------
    // Verificar resultado cargado al m4
    // ------------------------------------------------------------
    task automatic check_m4_result(
        input logic [15:0] expected,
        input string test_name
    );
        begin
            if (m4_result_data == expected) begin
                $display("[OK] %s -> m4_result_data = %h", 
                         test_name, m4_result_data);
            end
            else begin
                $display("[ERROR] %s -> esperado = %h, obtenido = %h",
                         test_name, expected, m4_result_data);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Verificar pulso de limpieza
    // ------------------------------------------------------------
    task automatic check_m4_clear(input string test_name);
        begin
            @(posedge clk);
            if (m4_clear) begin
                $display("[OK] %s -> m4_clear activo", test_name);
            end
            else begin
                $display("[ERROR] %s -> m4_clear no se activó", test_name);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Guardar A desde current_display
    // ------------------------------------------------------------
    task automatic save_A(
        input logic [15:0] display_value,
        input string label
    );
        begin
            current_display <= display_value;
            press_key(KEY_A);
            check_m4_clear({"Guardar A: ", label});
            wait_cycles(2);
        end
    endtask

    // ------------------------------------------------------------
    // Guardar B desde current_display
    // ------------------------------------------------------------
    task automatic save_B(
        input logic [15:0] display_value,
        input string label
    );
        begin
            current_display <= display_value;
            press_key(KEY_B);
            check_m4_clear({"Guardar B: ", label});
            wait_cycles(2);
        end
    endtask

    // ------------------------------------------------------------
    // Ejecutar división
    // ------------------------------------------------------------
    task automatic execute_division;
        begin
            press_key(KEY_D);
            wait_m4_load();
            wait_cycles(2);
        end
    endtask

    // ------------------------------------------------------------
    // Mostrar cociente con *
    // ------------------------------------------------------------
    task automatic show_quotient;
        begin
            press_key(KEY_STAR);
            wait_m4_load();
            wait_cycles(2);
        end
    endtask

    // ------------------------------------------------------------
    // Mostrar residuo con #
    // ------------------------------------------------------------
    task automatic show_remainder;
        begin
            press_key(KEY_HASH);
            wait_m4_load();
            wait_cycles(2);
        end
    endtask

    // ------------------------------------------------------------
    // Secuencia principal
    // ------------------------------------------------------------
    initial begin
        $display("==========================================");
        $display(" Iniciando m7_calculadora_tb");
        $display("==========================================");

        // Valores iniciales
        rst_n           = 1'b0;
        key_code        = 4'h0;
        key_valid       = 1'b0;
        current_display = 16'hCCCC;

        wait_cycles(5);

        rst_n = 1'b1;
        wait_cycles(5);

        // --------------------------------------------------------
        // Nota importante sobre current_display:
        //
        // El m4 guarda los dígitos desplazando hacia la derecha.
        // Por ejemplo:
        //   Si se presiona 1 y luego 5, display_data queda 16'h51CC.
        //
        // El m7 interpreta:
        //   [7:4]   = centenas
        //   [11:8]  = decenas
        //   [15:12] = unidades
        //
        // Por eso:
        //   16'h51CC representa el número 15.
        //   16'h31CC representa el número 13.
        //   16'h36CC representa el número 63.
        // --------------------------------------------------------

        // ========================================================
        // Prueba 1: 15 / 3 = 5, residuo 0
        // ========================================================
        $display("\n--- Prueba 1: 15 / 3 ---");

        save_A(16'h51CC, "15");
        save_B(16'h3CCC, "3");

        execute_division();
        check_m4_result(16'hCCC5, "15 / 3 debe mostrar cociente 5");

        show_remainder();
        check_m4_result(16'hCCC0, "15 / 3 debe mostrar residuo 0");

        show_quotient();
        check_m4_result(16'hCCC5, "Volver a mostrar cociente 5");

        // ========================================================
        // Prueba 2: 13 / 4 = 3, residuo 1
        // ========================================================
        $display("\n--- Prueba 2: 13 / 4 ---");

        press_key(KEY_C);
        wait_cycles(2);

        save_A(16'h31CC, "13");
        save_B(16'h4CCC, "4");

        execute_division();
        check_m4_result(16'hCCC3, "13 / 4 debe mostrar cociente 3");

        show_remainder();
        check_m4_result(16'hCCC1, "13 / 4 debe mostrar residuo 1");

        // ========================================================
        // Prueba 3: 63 / 15 = 4, residuo 3
        // ========================================================
        $display("\n--- Prueba 3: 63 / 15 ---");

        press_key(KEY_C);
        wait_cycles(2);

        save_A(16'h36CC, "63");
        save_B(16'h51CC, "15");

        execute_division();
        check_m4_result(16'hCCC4, "63 / 15 debe mostrar cociente 4");

        show_remainder();
        check_m4_result(16'hCCC3, "63 / 15 debe mostrar residuo 3");

        // ========================================================
        // Prueba 4: 6 / 9 = 0, residuo 6
        // ========================================================
        $display("\n--- Prueba 4: 6 / 9 ---");

        press_key(KEY_C);
        wait_cycles(2);

        save_A(16'h6CCC, "6");
        save_B(16'h9CCC, "9");

        execute_division();
        check_m4_result(16'hCCC0, "6 / 9 debe mostrar cociente 0");

        show_remainder();
        check_m4_result(16'hCCC6, "6 / 9 debe mostrar residuo 6");

        // ========================================================
        // Prueba 5: División entre cero
        // 10 / 0 -> CEEE
        // ========================================================
        $display("\n--- Prueba 5: 10 / 0 ---");

        press_key(KEY_C);
        wait_cycles(2);

        save_A(16'h01CC, "10");
        save_B(16'h0CCC, "0");

        execute_division();
        check_m4_result(16'hCEEE, "10 / 0 debe mostrar error CEEE");

        $display("==========================================");
        $display(" Fin de m7_calculadora_tb");
        $display("==========================================");

        $finish;
    end

endmodule
