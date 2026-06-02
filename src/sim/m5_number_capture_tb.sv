`timescale 1ns/1ps

module m5_number_capture_tb;

    // ------------------------------------------------------------
    // Señales del testbench
    // ------------------------------------------------------------
    logic clk;
    logic rst_n;

    logic [3:0] key_code;
    logic       key_valid;

    logic enable;
    logic clear;

    logic [5:0] number;
    logic       digit_done;
    logic       overflow;

    // ------------------------------------------------------------
    // Instancia del DUT
    // Para esta prueba se usa:
    // WIDTH      = 6
    // MAX_VALUE  = 63
    // MAX_DIGITS = 2
    // ------------------------------------------------------------
    m5_number_capture #(
        .WIDTH(6),
        .MAX_VALUE(63),
        .MAX_DIGITS(2)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),

        .key_code   (key_code),
        .key_valid  (key_valid),

        .enable     (enable),
        .clear      (clear),

        .number     (number),
        .digit_done (digit_done),
        .overflow   (overflow)
    );

    // ------------------------------------------------------------
    // Generación de reloj
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // Periodo = 10 ns
    end

    // ------------------------------------------------------------
    // Esperar ciclos de reloj
    // ------------------------------------------------------------
    task automatic wait_cycles(input int cycles);
        begin
            repeat (cycles) @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // Presionar una tecla numérica
    // key_valid dura 1 ciclo
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
    // Aplicar clear por un ciclo
    // ------------------------------------------------------------
    task automatic apply_clear;
        begin
            @(posedge clk);
            clear <= 1'b1;

            @(posedge clk);
            clear <= 1'b0;

            wait_cycles(1);
        end
    endtask

    // ------------------------------------------------------------
    // Verificar valor de number
    // ------------------------------------------------------------
    task automatic check_number(
        input logic [5:0] expected,
        input string test_name
    );
        begin
            if (number == expected) begin
                $display("[OK] %s -> number = %0d", test_name, number);
            end
            else begin
                $display("[ERROR] %s -> esperado = %0d, obtenido = %0d",
                         test_name, expected, number);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Verificar overflow
    // ------------------------------------------------------------
    task automatic check_overflow(
        input logic expected,
        input string test_name
    );
        begin
            if (overflow == expected) begin
                $display("[OK] %s -> overflow = %b", test_name, overflow);
            end
            else begin
                $display("[ERROR] %s -> overflow esperado = %b, obtenido = %b",
                         test_name, expected, overflow);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Verificar digit_done
    // ------------------------------------------------------------
    task automatic check_digit_done(
        input logic expected,
        input string test_name
    );
        begin
            if (digit_done == expected) begin
                $display("[OK] %s -> digit_done = %b", test_name, digit_done);
            end
            else begin
                $display("[ERROR] %s -> digit_done esperado = %b, obtenido = %b",
                         test_name, expected, digit_done);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Secuencia principal
    // ------------------------------------------------------------
    initial begin
        $display("==========================================");
        $display(" Iniciando m5_number_capture_tb");
        $display("==========================================");

        // Valores iniciales
        rst_n     = 1'b0;
        key_code  = 4'h0;
        key_valid = 1'b0;
        enable    = 1'b0;
        clear     = 1'b0;

        wait_cycles(3);

        // --------------------------------------------------------
        // Prueba 1: reset físico
        // --------------------------------------------------------
        rst_n = 1'b1;
        wait_cycles(1);

        check_number(6'd0, "Reset físico debe limpiar number");
        check_overflow(1'b0, "Reset físico debe limpiar overflow");

        // --------------------------------------------------------
        // Prueba 2: si enable = 0, no debe capturar
        // --------------------------------------------------------
        enable = 1'b0;
        press_key(4'd5);
        check_number(6'd0, "Con enable=0 no debe capturar tecla 5");

        // --------------------------------------------------------
        // Prueba 3: capturar número 6
        // --------------------------------------------------------
        enable = 1'b1;
        press_key(4'd6);
        check_number(6'd6, "Capturar primer dígito 6");

        // --------------------------------------------------------
        // Prueba 4: capturar segundo dígito para formar 63
        // --------------------------------------------------------
        press_key(4'd3);
        check_number(6'd63, "Capturar segundo dígito 3 para formar 63");
        check_overflow(1'b0, "63 está dentro del rango permitido");

        // --------------------------------------------------------
        // Prueba 5: intentar ingresar tercer dígito
        // MAX_DIGITS = 2, entonces debe ignorarse
        // --------------------------------------------------------
        press_key(4'd4);
        check_number(6'd63, "Tercer dígito debe ignorarse por MAX_DIGITS=2");

        // --------------------------------------------------------
        // Prueba 6: clear debe borrar captura
        // --------------------------------------------------------
        apply_clear();
        check_number(6'd0, "clear debe limpiar number");
        check_overflow(1'b0, "clear debe limpiar overflow");

        // --------------------------------------------------------
        // Prueba 7: overflow con 99
        // Primer dígito 9 se acepta.
        // Segundo dígito 9 produciría 99, mayor que 63.
        // number debe quedarse en 9 y overflow debe activarse.
        // --------------------------------------------------------
        press_key(4'd9);
        check_number(6'd9, "Capturar primer dígito 9");

        press_key(4'd9);
        check_number(6'd9, "99 no debe aceptarse porque supera MAX_VALUE=63");
        check_overflow(1'b1, "99 debe activar overflow");

        // --------------------------------------------------------
        // Prueba 8: clear después de overflow
        // --------------------------------------------------------
        apply_clear();
        check_number(6'd0, "clear después de overflow limpia number");
        check_overflow(1'b0, "clear después de overflow limpia overflow");

        // --------------------------------------------------------
        // Prueba 9: tecla no numérica no debe capturar
        // --------------------------------------------------------
        press_key(4'hA);
        check_number(6'd0, "Tecla A no debe capturarse como número");

        // --------------------------------------------------------
        // Prueba 10: capturar número 15
        // --------------------------------------------------------
        press_key(4'd1);
        press_key(4'd5);
        check_number(6'd15, "Capturar número 15");

        $display("==========================================");
        $display(" Fin de m5_number_capture_tb");
        $display("==========================================");

        $finish;
    end

endmodule
