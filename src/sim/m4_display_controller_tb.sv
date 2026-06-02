`timescale 1ns/1ps

module m4_display_controller_tb;

    // ------------------------------------------------------------
    // Señales del testbench
    // ------------------------------------------------------------
    logic clk;
    logic rst_n;

    logic [3:0] key_code;
    logic       key_valid;

    logic        force_reset;
    logic        force_load;
    logic [15:0] data_to_load;

    logic [15:0] display_data;

    // ------------------------------------------------------------
    // Instancia del DUT
    // ------------------------------------------------------------
    m4_display_controller dut (
        .clk          (clk),
        .rst_n        (rst_n),

        .key_code     (key_code),
        .key_valid    (key_valid),

        .force_reset  (force_reset),
        .force_load   (force_load),
        .data_to_load (data_to_load),

        .display_data (display_data)
    );

    // ------------------------------------------------------------
    // Generación de reloj
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // Periodo = 10 ns
    end

    // ------------------------------------------------------------
    // Tarea para esperar ciclos de reloj
    // ------------------------------------------------------------
    task automatic wait_cycles(input int cycles);
        begin
            repeat (cycles) @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // Tarea para presionar una tecla
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
    // Tarea para aplicar force_reset
    // ------------------------------------------------------------
    task automatic apply_force_reset;
        begin
            @(posedge clk);
            force_reset <= 1'b1;

            @(posedge clk);
            force_reset <= 1'b0;

            wait_cycles(1);
        end
    endtask

    // ------------------------------------------------------------
    // Tarea para aplicar force_load
    // ------------------------------------------------------------
    task automatic apply_force_load(input logic [15:0] value);
        begin
            @(posedge clk);
            data_to_load <= value;
            force_load   <= 1'b1;

            @(posedge clk);
            force_load   <= 1'b0;

            wait_cycles(1);
        end
    endtask

    // ------------------------------------------------------------
    // Tarea para verificar display_data
    // ------------------------------------------------------------
    task automatic check_display(
        input logic [15:0] expected,
        input string test_name
    );
        begin
            if (display_data == expected) begin
                $display("[OK] %s -> display_data = %h", test_name, display_data);
            end
            else begin
                $display("[ERROR] %s -> esperado = %h, obtenido = %h",
                         test_name, expected, display_data);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Secuencia principal de prueba
    // ------------------------------------------------------------
    initial begin
        $display("==========================================");
        $display(" Iniciando m4_display_controller_tb");
        $display("==========================================");

        // Valores iniciales
        rst_n        = 1'b0;
        key_code     = 4'h0;
        key_valid    = 1'b0;
        force_reset  = 1'b0;
        force_load   = 1'b0;
        data_to_load = 16'h0000;

        wait_cycles(3);

        // --------------------------------------------------------
        // Prueba 1: reset físico
        // --------------------------------------------------------
        rst_n = 1'b1;
        wait_cycles(1);

        check_display(16'hCCCC, "Reset físico debe limpiar pantalla");

        // --------------------------------------------------------
        // Prueba 2: ingresar un dígito
        // display inicial: CCCC
        // tecla 1 -> 1CCC
        // --------------------------------------------------------
        press_key(4'h1);
        check_display(16'h1CCC, "Ingresar tecla 1");

        // --------------------------------------------------------
        // Prueba 3: ingresar segundo dígito
        // tecla 2 -> 21CC
        // --------------------------------------------------------
        press_key(4'h2);
        check_display(16'h21CC, "Ingresar tecla 2");

        // --------------------------------------------------------
        // Prueba 4: ingresar tercer dígito
        // tecla 3 -> 321C
        // --------------------------------------------------------
        press_key(4'h3);
        check_display(16'h321C, "Ingresar tecla 3");

        // --------------------------------------------------------
        // Prueba 5: intentar ingresar cuarto dígito
        // digit_count ya llegó a 3, entonces debe ignorarse
        // tecla 4 -> se mantiene 321C
        // --------------------------------------------------------
        press_key(4'h4);
        check_display(16'h321C, "Intentar ingresar cuarto dígito");

        // --------------------------------------------------------
        // Prueba 6: tecla no numérica A
        // Debe ignorarse
        // --------------------------------------------------------
        press_key(4'hA);
        check_display(16'h321C, "Tecla A no debe modificar display");

        // --------------------------------------------------------
        // Prueba 7: tecla C borra pantalla
        // --------------------------------------------------------
        press_key(4'hC);
        check_display(16'hCCCC, "Tecla C debe borrar pantalla");

        // --------------------------------------------------------
        // Prueba 8: force_load carga resultado desde m7
        // --------------------------------------------------------
        apply_force_load(16'hCCC5);
        check_display(16'hCCC5, "force_load debe cargar CCC5");

        // --------------------------------------------------------
        // Prueba 9: después de force_load, no debería aceptar más dígitos
        // porque digit_count queda en 3
        // --------------------------------------------------------
        press_key(4'h9);
        check_display(16'hCCC5, "Después de force_load debe ignorar dígitos");

        // --------------------------------------------------------
        // Prueba 10: force_reset limpia pantalla
        // --------------------------------------------------------
        apply_force_reset();
        check_display(16'hCCCC, "force_reset debe limpiar pantalla");

        // --------------------------------------------------------
        // Prueba 11: cargar código de error CEEE
        // --------------------------------------------------------
        apply_force_load(16'hCEEE);
        check_display(16'hCEEE, "force_load debe cargar código de error CEEE");

        $display("==========================================");
        $display(" Fin de m4_display_controller_tb");
        $display("==========================================");

        $finish;
    end

endmodule
