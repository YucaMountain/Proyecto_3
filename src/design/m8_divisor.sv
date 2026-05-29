module m8_sumador (
    input  [9:0] A,
    input  [9:0] B,
    output [10:0] SUM
);

// Simplemente sumamos A y B. El resultado es de 11 bits para manejar el posible carry.

    assign SUM = A + B;

endmodule
