module lfsr_gen
    #(
        parameter DEF_SEED  = 300                                                           //! Semilla por defecto
    )
    (
        output reg [15 : 0]   o_LFSR                                                    ,   //! Salida de generador LFSR
        input      [15 : 0]   i_seed                                                    ,   //! Entrada de Semilla
        input                 i_valid                                                   ,   //! Señal para habilitar generador LFSR
        input                 i_clk                                                     ,   //! Entrada de Reloj
        input                 i_rst                                                     ,   //! Entrada de Reset asincrono
        input                 i_soft_reset                                                  //! Entrada de Reset sincrono
    );

    wire feedback           = o_LFSR[15] ^ (o_LFSR[14 : 0] == 'd0)                      ;   //! Retroalimentacion de LFSR

    always @(posedge i_clk or posedge i_rst) begin

        if (i_rst) begin
            o_LFSR         <= DEF_SEED                                                  ;   //  Setear semilla inicial
        end else begin

            if (i_soft_reset) begin
                o_LFSR     <= i_seed                                                    ;   //  Setear semilla inicial
            end else if (i_valid) begin                                                     //  Si esta habilitada la generacion de LFSR
                //  Generar LFSR (Galois)
                o_LFSR[0 ] <= feedback                                                  ;
                o_LFSR[1 ] <= o_LFSR[0 ]                                                ;
                o_LFSR[2 ] <= o_LFSR[1 ] ^ feedback                                     ;
                o_LFSR[3 ] <= o_LFSR[2 ] ^ feedback                                     ;
                o_LFSR[4 ] <= o_LFSR[3 ]                                                ;
                o_LFSR[5 ] <= o_LFSR[4 ] ^ feedback                                     ;
                o_LFSR[6 ] <= o_LFSR[5 ]                                                ;
                o_LFSR[7 ] <= o_LFSR[6 ]                                                ;
                o_LFSR[8 ] <= o_LFSR[7 ]                                                ;    
                o_LFSR[9 ] <= o_LFSR[8 ]                                                ;
                o_LFSR[10] <= o_LFSR[9 ]                                                ;
                o_LFSR[11] <= o_LFSR[10]                                                ;
                o_LFSR[12] <= o_LFSR[11]                                                ;
                o_LFSR[13] <= o_LFSR[12]                                                ;
                o_LFSR[14] <= o_LFSR[13]                                                ;
                o_LFSR[15] <= o_LFSR[14]                                                ;

            end else begin                                                                  //  Si no esta habilitada la generacion de LFSR
                o_LFSR     <= o_LFSR                                                    ;   //  Mantener el mismo valor de LFSR
            end

        end

    end

endmodule
