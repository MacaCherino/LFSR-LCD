module top
    #(
        parameter DEF_SEED          = 300    ,     //! Semilla por defecto
        parameter VALID_TO_LOCK     = 5      ,     //! Cantidad de Datos Validos para activar bloqueo
        parameter INVALID_TO_UNLOCK = 3            //! Cantidad de Datos Invalidos para desactivar bloqueo
    )
    (
        input                i_clk                 //! Entrada de Reloj                        
    );

    wire                     o_lock          ;     //! Bandera de Bloqueo
    wire            [15 : 0] i_seed          ;     //! Entrada de Semilla
    wire                     i_valid         ;     //! Señal para habilitar generador LFSR
    wire                     i_rst           ;     //! Entrada de Reset asincrono
    wire                     i_soft_reset    ;     //! Entrada de Reset sincrono
    wire                     i_corrupt       ;     //! Señal para corromper datos        

    wire            [15 : 0] lfsr_check_in   ;     //! Cable de entrada del checker
    wire            [15 : 0] lfsr_gen_out    ;     //! Cable de salida del generador


    lfsr_gen                                       //! Instancia del generador LFSR
    #(
        .DEF_SEED         (DEF_SEED         )
    )
    u_lfsr_gen
    (
        .o_LFSR           (lfsr_gen_out     ),
        .i_clk            (i_clk            ),
        .i_rst            (~i_rst            ),
        .i_seed           (i_seed           ),
        .i_valid          (i_valid          ),
        .i_soft_reset     (~i_soft_reset     )    
    );
    
    lfsr_checker                                   //! Instancia del checker LFSR
    #(
        .DEF_SEED         (DEF_SEED         ),
        .VALID_TO_LOCK    (VALID_TO_LOCK    ),
        .INVALID_TO_UNLOCK(INVALID_TO_UNLOCK)   
    )
    u_lfsr_checker
    (
        .o_lock           (o_lock           ),
        .i_LFSR           (lfsr_check_in    ),
        .i_clk            (i_clk            ),
        .i_rst            (~i_rst            ),
        .i_seed           (i_seed           ),
        .i_valid          (i_valid          ),
        .i_soft_reset     (~i_soft_reset     )
    );

    // Si la señal para corromper datos esta habilitada, se asigna a la entrada del checker la salida del generador con el ultimo bit invertido
    // Si la señal para corromper datos esta inhabilitada, se asigna a la entrada del checker la salida del generador
    assign lfsr_check_in = i_corrupt ? {lfsr_gen_out[15 : 1] , ~lfsr_gen_out[0]} : lfsr_gen_out;

    vio                                            //! Instancia de VIO
        u_vio
            (
            .clk_0       (i_clk       ),
            .probe_in0_0 (o_lock      ),
            .probe_out0_0(i_valid     ),
            .probe_out1_0(i_corrupt   ),
            .probe_out2_0(i_rst       ),
            .probe_out3_0(i_soft_reset),
            .probe_out4_0(i_seed      )
            );

    ila                                            //! Instancia de ILA
        u_ila
            (
            .clk_0       (i_clk       ),
            .probe0_0    (o_lock      )
            );

endmodule
