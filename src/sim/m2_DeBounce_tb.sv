`timescale 1ns / 1ps

module m2_DeBounce_tb;

    localparam CLK_PERIOD = 20;

    reg clk;
    reg rst_n;
    reg button_in;
    wire DB_out;

    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    m2_DeBounce uut (
        .clk   (clk),
        .rst_n (rst_n),
        .sw_in (button_in),
        .sw_out(DB_out)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    task reset_system;
    begin
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
        $display("Sistema reseteado");
    end
    endtask

    // Con pull-up: presionado = 0
    task press_button;
    begin
        $display("  Presionando botón...");
        button_in = 1'b0;
    end
    endtask

    // Con pull-up: liberado = 1
    task release_button;
    begin
        $display("  Liberando botón...");
        button_in = 1'b1;
    end
    endtask

    task wait_cycles;
        input integer cycles;
        integer i;
    begin
        for (i = 0; i < cycles; i = i + 1)
            @(posedge clk);
    end
    endtask

    task check_output;
        input expected;
        input [100:0] test_name;
    begin
        test_count = test_count + 1;
        #1;
        if (DB_out === expected) begin
            $display("  PASS: %s (salida=%b)", test_name, DB_out);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: %s (esperado=%b, obtenido=%b)", test_name, expected, DB_out);
            fail_count = fail_count + 1;
        end
    end
    endtask

    initial begin
        $display("============================================================");
        $display("Iniciando Testbench de m2_DeBounce");
        $display("============================================================");

        // reposo con pull-up
        button_in = 1'b1;

        reset_system();

        // Prueba 1
        $display("\n--- Prueba 1: botón presionado estable ---");
        press_button();
        wait_cycles(25);
        check_output(1'b0, "Boton presionado estable");

        release_button();
        wait_cycles(25);
        check_output(1'b1, "Boton liberado estable");

        // Prueba 2
        $display("\n--- Prueba 2: rebote corto ignorado ---");
        press_button();
        wait_cycles(5);
        release_button();
        wait_cycles(10);
        check_output(1'b1, "Rebote corto ignorado");

        // Prueba 3
        $display("\n--- Prueba 3: presion larga valida ---");
        press_button();
        wait_cycles(25);
        check_output(1'b0, "Presion larga valida");

        // Resumen
        $display("\n============================================================");
        $display("Pruebas totales: %0d", test_count);
        $display("Pruebas exitosas: %0d", pass_count);
        $display("Pruebas fallidas: %0d", fail_count);
        $display("============================================================");

        $finish;
    end

    initial begin
        $dumpfile("m2_DeBounce_tb.vcd");
        $dumpvars(0, m2_DeBounce_tb);
    end

endmodule
