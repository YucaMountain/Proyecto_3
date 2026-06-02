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
    // Esperar ciclos de reloj
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
        input logic [5:0] dividend_in,
        input logic [3:0] divisor_in,
        input logic [5:0] expected_q,
        input logic [3:0] expected_r,
        input string      test_name
    );

        int timeout;

        begin
            $display("\n--- %s ---", test_name);

            // Colocar entradas
            @(posedge clk);
            dividend <= dividend_in;
            divisor  <= divisor_in;
            valid    <= 1'b1;

            // valid dura solo un ciclo
            @(posedge clk);
            valid    <= 1'b0;

            // Esperar done
            timeout = 0;
            while (!done && timeout < 20) begin
                @(posedge clk);
                timeout++;
            end

            if (timeout >= 20) begin
                $display("[ERROR] Timeout esperando done en %s", test_name);
            end
            else begin
                // Esperar un delta/ciclo pequeño para observar salidas registradas
                #1;

                if (quotient == expected_q && remainder == expected_r) begin
                    $display("[OK] %s: %0d / %0d = Q=%0d, R=%0d",
                             test_name, dividend_in, divisor_in, quotient, remainder);
                end
                else begin
                    $display("[ERROR] %s: %0d / %0d", 
                             test_name, dividend_in, divisor_in);
                    $display("        Esperado: Q=%0d, R=%0d", expected_q, expected_r);
                    $display("        Obtenido: Q=%0d, R=%0d", quotient, remainder);
                end
            end

            // Dejar pasar unos ciclos antes de la siguiente prueba
            wait_cycles(3);
        end

    endtask

    // ------------------------------------------------------------
    // Secuencia principal
    // ------------------------------------------------------------
    initial begin
        $display("==========================================");
        $display(" Iniciando m8_divisor_tb");
        $display("==========================================");

        // Valores iniciales
        rst_n    = 1'b0;
        valid    = 1'b0;
        dividend = 6'd0;
        divisor  = 4'd0;

        wait_cycles(5);

        // Soltar reset
        rst_n = 1'b1;
        wait_cycles(3);

        // --------------------------------------------------------
        // Casos de prueba principales
        // --------------------------------------------------------
        run_division(6'd15, 4'd3,  6'd5,  4'd0, "Division exacta 15 / 3");
        run_division(6'd13, 4'd4,  6'd3,  4'd1, "Division con residuo 13 / 4");
        run_division(6'd63, 4'd15, 6'd4,  4'd3, "Valor maximo 63 / 15");
        run_division(6'd6,  4'd9,  6'd0,  4'd6, "Divisor mayor que dividendo 6 / 9");
        run_division(6'd20, 4'd6,  6'd3,  4'd2, "Caso general 20 / 6");

        // --------------------------------------------------------
        // Casos borde
        // --------------------------------------------------------
        run_division(6'd0,  4'd5,  6'd0,  4'd0, "Cero entre numero 0 / 5");
        run_division(6'd1,  4'd1,  6'd1,  4'd0, "Uno entre uno 1 / 1");
        run_division(6'd63, 4'd1,  6'd63, 4'd0, "Division entre uno 63 / 1");

        // --------------------------------------------------------
        // Division entre cero
        // Este divisor devuelve Q=0, R=0 y done=1
        // --------------------------------------------------------
        run_division(6'd10, 4'd0,  6'd0,  4'd0, "Division entre cero 10 / 0");

        $display("==========================================");
        $display(" Fin de m8_divisor_tb");
        $display("==========================================");

        $finish;
    end

endmodule
