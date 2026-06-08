`timescale 1ns/1ps

module m8_divisor_tb;

    // ------------------------------------------------------------
    // Señales del testbench
    // ------------------------------------------------------------
    logic clk;
    logic rst_n;

    logic       valid;
    logic [5:0] dividend;
    logic [3:0] divisor;

    logic       done;
    logic [5:0] quotient;
    logic [3:0] remainder;

    // ------------------------------------------------------------
    // Instancia del DUT
    // ------------------------------------------------------------
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

    // ------------------------------------------------------------
    // Reloj
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // Periodo = 10 ns
    end

    // ------------------------------------------------------------
    // Esperar ciclos
    // ------------------------------------------------------------
    task automatic wait_cycles(input int cycles);
        begin
            repeat (cycles) @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // Ejecutar una división
    // ------------------------------------------------------------
    task automatic run_division(
        input logic [5:0] dividend_value,
        input logic [3:0] divisor_value,
        input logic [5:0] expected_quotient,
        input logic [3:0] expected_remainder,
        input string      test_name
    );
        int timeout;

        begin
            $display("------------------------------------------");
            $display("Prueba: %s", test_name);
            $display("Operacion: %0d / %0d", dividend_value, divisor_value);

            // Colocar datos
            @(posedge clk);
            dividend <= dividend_value;
            divisor  <= divisor_value;
            valid    <= 1'b1;

            // valid dura solo 1 ciclo
            @(posedge clk);
            valid <= 1'b0;

            // Esperar done
            timeout = 0;

            while (!done && timeout < 50) begin
                @(posedge clk);
                timeout++;
            end

            if (timeout >= 50) begin
                $display("[ERROR] Timeout esperando done");
            end
            else begin
                #1;

                if ((quotient == expected_quotient) &&
                    (remainder == expected_remainder)) begin

                    $display("[OK] %s", test_name);
                    $display("     Cociente esperado = %0d, obtenido = %0d",
                             expected_quotient, quotient);
                    $display("     Residuo esperado  = %0d, obtenido = %0d",
                             expected_remainder, remainder);
                end
                else begin
                    $display("[ERROR] %s", test_name);
                    $display("        Cociente esperado = %0d, obtenido = %0d",
                             expected_quotient, quotient);
                    $display("        Residuo esperado  = %0d, obtenido = %0d",
                             expected_remainder, remainder);
                end
            end

            wait_cycles(3);
        end
    endtask

    // ------------------------------------------------------------
    // Secuencia principal
    // ------------------------------------------------------------
    initial begin
        $dumpfile("m8_divisor_tb.vcd");
        $dumpvars(0, m8_divisor_tb);

        $display("==========================================");
        $display(" Iniciando m8_divisor_tb");
        $display("==========================================");

        // Valores iniciales
        rst_n    = 1'b0;
        valid    = 1'b0;
        dividend = 6'd0;
        divisor  = 4'd0;

        wait_cycles(5);

        // Quitar reset
        rst_n = 1'b1;
        wait_cycles(5);

        // --------------------------------------------------------
        // Pruebas principales
        // --------------------------------------------------------

        run_division(6'd15, 4'd3,  6'd5,  4'd0, "15 / 3 = 5 residuo 0");

        run_division(6'd13, 4'd4,  6'd3,  4'd1, "13 / 4 = 3 residuo 1");

        run_division(6'd63, 4'd15, 6'd4,  4'd3, "63 / 15 = 4 residuo 3");

        run_division(6'd6,  4'd9,  6'd0,  4'd6, "6 / 9 = 0 residuo 6");

        run_division(6'd20, 4'd6,  6'd3,  4'd2, "20 / 6 = 3 residuo 2");

        run_division(6'd0,  4'd5,  6'd0,  4'd0, "0 / 5 = 0 residuo 0");

        run_division(6'd1,  4'd1,  6'd1,  4'd0, "1 / 1 = 1 residuo 0");

        run_division(6'd63, 4'd1,  6'd63, 4'd0, "63 / 1 = 63 residuo 0");

        // División entre cero
        // En tu m8, por protección, devuelve Q=0 y R=0
        run_division(6'd10, 4'd0,  6'd0,  4'd0, "10 / 0 = proteccion Q0 R0");

        $display("==========================================");
        $display(" Fin de m8_divisor_tb");
        $display("==========================================");

        $finish;
    end

endmodule
