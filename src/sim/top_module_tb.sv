`timescale 1ns/1ps

module top_module_tb;

    // ============================================================
    // Señales del DUT
    // ============================================================

    logic       clk;
    logic       rst_n;
    logic [3:0] rows;
    logic [3:0] cols;
    logic [6:0] seg;
    logic [3:0] an;

    // ============================================================
    // Instancia del top_module
    // ============================================================

    top_module dut (
        .clk   (clk),
        .rst_n (rst_n),
        .rows  (rows),
        .cols  (cols),
        .seg   (seg),
        .an    (an)
    );

    // Acelera el divisor de reloj para simulación
    defparam dut.u_clk_div.COUNTER_MAX = 2;

    // ============================================================
    // Reloj principal
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // 100 MHz en simulación
    end

    // ============================================================
    // Códigos físicos del teclado
    // ============================================================
    // Columnas activas en bajo
    // Columna 0 = 1110
    // Columna 1 = 1101
    // Columna 2 = 1011
    // Columna 3 = 0111
    //
    // Filas activas en bajo
    // Fila 0 = 1110
    // Fila 1 = 1101
    // Fila 2 = 1011
    // Fila 3 = 0111
    //
    // Teclado:
    // 1  2  3  A
    // 4  5  6  B
    // 7  8  9  C
    // *  0  #  D
    // ============================================================

    localparam COL_0 = 4'b1110;
    localparam COL_1 = 4'b1101;
    localparam COL_2 = 4'b1011;
    localparam COL_3 = 4'b0111;

    localparam ROW_0 = 4'b1110;
    localparam ROW_1 = 4'b1101;
    localparam ROW_2 = 4'b1011;
    localparam ROW_3 = 4'b0111;

    // ============================================================
    // Tareas auxiliares
    // ============================================================

    task automatic check_display(
        input logic [15:0] expected,
        input string msg
    );
        begin
            #1;
            if (dut.display_data_wire !== expected) begin
                $display("[ERROR] %s", msg);
                $display("Esperado: %h", expected);
                $display("Obtenido: %h", dut.display_data_wire);
                $display("Tiempo: %0t", $time);
                $finish;
            end
            else begin
                $display("[OK] %s -> display = %h", msg, dut.display_data_wire);
            end
        end
    endtask

    task automatic wait_display(
        input logic [15:0] expected,
        input string msg
    );
        integer i;
        begin
            for (i = 0; i < 300; i = i + 1) begin
                @(posedge clk);
                if (dut.display_data_wire === expected) begin
                    $display("[OK] %s -> display = %h", msg, dut.display_data_wire);
                    disable wait_display;
                end
            end

            $display("[ERROR] Timeout esperando display");
            $display("Mensaje: %s", msg);
            $display("Esperado: %h", expected);
            $display("Obtenido: %h", dut.display_data_wire);
            $display("Tiempo: %0t", $time);
            $finish;
        end
    endtask

    task automatic press_physical_key(
        input logic [3:0] target_col,
        input logic [3:0] target_row,
        input string key_name
    );
        integer i;
        begin
            $display("Presionando tecla %s", key_name);

            // Mantener tecla presionada varios ciclos
            for (i = 0; i < 120; i = i + 1) begin
                @(posedge clk);

                // Si el lector está escaneando la columna de la tecla,
                // la fila correspondiente baja.
                if (cols == target_col)
                    rows = target_row;
                else
                    rows = 4'b1111;
            end

            // Soltar tecla
            rows = 4'b1111;

            // Esperar un poco entre teclas
            repeat (40) @(posedge clk);
        end
    endtask

    // ============================================================
    // Tareas por tecla
    // ============================================================

    task automatic key_0(); begin press_physical_key(COL_1, ROW_3, "0"); end endtask
    task automatic key_1(); begin press_physical_key(COL_0, ROW_0, "1"); end endtask
    task automatic key_2(); begin press_physical_key(COL_1, ROW_0, "2"); end endtask
    task automatic key_3(); begin press_physical_key(COL_2, ROW_0, "3"); end endtask
    task automatic key_4(); begin press_physical_key(COL_0, ROW_1, "4"); end endtask
    task automatic key_5(); begin press_physical_key(COL_1, ROW_1, "5"); end endtask
    task automatic key_6(); begin press_physical_key(COL_2, ROW_1, "6"); end endtask
    task automatic key_7(); begin press_physical_key(COL_0, ROW_2, "7"); end endtask
    task automatic key_8(); begin press_physical_key(COL_1, ROW_2, "8"); end endtask
    task automatic key_9(); begin press_physical_key(COL_2, ROW_2, "9"); end endtask

    task automatic key_A(); begin press_physical_key(COL_3, ROW_0, "A"); end endtask
    task automatic key_B(); begin press_physical_key(COL_3, ROW_1, "B"); end endtask
    task automatic key_C(); begin press_physical_key(COL_3, ROW_2, "C"); end endtask
    task automatic key_D(); begin press_physical_key(COL_3, ROW_3, "D"); end endtask

    task automatic key_STAR(); begin press_physical_key(COL_0, ROW_3, "*"); end endtask
    task automatic key_HASH(); begin press_physical_key(COL_2, ROW_3, "#"); end endtask

    // ============================================================
    // Secuencia principal
    // ============================================================

    initial begin
        $display("==============================================");
        $display(" TESTBENCH top_module");
        $display("==============================================");

        // Inicialización
        rst_n = 1'b0;
        rows  = 4'b1111;

        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (20) @(posedge clk);

        wait_display(16'hCCCC, "Reset inicial limpia pantalla");

        // ========================================================
        // Prueba 1: 15 / 3 = Q5 R0
        // ========================================================

        $display("\n--- Prueba 1: 15 / 3 ---");

        key_C();
        wait_display(16'hCCCC, "C limpia pantalla");

        key_1();
        wait_display(16'hCCC1, "Ingresar 1");

        key_5();
        wait_display(16'hCC15, "Ingresar 15");

        key_A();
        wait_display(16'hCCCC, "A guarda dividendo 15 y limpia");

        key_3();
        wait_display(16'hCCC3, "Ingresar 3");

        key_B();
        wait_display(16'hCCCC, "B guarda divisor 3 y limpia");

        key_D();
        wait_display(16'hCCC5, "D ejecuta 15/3 y muestra cociente 5");

        key_STAR();
        wait_display(16'hCCC0, "* muestra residuo 0");

        key_HASH();
        wait_display(16'hCCC5, "# muestra cociente 5");

        // ========================================================
        // Prueba 2: 13 / 4 = Q3 R1
        // ========================================================

        $display("\n--- Prueba 2: 13 / 4 ---");

        key_C();
        wait_display(16'hCCCC, "C limpia pantalla");

        key_1();
        wait_display(16'hCCC1, "Ingresar 1");

        key_3();
        wait_display(16'hCC13, "Ingresar 13");

        key_A();
        wait_display(16'hCCCC, "A guarda dividendo 13 y limpia");

        key_4();
        wait_display(16'hCCC4, "Ingresar 4");

        key_B();
        wait_display(16'hCCCC, "B guarda divisor 4 y limpia");

        key_D();
        wait_display(16'hCCC3, "D ejecuta 13/4 y muestra cociente 3");

        key_STAR();
        wait_display(16'hCCC1, "* muestra residuo 1");

        key_HASH();
        wait_display(16'hCCC3, "# muestra cociente 3");

        // ========================================================
        // Prueba 3: 58 / 5 = Q11 R3
        // ========================================================

        $display("\n--- Prueba 3: 58 / 5 ---");

        key_C();
        wait_display(16'hCCCC, "C limpia pantalla");

        key_5();
        wait_display(16'hCCC5, "Ingresar 5");

        key_8();
        wait_display(16'hCC58, "Ingresar 58");

        key_A();
        wait_display(16'hCCCC, "A guarda dividendo 58 y limpia");

        key_5();
        wait_display(16'hCCC5, "Ingresar 5");

        key_B();
        wait_display(16'hCCCC, "B guarda divisor 5 y limpia");

        key_D();
        wait_display(16'hCC11, "D ejecuta 58/5 y muestra cociente 11");

        key_STAR();
        wait_display(16'hCCC3, "* muestra residuo 3");

        key_HASH();
        wait_display(16'hCC11, "# muestra cociente 11");

        // ========================================================
        // Prueba 4: 38 / 7 = Q5 R3
        // ========================================================

        $display("\n--- Prueba 4: 38 / 7 ---");

        key_C();
        wait_display(16'hCCCC, "C limpia pantalla");

        key_3();
        wait_display(16'hCCC3, "Ingresar 3");

        key_8();
        wait_display(16'hCC38, "Ingresar 38");

        key_A();
        wait_display(16'hCCCC, "A guarda dividendo 38 y limpia");

        key_7();
        wait_display(16'hCCC7, "Ingresar 7");

        key_B();
        wait_display(16'hCCCC, "B guarda divisor 7 y limpia");

        key_D();
        wait_display(16'hCCC5, "D ejecuta 38/7 y muestra cociente 5");

        key_STAR();
        wait_display(16'hCCC3, "* muestra residuo 3");

        key_HASH();
        wait_display(16'hCCC5, "# muestra cociente 5");

        // ========================================================
        // Prueba 5: 63 / 15 = Q4 R3
        // ========================================================

        $display("\n--- Prueba 5: 63 / 15 ---");

        key_C();
        wait_display(16'hCCCC, "C limpia pantalla");

        key_6();
        wait_display(16'hCCC6, "Ingresar 6");

        key_3();
        wait_display(16'hCC63, "Ingresar 63");

        key_A();
        wait_display(16'hCCCC, "A guarda dividendo 63 y limpia");

        key_1();
        wait_display(16'hCCC1, "Ingresar 1");

        key_5();
        wait_display(16'hCC15, "Ingresar 15");

        key_B();
        wait_display(16'hCCCC, "B guarda divisor 15 y limpia");

        key_D();
        wait_display(16'hCCC4, "D ejecuta 63/15 y muestra cociente 4");

        key_STAR();
        wait_display(16'hCCC3, "* muestra residuo 3");

        key_HASH();
        wait_display(16'hCCC4, "# muestra cociente 4");

        // ========================================================
        // Prueba 6: 20 / 4 = Q5 R0
        // ========================================================

        $display("\n--- Prueba 6: 20 / 4 ---");

        key_C();
        wait_display(16'hCCCC, "C limpia pantalla");

        key_2();
        wait_display(16'hCCC2, "Ingresar 2");

        key_0();
        wait_display(16'hCC20, "Ingresar 20");

        key_A();
        wait_display(16'hCCCC, "A guarda dividendo 20 y limpia");

        key_4();
        wait_display(16'hCCC4, "Ingresar 4");

        key_B();
        wait_display(16'hCCCC, "B guarda divisor 4 y limpia");

        key_D();
        wait_display(16'hCCC5, "D ejecuta 20/4 y muestra cociente 5");

        key_STAR();
        wait_display(16'hCCC0, "* muestra residuo 0");

        key_HASH();
        wait_display(16'hCCC5, "# muestra cociente 5");

        // ========================================================
        // Prueba 7: división entre cero
        // ========================================================

        $display("\n--- Prueba 7: 10 / 0 ---");

        key_C();
        wait_display(16'hCCCC, "C limpia pantalla");

        key_1();
        wait_display(16'hCCC1, "Ingresar 1");

        key_0();
        wait_display(16'hCC10, "Ingresar 10");

        key_A();
        wait_display(16'hCCCC, "A guarda dividendo 10 y limpia");

        key_0();
        wait_display(16'hCCC0, "Ingresar 0");

        key_B();
        wait_display(16'hCCCC, "B guarda divisor 0 y limpia");

        key_D();
        wait_display(16'hCEEE, "D detecta divisor cero y muestra error CEEE");

        // ========================================================
        // Final
        // ========================================================

        $display("\n==============================================");
        $display(" TODAS LAS PRUEBAS DEL top_module PASARON");
        $display("==============================================");

        $finish;
    end

endmodule