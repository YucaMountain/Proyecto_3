`timescale 1ns / 1ps

module m6_seven_segment_driver_tb;

    reg         clk;
    reg         rst_n;
    reg  [15:0] hex_data;
    wire [6:0]  seg;
    wire [3:0]  an;

    integer errors;

    m6_seven_segment_driver uut (
        .clk     (clk),
        .rst_n   (rst_n),
        .hex_data(hex_data),
        .seg     (seg),
        .an      (an)
    );

    //============================================================
    // Reloj
    //============================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //============================================================
    // Función: patrón esperado de segmentos
    //============================================================
    function [6:0] expected_seg;
        input [3:0] digit;
        begin
            case (digit)
                4'h0: expected_seg = 7'b0111111;
                4'h1: expected_seg = 7'b0000110;
                4'h2: expected_seg = 7'b1011011;
                4'h3: expected_seg = 7'b1001111;
                4'h4: expected_seg = 7'b1100110;
                4'h5: expected_seg = 7'b1101101;
                4'h6: expected_seg = 7'b1111101;
                4'h7: expected_seg = 7'b0000111;
                4'h8: expected_seg = 7'b1111111;
                4'h9: expected_seg = 7'b1101111;
                4'hA: expected_seg = 7'b1110111;
                4'hB: expected_seg = 7'b1111100;
                4'hC: expected_seg = 7'b1000000;
                4'hD: expected_seg = 7'b1011110;
                4'hE: expected_seg = 7'b1111001;
                4'hF: expected_seg = 7'b1110001;
                default: expected_seg = 7'b1000000;
            endcase
        end
    endfunction

    //============================================================
    // Tarea: verificar un dígito
    // digit_pos:
    //   0 -> hex_data[3:0]
    //   1 -> hex_data[7:4]
    //   2 -> hex_data[11:8]
    //   3 -> hex_data[15:12]
    //============================================================
    task check_digit;
        input [1:0] digit_pos;
        input [3:0] expected_digit;
        reg [3:0] expected_an;
        reg [6:0] expected_segments;
    begin
        case (digit_pos)
            2'd0: expected_an = 4'b0001;
            2'd1: expected_an = 4'b0010;
            2'd2: expected_an = 4'b0100;
            2'd3: expected_an = 4'b1000;
            default: expected_an = 4'b0000;
        endcase

        expected_segments = expected_seg(expected_digit);

        wait(an == expected_an);
        #1;

        if (seg !== expected_segments) begin
            $display("✗ ERROR: digito %0d esperado=%h seg=%b obtenido=%b",
                     digit_pos, expected_digit, expected_segments, seg);
            errors = errors + 1;
        end else begin
            $display("✓ Digito %0d correcto: %h", digit_pos, expected_digit);
        end
    end
    endtask

    //============================================================
    // Reset
    //============================================================
    task reset_system;
    begin
        rst_n = 1'b0;
        hex_data = 16'h0000;
        repeat(4) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);
        $display("✓ Sistema reseteado");
    end
    endtask

    //============================================================
    // Test principal
    //============================================================
    initial begin
        errors = 0;

        $dumpfile("m6_seven_segment_driver_tb.vcd");
        $dumpvars(0, m6_seven_segment_driver_tb);

        $display("==================================================");
        $display("Iniciando testbench de m6_seven_segment_driver");
        $display("==================================================");

        reset_system();

        // -------------------------------------------------------
        // Prueba 1: 16'h1234
        // -------------------------------------------------------
        $display("\n--- Prueba 1: hex_data = 16'h1234 ---");
        hex_data = 16'h1234;
        repeat(8) @(posedge clk);

        check_digit(2'd0, 4'h4);
        check_digit(2'd1, 4'h3);
        check_digit(2'd2, 4'h2);
        check_digit(2'd3, 4'h1);

        // -------------------------------------------------------
        // Prueba 2: 16'hABCD
        // -------------------------------------------------------
        $display("\n--- Prueba 2: hex_data = 16'hABCD ---");
        hex_data = 16'hABCD;
        repeat(8) @(posedge clk);

        check_digit(2'd0, 4'hD);
        check_digit(2'd1, 4'hC);
        check_digit(2'd2, 4'hB);
        check_digit(2'd3, 4'hA);

        // -------------------------------------------------------
        // Prueba 3: 16'h0000
        // -------------------------------------------------------
        $display("\n--- Prueba 3: hex_data = 16'h0000 ---");
        hex_data = 16'h0000;
        repeat(8) @(posedge clk);

        check_digit(2'd0, 4'h0);
        check_digit(2'd1, 4'h0);
        check_digit(2'd2, 4'h0);
        check_digit(2'd3, 4'h0);

        // -------------------------------------------------------
        // Prueba 4: 16'hF0E1
        // -------------------------------------------------------
        $display("\n--- Prueba 4: hex_data = 16'hF0E1 ---");
        hex_data = 16'hF0E1;
        repeat(8) @(posedge clk);

        check_digit(2'd0, 4'h1);
        check_digit(2'd1, 4'hE);
        check_digit(2'd2, 4'h0);
        check_digit(2'd3, 4'hF);

        // -------------------------------------------------------
        // Resumen
        // -------------------------------------------------------
        $display("\n==================================================");
        if (errors == 0)
            $display("✅ TODAS LAS PRUEBAS PASARON");
        else
            $display("❌ SE ENCONTRARON %0d ERRORES", errors);
        $display("==================================================");

        #20;
        $finish;
    end

    initial begin
        $monitor("t=%0t hex_data=%h an=%b seg=%b", $time, hex_data, an, seg);
    end

endmodule
