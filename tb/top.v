module top
    #(
        parameter DEF_SEED          = 300    ,     //! Semilla por defecto
        parameter VALID_TO_LOCK     = 5      ,     //! Cantidad de Datos Validos para activar bloqueo
        parameter INVALID_TO_UNLOCK = 3            //! Cantidad de Datos Invalidos para desactivar bloqueo
    )
    (
        output wire [15 : 0] o_LFSR          ,     //! Salida de generador LFSR
        output               o_lock          ,     //! Bandera de Bloqueo
        input       [15 : 0] i_seed          ,     //! Entrada de Semilla
        input                i_valid         ,     //! Señal para habilitar generador LFSR
        input                i_clk           ,     //! Entrada de Reloj
        input                i_rst           ,     //! Entrada de Reset asincrono
        input                i_soft_reset    ,     //! Entrada de Reset sincrono
        input                i_corrupt             //! Señal para corromper datos                             
    );

    wire            [15 : 0] lfsr_check_in   ;     //! Cable de entrada del checker

    lfsr_gen                                       //! Instancia del generador LFSR
    #(
        .DEF_SEED         (DEF_SEED         )
    )
    u_lfsr_gen
    (
        .o_LFSR           (o_LFSR           ),
        .i_clk            (i_clk            ),
        .i_rst            (i_rst            ),
        .i_seed           (i_seed           ),
        .i_valid          (i_valid          ),
        .i_soft_reset     (i_soft_reset     )    
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
        .i_rst            (i_rst            ),
        .i_seed           (i_seed           ),
        .i_valid          (i_valid          ),
        .i_soft_reset     (i_soft_reset     )
    );

    // Si la señal para corromper datos esta habilitada, se asigna a la entrada del checker la salida del generador con el ultimo bit invertido
    // Si la señal para corromper datos esta inhabilitada, se asigna a la entrada del checker la salida del generador
    assign lfsr_check_in = i_corrupt ? {o_LFSR[15 : 1] , ~o_LFSR[0]} : o_LFSR;

endmodule
