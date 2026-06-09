`timescale 1ns/1ps

module top_module_tb;

    // ============================================================
    // Señales del testbench
    // ============================================================

    logic clk;
    logic rst_n;

    logic [3:0] rows;
    logic [3:0] cols;

    logic [6:0] seg;
    logic [3:0] an;

    // ============================================================
    // Instancia del DUT
    // ============================================================

    top_module dut (
        .clk   (clk),
        .rst_n (rst_n),

        .rows  (rows),
        .cols  (cols),

        .seg   (seg),
        .an    (an)
    );

    // ============================================================
    // Acelerar divisor de reloj m1 para simulación
    // ============================================================

    defparam dut.u_m1_clk_divider.COUNTER_MAX = 2;

    // ============================================================
    // Reloj principal
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // 100 MHz para simulación
    end

    // ============================================================
    // Parámetros del teclado
    // ============================================================

    localparam COL_0 = 4'b1110;
    localparam COL_1 = 4'b1101;
    localparam COL_2 = 4'b1011;
    localparam COL_3 = 4'b0111;

    localparam ROW_0 = 4'b1110;
    localparam ROW_1 = 4'b1101;
    localparam ROW_2 = 4'b1011;
    localparam ROW_3 = 4'b0111;

    // Si alguna tecla no se detecta, sube este valor
    localparam int HOLD_CYCLES = 3000;

    // ============================================================
    // Esperar ciclos
    // ============================================================

    task automatic wait_cycles(input int cycles);
        begin
            repeat (cycles) @(posedge clk);
        end
    endtask

    // ============================================================
    // Presionar tecla física
    // ============================================================

    task automatic press_key(
        input logic [3:0] row_value,
        input logic [3:0] col_value,
        input string key_name
    );
        int timeout;
        begin
            $display("Presionando tecla %s", key_name);

            // Teclado liberado
            rows <= 4'b1111;

            // Esperar a que el lector active la columna deseada
            timeout = 0;
            while (cols !== col_value && timeout < 20000) begin
                @(posedge clk);
                timeout++;
            end

            if (timeout >= 20000) begin
                $display("[ERROR] Timeout esperando columna para tecla %s", key_name);
            end

            // Bajar la fila correspondiente
            rows <= row_value;

            // Mantener presionada la tecla
            wait_cycles(HOLD_CYCLES);

            // Soltar tecla
            rows <= 4'b1111;

            // Esperar liberación y antirrebote
            wait_cycles(HOLD_CYCLES);
        end
    endtask

    // ============================================================
    // Atajos de teclas
    // Distribución:
    //
    // 1  2  3  A
    // 4  5  6  B
    // 7  8  9  C
    // *  0  #  D
    // ============================================================

    task automatic key_1;     begin press_key(ROW_0, COL_0, "1"); end endtask
    task automatic key_2;     begin press_key(ROW_0, COL_1, "2"); end endtask
    task automatic key_3;     begin press_key(ROW_0, COL_2, "3"); end endtask
    task automatic key_A;     begin press_key(ROW_0, COL_3, "A"); end endtask

    task automatic key_4;     begin press_key(ROW_1, COL_0, "4"); end endtask
    task automatic key_5;     begin press_key(ROW_1, COL_1, "5"); end endtask
    task automatic key_6;     begin press_key(ROW_1, COL_2, "6"); end endtask
    task automatic key_B;     begin press_key(ROW_1, COL_3, "B"); end endtask

    task automatic key_7;     begin press_key(ROW_2, COL_0, "7"); end endtask
    task automatic key_8;     begin press_key(ROW_2, COL_1, "8"); end endtask
    task automatic key_9;     begin press_key(ROW_2, COL_2, "9"); end endtask
    task automatic key_C;     begin press_key(ROW_2, COL_3, "C"); end endtask

    task automatic key_STAR;  begin press_key(ROW_3, COL_0, "*"); end endtask
    task automatic key_0;     begin press_key(ROW_3, COL_1, "0"); end endtask
    task automatic key_HASH;  begin press_key(ROW_3, COL_2, "#"); end endtask
    task automatic key_D;     begin press_key(ROW_3, COL_3, "D"); end endtask

    // ============================================================
    // Revisar display_data interno
    // ============================================================

    task automatic check_display(
        input logic [15:0] expected,
        input string test_name
    );
        begin
            #1;

            if (dut.display_data == expected) begin
                $display("[OK] %s -> display_data = %h",
                         test_name, dut.display_data);
            end
            else begin
                $display("[ERROR] %s", test_name);
                $display("        Esperado: %h", expected);
                $display("        Obtenido: %h", dut.display_data);
            end
        end
    endtask

    // ============================================================
    // Esperar hasta que display_data tenga cierto valor
    // ============================================================

    task automatic wait_display(
        input logic [15:0] expected,
        input string test_name
    );
        int timeout;
        begin
            timeout = 0;

            while (dut.display_data !== expected && timeout < 200000) begin
                @(posedge clk);
                timeout++;
            end

            if (timeout >= 200000) begin
                $display("[ERROR] Timeout esperando display en: %s", test_name);
                $display("        Esperado: %h", expected);
                $display("        Obtenido: %h", dut.display_data);
            end
            else begin
                $display("[OK] %s -> display_data = %h",
                         test_name, dut.display_data);
            end
        end
    endtask

    // ============================================================
    // Secuencia principal
    // ============================================================

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);

        $display("==========================================");
        $display(" Iniciando top_module_tb");
        $display("==========================================");

        // Valores iniciales
        rst_n = 1'b0;
        rows  = 4'b1111;

        wait_cycles(20);

        rst_n = 1'b1;
        wait_cycles(2000);

        check_display(16'hCCCC, "Reset inicial");

        // ========================================================
        // Prueba 1: 15 / 3 = Q5 R0
        // ========================================================

        $display("\n--- Prueba 1: 15 / 3 ---");

        key_1();
        wait_display(16'hCCC1, "Ingresar 1");

        key_5();
        wait_display(16'hCC15, "Ingresar 15");

        key_A();
        wait_display(16'hCCCC, "Guardar A=15 y limpiar pantalla");

        key_3();
        wait_display(16'hCCC3, "Ingresar 3");

        key_B();
        wait_display(16'hCCCC, "Guardar B=3 y limpiar pantalla");

        key_D();
        wait_display(16'hCCC5, "D ejecuta 15/3 y muestra cociente 5");

        key_HASH();
        wait_display(16'hCCC0, "# muestra residuo 0");

        key_STAR();
        wait_display(16'hCCC5, "* vuelve a mostrar cociente 5");

        // ========================================================
        // Prueba 2: 13 / 4 = Q3 R1
        // ========================================================

        $display("\n--- Prueba 2: 13 / 4 ---");

        key_C();
        wait_display(16'hCCCC, "C limpia todo");

        key_1();
        wait_display(16'hCCC1, "Ingresar 1");

        key_3();
        wait_display(16'hCC13, "Ingresar 13");

        key_A();
        wait_display(16'hCCCC, "Guardar A=13");

        key_4();
        wait_display(16'hCCC4, "Ingresar 4");

        key_B();
        wait_display(16'hCCCC, "Guardar B=4");

        key_D();
        wait_display(16'hCCC3, "D ejecuta 13/4 y muestra cociente 3");

        key_HASH();
        wait_display(16'hCCC1, "# muestra residuo 1");

        // ========================================================
        // Prueba 3: 63 / 15 = Q4 R3
        // ========================================================

        $display("\n--- Prueba 3: 63 / 15 ---");

        key_C();
        wait_display(16'hCCCC, "C limpia todo");

        key_6();
        wait_display(16'hCCC6, "Ingresar 6");

        key_3();
        wait_display(16'hCC63, "Ingresar 63");

        key_A();
        wait_display(16'hCCCC, "Guardar A=63");

        key_1();
        wait_display(16'hCCC1, "Ingresar 1");

        key_5();
        wait_display(16'hCC15, "Ingresar 15");

        key_B();
        wait_display(16'hCCCC, "Guardar B=15");

        key_D();
        wait_display(16'hCCC4, "D ejecuta 63/15 y muestra cociente 4");

        key_HASH();
        wait_display(16'hCCC3, "# muestra residuo 3");

        // ========================================================
        // Prueba 4: división entre cero
        // 10 / 0 debe mostrar CEEE
        // ========================================================

        $display("\n--- Prueba 4: 10 / 0 ---");

        key_C();
        wait_display(16'hCCCC, "C limpia todo");

        key_1();
        wait_display(16'hCCC1, "Ingresar 1");

        key_0();
        wait_display(16'hCC10, "Ingresar 10");

        key_A();
        wait_display(16'hCCCC, "Guardar A=10");

        key_0();
        wait_display(16'hCCC0, "Ingresar 0");

        key_B();
        wait_display(16'hCCCC, "Guardar B=0");

        key_D();
        wait_display(16'hCEEE, "D ejecuta 10/0 y muestra error CEEE");

        // ========================================================
        // Prueba 5: 50 / 5 = Q10 R0
        // ========================================================

        $display("\n--- Prueba 5: 50 / 5 ---");

        key_C();
        wait_display(16'hCCCC, "C limpia todo");

        key_5();
        wait_display(16'hCCC5, "Ingresar 5");

        key_0();
        wait_display(16'hCC50, "Ingresar 50");

        key_A();
        wait_display(16'hCCCC, "Guardar A=50");

        key_5();
        wait_display(16'hCCC5, "Ingresar 5");

        key_B();
        wait_display(16'hCCCC, "Guardar B=5");

        key_D();
        wait_display(16'hCC10, "D ejecuta 50/5 y muestra cociente 10");

        key_HASH();
        wait_display(16'hCCC0, "# muestra residuo 0");

        key_STAR();
        wait_display(16'hCC10, "* vuelve a mostrar cociente 10");


        // ========================================================
        // Prueba 6: 48 / 8 = Q6 R0
        // ========================================================

        $display("\n--- Prueba 6: 48 / 8 ---");

        key_C();
        wait_display(16'hCCCC, "C limpia todo");

        key_4();
        wait_display(16'hCCC4, "Ingresar 4");

        key_8();
        wait_display(16'hCC48, "Ingresar 48");

        key_A();
        wait_display(16'hCCCC, "Guardar A=48");

        key_8();
        wait_display(16'hCCC8, "Ingresar 8");

        key_B();
        wait_display(16'hCCCC, "Guardar B=8");

        key_D();
        wait_display(16'hCCC6, "D ejecuta 48/8 y muestra cociente 6");

        key_HASH();
        wait_display(16'hCCC0, "# muestra residuo 0");

        key_STAR();
        wait_display(16'hCCC6, "* vuelve a mostrar cociente 6");

        $display("==========================================");
        $display(" Fin de top_module_tb");
        $display("==========================================");

        $finish;
    end

endmodule
