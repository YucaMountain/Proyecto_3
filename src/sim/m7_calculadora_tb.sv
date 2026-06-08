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

    logic        div_valid;
    logic [5:0]  dividend_out;
    logic [3:0]  divisor_out;

    logic        div_done;
    logic [5:0]  quotient_in;
    logic [3:0]  remainder_in;

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
        .m4_result_data  (m4_result_data),

        .div_valid       (div_valid),
        .dividend_out    (dividend_out),
        .divisor_out     (divisor_out),

        .div_done        (div_done),
        .quotient_in     (quotient_in),
        .remainder_in    (remainder_in)
    );

    // ------------------------------------------------------------
    // Reloj
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // Periodo = 10 ns
    end

    // ------------------------------------------------------------
    // Códigos de teclado
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
    // Simular respuesta del divisor externo m8
    // ------------------------------------------------------------
    task automatic respond_divisor(
        input logic [5:0] q,
        input logic [3:0] r
    );
        begin
            // Esperar a que m7 active div_valid
            wait (div_valid == 1'b1);
            @(posedge clk);

            // Simular que el divisor tarda algunos ciclos
            wait_cycles(6);

            quotient_in  <= q;
            remainder_in <= r;
            div_done     <= 1'b1;

            @(posedge clk);
            div_done     <= 1'b0;

            wait_cycles(2);
        end
    endtask

    // ------------------------------------------------------------
    // Revisar m4_load y resultado
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
                $display("[ERROR] %s", test_name);
                $display("        Esperado: %h", expected);
                $display("        Obtenido: %h", m4_result_data);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Revisar div_valid y operandos enviados hacia m8
    // ------------------------------------------------------------
    task automatic check_div_start(
        input logic [5:0] expected_A,
        input logic [3:0] expected_B,
        input string test_name
    );
        begin
            wait (div_valid == 1'b1);
            #1;

            if (dividend_out == expected_A && divisor_out == expected_B) begin
                $display("[OK] %s -> A=%0d, B=%0d, div_valid=%b",
                         test_name, dividend_out, divisor_out, div_valid);
            end
            else begin
                $display("[ERROR] %s", test_name);
                $display("        Esperado: A=%0d, B=%0d", expected_A, expected_B);
                $display("        Obtenido: A=%0d, B=%0d", dividend_out, divisor_out);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Guardar A desde current_display
    // ------------------------------------------------------------
    task automatic save_A(
    input logic [15:0] display_value,
    input logic [5:0]  expected_A,
    input string       label
);
    begin
        current_display <= display_value;

        @(posedge clk);
        key_code  <= KEY_A;
        key_valid <= 1'b1;

        @(posedge clk);
        #1;

        if (m4_clear) begin
            $display("[OK] Guardar A=%s -> m4_clear activo", label);
        end
        else begin
            $display("[ERROR] Guardar A=%s -> m4_clear no se activó", label);
        end

        key_valid <= 1'b0;
        key_code  <= 4'h0;

        wait_cycles(2);
    end
endtask

    // ------------------------------------------------------------
    // Guardar B desde current_display
    // ------------------------------------------------------------
    task automatic save_B(
    input logic [15:0] display_value,
    input logic [3:0]  expected_B,
    input string       label
);
    begin
        current_display <= display_value;

        @(posedge clk);
        key_code  <= KEY_B;
        key_valid <= 1'b1;

        @(posedge clk);
        #1;

        if (m4_clear) begin
            $display("[OK] Guardar B=%s -> m4_clear activo", label);
        end
        else begin
            $display("[ERROR] Guardar B=%s -> m4_clear no se activó", label);
        end

        key_valid <= 1'b0;
        key_code  <= 4'h0;

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

        div_done        = 1'b0;
        quotient_in     = 6'd0;
        remainder_in    = 4'd0;

        wait_cycles(5);

        rst_n = 1'b1;
        wait_cycles(5);

        // --------------------------------------------------------
        // Nota sobre current_display:
        //
        // Con el m4 corregido, normalmente:
        // 15 se representa como 16'hCC15
        // 13 se representa como 16'hCC13
        // 63 se representa como 16'hCC63
        //
        // Si tu m4 todavía deja 15 como 16'h51CC,
        // hay que cambiar estos valores.
        // --------------------------------------------------------

        // ========================================================
        // Prueba 1: guardar A=15, B=3, ejecutar D
        // Simulamos que m8 responde Q=5, R=0
        // ========================================================
        $display("\n--- Prueba 1: 15 / 3 ---");

        save_A(16'hCC15, 6'd15, "15");
        save_B(16'hCCC3, 4'd3,  "3");

        fork
            begin
                press_key(KEY_D);
                check_div_start(6'd15, 4'd3, "D debe iniciar division 15/3");
            end
            begin
                respond_divisor(6'd5, 4'd0);
            end
        join

        wait_m4_load();
        check_m4_result(16'hCCC5, "15/3 debe cargar cociente 5");

        // Mostrar residuo con #
        press_key(KEY_HASH);
        wait_m4_load();
        check_m4_result(16'hCCC0, "15/3 debe cargar residuo 0");

        // Mostrar cociente con *
        press_key(KEY_STAR);
        wait_m4_load();
        check_m4_result(16'hCCC5, "15/3 debe volver a cargar cociente 5");

        // ========================================================
        // Prueba 2: 13 / 4 = Q3, R1
        // ========================================================
        $display("\n--- Prueba 2: 13 / 4 ---");

        press_key(KEY_C);
        wait_cycles(3);

        save_A(16'hCC13, 6'd13, "13");
        save_B(16'hCCC4, 4'd4,  "4");

        fork
            begin
                press_key(KEY_D);
                check_div_start(6'd13, 4'd4, "D debe iniciar division 13/4");
            end
            begin
                respond_divisor(6'd3, 4'd1);
            end
        join

        wait_m4_load();
        check_m4_result(16'hCCC3, "13/4 debe cargar cociente 3");

        press_key(KEY_HASH);
        wait_m4_load();
        check_m4_result(16'hCCC1, "13/4 debe cargar residuo 1");

        // ========================================================
        // Prueba 3: 63 / 15 = Q4, R3
        // ========================================================
        $display("\n--- Prueba 3: 63 / 15 ---");

        press_key(KEY_C);
        wait_cycles(3);

        save_A(16'hCC63, 6'd63, "63");
        save_B(16'hCC15, 4'd15, "15");

        fork
            begin
                press_key(KEY_D);
                check_div_start(6'd63, 4'd15, "D debe iniciar division 63/15");
            end
            begin
                respond_divisor(6'd4, 4'd3);
            end
        join

        wait_m4_load();
        check_m4_result(16'hCCC4, "63/15 debe cargar cociente 4");

        press_key(KEY_HASH);
        wait_m4_load();
        check_m4_result(16'hCCC3, "63/15 debe cargar residuo 3");

        // ========================================================
        // Prueba 4: division entre cero
        // No debe activar div_valid, debe cargar error CEEE
        // ========================================================
        $display("\n--- Prueba 4: 10 / 0 ---");

        press_key(KEY_C);
        wait_cycles(3);

        save_A(16'hCC10, 6'd10, "10");
        save_B(16'hCCC0, 4'd0,  "0");

        press_key(KEY_D);
        wait_m4_load();
        check_m4_result(16'hCEEE, "10/0 debe cargar error CEEE");

        $display("==========================================");
        $display(" Fin de m7_calculadora_tb");
        $display("==========================================");

        $finish;
    end

endmodule
