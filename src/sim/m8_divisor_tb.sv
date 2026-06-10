`timescale 1ns/1ps

module m8_divisor_tb;

    // ============================================================
    // Señales del DUT
    // ============================================================

    logic       clk;
    logic       rst_n;

    logic       valid;
    logic [5:0] dividend;
    logic [3:0] divisor;

    logic       done;
    logic [5:0] quotient;
    logic [3:0] remainder;

    // ============================================================
    // Instancia del DUT
    // ============================================================

    m8_divisor dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid     (valid),
        .dividend  (dividend),
        .divisor   (divisor),
        .done      (done),
        .quotient  (quotient),
        .remainder (remainder)
    );

    // ============================================================
    // Reloj
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // Periodo de 10 ns
    end

    // ============================================================
    // Tarea para verificar una división
    // ============================================================

    task automatic run_division(
        input logic [5:0] dividend_value,
        input logic [3:0] divisor_value,
        input logic [5:0] expected_quotient,
        input logic [3:0] expected_remainder,
        input string      test_name
    );
        integer timeout_counter;
        begin
            $display("\n--- Prueba: %s ---", test_name);
            $display("Operacion: %0d / %0d", dividend_value, divisor_value);

            // Colocar operandos
            @(negedge clk);
            dividend = dividend_value;
            divisor  = divisor_value;
            valid    = 1'b1;

            // Valid activo solo un ciclo
            @(negedge clk);
            valid = 1'b0;

            // Esperar done con timeout
            timeout_counter = 0;
            while (done !== 1'b1 && timeout_counter < 20) begin
                @(posedge clk);
                timeout_counter = timeout_counter + 1;
            end

            if (done !== 1'b1) begin
                $display("[ERROR] Timeout: done nunca se activo");
                $finish;
            end

            // Revisar resultado
            #1;
            if (quotient !== expected_quotient || remainder !== expected_remainder) begin
                $display("[ERROR] Resultado incorrecto");
                $display("Esperado: Q=%0d R=%0d", expected_quotient, expected_remainder);
                $display("Obtenido: Q=%0d R=%0d", quotient, remainder);
                $finish;
            end
            else begin
                $display("[OK] Resultado correcto: Q=%0d R=%0d", quotient, remainder);
            end

            // Esperar un ciclo para que done vuelva a cero
            @(posedge clk);
            #1;
            if (done !== 1'b0) begin
                $display("[ERROR] done no regreso a cero");
                $finish;
            end
            else begin
                $display("[OK] done regreso a cero");
            end

            // Limpiar entradas visualmente
            @(negedge clk);
            dividend = 6'd0;
            divisor  = 4'd0;
        end
    endtask

    // ============================================================
    // Secuencia principal
    // ============================================================

    initial begin
        $display("==============================================");
        $display(" TESTBENCH m8_divisor");
        $display("==============================================");

        // Valores iniciales
        rst_n    = 1'b0;
        valid    = 1'b0;
        dividend = 6'd0;
        divisor  = 4'd0;

        // Reset
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // ========================================================
        // Pruebas normales
        // ========================================================

        run_division(6'd15, 4'd3,  6'd5,  4'd0, "15 / 3 = 5 residuo 0");
        run_division(6'd13, 4'd4,  6'd3,  4'd1, "13 / 4 = 3 residuo 1");
        run_division(6'd50, 4'd5,  6'd10, 4'd0, "50 / 5 = 10 residuo 0");
        run_division(6'd48, 4'd8,  6'd6,  4'd0, "48 / 8 = 6 residuo 0");
        run_division(6'd58, 4'd5,  6'd11, 4'd3, "58 / 5 = 11 residuo 3");
        run_division(6'd38, 4'd7,  6'd5,  4'd3, "38 / 7 = 5 residuo 3");
        run_division(6'd58, 4'd11, 6'd5,  4'd3, "58 / 11 = 5 residuo 3");

        // ========================================================
        // Casos límite
        // ========================================================

        run_division(6'd63, 4'd15, 6'd4,  4'd3, "63 / 15 = 4 residuo 3");
        run_division(6'd63, 4'd1,  6'd63, 4'd0, "63 / 1 = 63 residuo 0");
        run_division(6'd0,  4'd5,  6'd0,  4'd0, "0 / 5 = 0 residuo 0");
        run_division(6'd1,  4'd1,  6'd1,  4'd0, "1 / 1 = 1 residuo 0");

        // ========================================================
        // Dividendo menor que divisor
        // ========================================================

        run_division(6'd6,  4'd9,  6'd0,  4'd6, "6 / 9 = 0 residuo 6");

        // ========================================================
        // Caso que falló en FPGA
        // ========================================================

        run_division(6'd20, 4'd4,  6'd5,  4'd0, "20 / 4 = 5 residuo 0");

        // ========================================================
        // División entre cero
        // ========================================================

        run_division(6'd10, 4'd0,  6'd0,  4'd0, "10 / 0 = salida protegida");

        $display("\n==============================================");
        $display(" TODAS LAS PRUEBAS DE m8_divisor PASARON");
        $display("==============================================");

        $finish;
    end

endmodule