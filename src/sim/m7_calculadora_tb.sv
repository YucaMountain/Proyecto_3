`timescale 1ns/1ps

module m7_calculadora_tb;

    // ============================================================
    // Señales del DUT
    // ============================================================

    logic        clk;
    logic        rst_n;

    logic [3:0]  key_code;
    logic        key_valid;
    logic [15:0] current_display;

    logic        m4_clear;
    logic        m4_load;
    logic [15:0] m4_result_data;

    logic        div_valid;
    logic [5:0]  dividend_out;
    logic [3:0]  divisor_out;

    logic        div_done;
    logic [5:0]  quotient_in;
    logic [3:0]  remainder_in;

    // ============================================================
    // Códigos de teclas
    // ============================================================

    localparam KEY_A    = 4'hA;
    localparam KEY_B    = 4'hB;
    localparam KEY_C    = 4'hC;
    localparam KEY_D    = 4'hD;
    localparam KEY_STAR = 4'hE; // *
    localparam KEY_HASH = 4'hF; // #

    // ============================================================
    // Instancia del DUT
    // ============================================================

    m7_calculadora dut (
        .clk             (clk),
        .rst_n           (rst_n),

        .key_code        (key_code),
        .key_valid       (key_valid),
        .current_display (current_display),

        .m4_clear        (m4_clear),
        .m4_load         (m4_load),
        .m4_result_data  (m4_result_data),

        .div_valid       (div_valid),
        .dividend_out    (dividend_out),
        .divisor_out     (divisor_out),

        .div_done        (div_done),
        .quotient_in     (quotient_in),
        .remainder_in    (remainder_in)
    );

    // ============================================================
    // Reloj
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // Periodo = 10 ns
    end

    // ============================================================
    // Tareas auxiliares
    // ============================================================

    task automatic press_key(input logic [3:0] key);
        begin
            @(negedge clk);
            key_code  = key;
            key_valid = 1'b1;

            @(negedge clk);
            key_valid = 1'b0;
            key_code  = 4'h0;
        end
    endtask

    task automatic check_signal(
        input logic condition,
        input string message
    );
        begin
            if (condition) begin
                $display("[OK] %s", message);
            end
            else begin
                $display("[ERROR] %s", message);
                $display("Tiempo: %0t", $time);
                $finish;
            end
        end
    endtask

    task automatic save_A(
        input logic [15:0] display_value,
        input logic [5:0]  expected_A
    );
        begin
            current_display = display_value;
            press_key(KEY_A);

            #1;
            check_signal(m4_clear == 1'b1, "A activa m4_clear");
            check_signal(dut.reg_A == expected_A, "A guarda correctamente el dividendo");

            @(posedge clk);
            #1;
        end
    endtask

    task automatic save_B(
        input logic [15:0] display_value,
        input logic [3:0]  expected_B
    );
        begin
            current_display = display_value;
            press_key(KEY_B);

            #1;
            check_signal(m4_clear == 1'b1, "B activa m4_clear");
            check_signal(dut.reg_B == expected_B, "B guarda correctamente el divisor");

            @(posedge clk);
            #1;
        end
    endtask

    task automatic execute_division(
        input logic [5:0] expected_dividend,
        input logic [3:0] expected_divisor,
        input logic [5:0] quotient_value,
        input logic [3:0] remainder_value,
        input logic [15:0] expected_display,
        input string test_name
    );
        begin
            $display("\n--- Ejecutando prueba: %s ---", test_name);

            // Presionar D
            press_key(KEY_D);

            // Esperar estado ST_START_DIV
            @(posedge clk);
            #1;
            check_signal(dividend_out == expected_dividend, "dividend_out correcto");
            check_signal(divisor_out  == expected_divisor,  "divisor_out correcto");

            // Esperar estado ST_SEND_VALID
            @(posedge clk);
            #1;
            check_signal(div_valid == 1'b1, "div_valid se activa por un ciclo");

            // Preparar respuesta del divisor simulado
            quotient_in  = quotient_value;
            remainder_in = remainder_value;

            // Enviar done mientras m7 está esperando
            @(negedge clk);
            div_done = 1'b1;

            @(negedge clk);
            div_done = 1'b0;

            // Esperar captura del resultado
            @(posedge clk);
            #1;

            check_signal(m4_load == 1'b1, "m4_load se activa para mostrar resultado");
            check_signal(m4_result_data == expected_display, "D muestra el cociente esperado");
            check_signal(dut.last_quotient == quotient_value, "last_quotient guardado correctamente");
            check_signal(dut.last_remainder == remainder_value, "last_remainder guardado correctamente");

            @(posedge clk);
            #1;
        end
    endtask

    task automatic show_remainder(
        input logic [15:0] expected_display
    );
        begin
            press_key(KEY_STAR);

            #1;
            check_signal(m4_load == 1'b1, "* activa m4_load");
            check_signal(m4_result_data == expected_display, "* muestra residuo esperado");

            @(posedge clk);
            #1;
        end
    endtask

    task automatic show_quotient(
        input logic [15:0] expected_display
    );
        begin
            press_key(KEY_HASH);

            #1;
            check_signal(m4_load == 1'b1, "# activa m4_load");
            check_signal(m4_result_data == expected_display, "# muestra cociente esperado");

            @(posedge clk);
            #1;
        end
    endtask

    task automatic clear_system();
        begin
            press_key(KEY_C);

            #1;
            check_signal(m4_clear == 1'b1, "C activa m4_clear");
            check_signal(dut.reg_A == 6'd0, "C limpia reg_A");
            check_signal(dut.reg_B == 4'd0, "C limpia reg_B");
            check_signal(dut.last_quotient == 6'd0, "C limpia last_quotient");
            check_signal(dut.last_remainder == 4'd0, "C limpia last_remainder");

            @(posedge clk);
            #1;
        end
    endtask

    task automatic test_division_by_zero();
        begin
            $display("\n--- Ejecutando prueba: division entre cero ---");

            save_A(16'hCC10, 6'd10);
            save_B(16'hCCC0, 4'd0);

            press_key(KEY_D);

            @(posedge clk);
            #1;

            check_signal(m4_load == 1'b1, "Division entre cero activa m4_load");
            check_signal(m4_result_data == 16'hCEEE, "Division entre cero muestra CEEE");

            @(posedge clk);
            #1;
        end
    endtask

    task automatic test_invalid_A();
        begin
            $display("\n--- Ejecutando prueba: dividendo fuera de rango ---");

            current_display = 16'hCC64; // 64 > 63
            press_key(KEY_A);

            #1;
            check_signal(m4_load == 1'b1, "A invalido activa m4_load");
            check_signal(m4_result_data == 16'hCEEE, "A invalido muestra CEEE");

            @(posedge clk);
            #1;
        end
    endtask

    task automatic test_invalid_B();
        begin
            $display("\n--- Ejecutando prueba: divisor fuera de rango ---");

            current_display = 16'hCC16; // 16 > 15
            press_key(KEY_B);

            #1;
            check_signal(m4_load == 1'b1, "B invalido activa m4_load");
            check_signal(m4_result_data == 16'hCEEE, "B invalido muestra CEEE");

            @(posedge clk);
            #1;
        end
    endtask

    // ============================================================
    // Secuencia principal de pruebas
    // ============================================================

    initial begin
        $display("==============================================");
        $display(" TESTBENCH m7_calculadora");
        $display("==============================================");

        // Valores iniciales
        rst_n           = 1'b0;
        key_code        = 4'h0;
        key_valid       = 1'b0;
        current_display = 16'hCCCC;

        div_done        = 1'b0;
        quotient_in     = 6'd0;
        remainder_in    = 4'd0;

        // Reset
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        check_signal(m4_result_data == 16'hCCCC, "Reset inicial correcto");

        // ========================================================
        // Prueba 1: 15 / 3 = Q5 R0
        // ========================================================
        clear_system();

        save_A(16'hCC15, 6'd15);
        save_B(16'hCCC3, 4'd3);

        execute_division(
            6'd15,
            4'd3,
            6'd5,
            4'd0,
            16'hCCC5,
            "15 / 3 = Q5 R0"
        );

        show_remainder(16'hCCC0);
        show_quotient(16'hCCC5);

        // ========================================================
        // Prueba 2: 13 / 4 = Q3 R1
        // ========================================================
        clear_system();

        save_A(16'hCC13, 6'd13);
        save_B(16'hCCC4, 4'd4);

        execute_division(
            6'd13,
            4'd4,
            6'd3,
            4'd1,
            16'hCCC3,
            "13 / 4 = Q3 R1"
        );

        show_remainder(16'hCCC1);
        show_quotient(16'hCCC3);

        // ========================================================
        // Prueba 3: 58 / 5 = Q11 R3
        // ========================================================
        clear_system();

        save_A(16'hCC58, 6'd58);
        save_B(16'hCCC5, 4'd5);

        execute_division(
            6'd58,
            4'd5,
            6'd11,
            4'd3,
            16'hCC11,
            "58 / 5 = Q11 R3"
        );

        show_remainder(16'hCCC3);
        show_quotient(16'hCC11);

        // ========================================================
        // Prueba 4: 38 / 7 = Q5 R3
        // ========================================================
        clear_system();

        save_A(16'hCC38, 6'd38);
        save_B(16'hCCC7, 4'd7);

        execute_division(
            6'd38,
            4'd7,
            6'd5,
            4'd3,
            16'hCCC5,
            "38 / 7 = Q5 R3"
        );

        show_remainder(16'hCCC3);
        show_quotient(16'hCCC5);

        // ========================================================
        // Prueba 5: 63 / 15 = Q4 R3
        // ========================================================
        clear_system();

        save_A(16'hCC63, 6'd63);
        save_B(16'hCC15, 4'd15);

        execute_division(
            6'd63,
            4'd15,
            6'd4,
            4'd3,
            16'hCCC4,
            "63 / 15 = Q4 R3"
        );

        show_remainder(16'hCCC3);
        show_quotient(16'hCCC4);

        // ========================================================
        // Prueba 6: 20 / 4 = Q5 R0
        // ========================================================
        clear_system();

        save_A(16'hCC20, 6'd20);
        save_B(16'hCCC4, 4'd4);

        execute_division(
            6'd20,
            4'd4,
            6'd5,
            4'd0,
            16'hCCC5,
            "20 / 4 = Q5 R0"
        );

        show_remainder(16'hCCC0);
        show_quotient(16'hCCC5);

        // ========================================================
        // Pruebas de error
        // ========================================================
        clear_system();
        test_division_by_zero();

        clear_system();
        test_invalid_A();

        clear_system();
        test_invalid_B();

        $display("\n==============================================");
        $display(" TODAS LAS PRUEBAS DE m7_calculadora PASARON");
        $display("==============================================");

        $finish;
    end

endmodule