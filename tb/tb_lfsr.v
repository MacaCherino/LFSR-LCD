`timescale 10ns / 100ps //#1 es 10 ns

module tb_lfsr ();

    // Parametros de Generador y Checker LFSR
    parameter                     DEF_SEED          = 300                       ;   //! Semilla por defecto
    parameter                     VALID_TO_LOCK     = 5                         ;   //! Cantidad de Datos Validos para activar bloqueo
    parameter                     INVALID_TO_UNLOCK = 3                         ;   //! Cantidad de Datos Invalidos para desactivar bloqueo

    // Entradas y Salidas de Generador y Checker
    wire [15 : 0]                 o_LFSR                                        ;   //! Salida de generador LFSR
    wire                          o_lock                                        ;   //! Bandera de Bloqueo
    reg  [15 : 0]                 i_seed                                        ;   //! Entrada de Semilla
    reg                           i_valid                                       ;   //! Señal para habilitar generador LFSR
    reg                           i_clk                                         ;   //! Entrada de Reloj
    reg                           i_rst                                         ;   //! Entrada de Reset asincrono
    reg                           i_soft_reset                                  ;   //! Entrada de Reset sincrono
    reg                           i_corrupt                                     ;   //! Señal para corromper datos     

    // Registros Auxiliares
    reg  [14 : 0]                 random_time_sync                              ;   //! Registro para almacenar el tiempo random del reset sincrono (entre 1 us y 250 us)
    reg  [14 : 0]                 random_time_async                             ;   //! Registro para almacenar el tiempo random del reset asincrono (entre 1 us y 250 us)
    reg  [16 : 0]                 period                                        ;   //! Registro para almacenar el periodo del generador
    reg  [15 : 0]                 current_seed                                  ;   //! Registro para almacenar la semilla actual
    reg  [2  : 0]                 count_valid                                   ;   //! Contador de datos validos consecutivos
    reg  [1  : 0]                 count_invalid                                 ;   //! Contador de datos invalidos consecutivos
    reg  [2  : 0]                 valid_limit                                   ;   //! Cantidad de datos validos consecutivos que se deben generar durante la simulacion
    reg  [1  : 0]                 invalid_limit                                 ;   //! Cantidad de datos invalidos consecutivos que se deben generar durante la simulacion
    reg  [31 : 0]                 random_reset                                  ;   //! Numero aleatorio que determinara si se debe realizar un reset
    reg                           random_reset_flag                             ;   //! Indicador de reset aleatorio

    // Definicion de macros
    `define TEST4                                                                   //! Tipo de test
    // TEST1                      Trafico Valido
    // TEST2                      4 Datos validos, 1 invalido
    // TEST3                      Ya lockeado, 2 datos invalidos, 1 valido
    // TEST4                      5 datos validos, 3 invalidos 

    `define NO_RAND_RST                                                                //! Habilitar/Deshabilitar resets aleatorios
    // RAND_RST                   Habilita Resets en momentos aleatorios
    // NO_RAND_RST                Deshabilita resets en momentos aleatorios

    initial begin

        // Inicializacion de entradas
        i_clk                          =  1'b1                                  ;
        i_seed                         = 16'b0                                  ;
        i_valid                        =  1'b0                                  ;
        i_soft_reset                   =  1'b0                                  ;
        i_rst                          =  1'b0                                  ;
        i_corrupt                      =  1'b0                                  ;

        // Inicializacion de registros
        period                         = 17'b0                                  ;
        random_time_async              = 15'b0                                  ;
        random_time_sync               = 15'b0                                  ;
        current_seed                   = 16'b0                                  ;
        count_invalid                  =  2'b0                                  ;
        count_valid                    =  3'b0                                  ;
        random_reset                   = 32'b0                                  ;
        random_reset_flag              =  1'b0                                  ;
        valid_limit                    =  3'b0                                  ;
        invalid_limit                  =  2'b0                                  ;

        // Reset Inicial
        i_soft_reset                   =  1'b1                                  ;
        i_rst                          =  1'b1                                  ;
        #100
        @(posedge i_clk)                                                        ;
        i_soft_reset                   =  1'b0                                  ;
        i_rst                          =  1'b0                                  ;
        
        // Reset Asincrono
        rst_async()                                                             ;
        current_seed                   = DEF_SEED                               ;
        $display("\n--- Test con seed fija: %d ---", DEF_SEED)                  ;
        start_sim()                                                             ;

        #500000
        $finish                                                                 ;
    end


    always #0.5 i_clk = ~i_clk                                                  ;   //! Periodo de clock 10 ns (100 MHz)

    always @(posedge i_clk) begin                                                   //! Determina un valor aleatorio para i_valid, indica si se debe realizar un reset en un momento aleatorio, cuenta la cantidad de datos validos e invalidos que se envian y determina si el siguiente dato se debe corromper, al cumplirse un periodo del generador lo imprime 
        
        if (i_rst || i_soft_reset) begin
            
            i_valid                   <=  1'b0                                  ;
            i_corrupt                 <=  1'b0                                  ;
            count_valid               <=  3'b0                                  ;
            count_invalid             <=  2'b0                                  ;
            random_reset              <= 32'b0                                  ;
            random_reset_flag         <=  1'b0                                  ;
            period                    <= 17'b0                                  ;

        end else begin

            i_valid                   <= $urandom_range(0,1)                    ;

            `ifdef RAND_RST
            begin
                random_reset          <= $urandom_range(0,10000000)             ;
                if (random_reset > 9999950) begin
                    random_reset_flag <=  1'b1                                  ;
                end else begin
                    random_reset_flag <=  1'b0                                  ;
                end
            end
            `endif

            if (i_valid) begin

                if (count_valid < valid_limit) begin
                    i_corrupt         <=  1'b0                                  ;
                    count_valid       <= count_valid + 1                        ; 
                    count_invalid     <= count_invalid                          ;
                end else if (count_invalid < invalid_limit) begin
                    i_corrupt         <=  1'b1                                  ;
                    count_valid       <= count_valid                            ;
                    count_invalid     <= count_invalid + 1                      ;
                end else begin
                    i_corrupt         <=  1'b0                                  ;
                    count_valid       <=   'd1                                  ;
                    count_invalid     <=   'd0                                  ;
                end

                period                <= period + 1                             ;

                if (o_LFSR == current_seed && period > 0) begin
                    $display("Periodicidad del Generador: %d", period)          ;
                    period            <= 17'b1                                  ;
                end

            end else begin
                period                <= period                                 ;
            end
            
        end
    end 

    always @(o_lock) begin                                                          //! Imprime el estado de bloqueo al producirse un cambio en este
        $display("Cambio de estado o_lock: %d", o_lock)                         ;
    end      

    always @(posedge random_reset_flag) begin                                       //! Genera una nueva semilla y realiza un reset sincrono al levantarse la bandera de reset en un momento random
        $display("Reset")                                                       ;
        random_seed()                                                           ;
        rst_sync()                                                              ;
        current_seed                   = i_seed                                 ;
        $display("\n--- Test con seed aleatoria: %d ---", current_seed)         ;
        random_reset_flag              = 1'b0                                   ;
        start_sim()                                                             ;
    end

    // Task para definir cantidad valores validos e invalidos que se generaran durante la simulacion
    task start_sim                                                              ;
    begin
        `ifdef TEST1
            // Test flujo correcto por al menos un periodo de generador
            begin
                valid_limit            = VALID_TO_LOCK                          ;
                invalid_limit          = 0                                      ;
            end
        `elsif TEST2
            // Test 4 datos correctos, 1 incorrecto
            begin
                valid_limit            = VALID_TO_LOCK - 1                      ;
                invalid_limit          = 1                                      ;
            end
        `elsif TEST3
            // Test alcanzar bloqueo y luego mandar 1 dato correcto y 2 correctos
            begin
                valid_limit            = VALID_TO_LOCK                          ;
                invalid_limit          = 0                                      ;
                #5000
                valid_limit            = 1                                      ;
                invalid_limit          = INVALID_TO_UNLOCK - 1                  ;
            end
        `elsif TEST4
            // Test 5 datos correctos y 3 incorrectos
            begin
                valid_limit            = VALID_TO_LOCK                          ;
                invalid_limit          = INVALID_TO_UNLOCK                      ;
            end
        `endif
    end
    endtask

    // Task para cambiar el puerto de entrada i_seed
    task random_seed                                                            ;
        i_seed                         = $urandom_range(0,65535)                ;
    endtask

    // Task para generar un reset asincrono durante un tiempo random entre 1 us y 250 us
    task rst_async                                                              ;
        begin
            random_time_async          = $urandom_range(100,25000)              ;
            i_rst                      = 1'b1                                   ;
            #random_time_async                                                  ;
            i_rst                      = 1'b0                                   ;
        end
    endtask

    // Task para generar un reset sincrono durante un tiempo random entre 1 us y 250 us
    task rst_sync                                                               ;
        begin
            random_time_sync           = $urandom_range(100,25000)              ;
            @(posedge i_clk)                                                    ;
            i_soft_reset               = 1'b1                                   ;
            #random_time_sync                                                   ;
            @(posedge i_clk)                                                    ;
            i_soft_reset               = 1'b0                                   ;
        end
    endtask


    top                                         //! Instancia de modulo top (generador y checker)
    #(
        .DEF_SEED         (DEF_SEED         ),
        .VALID_TO_LOCK    (VALID_TO_LOCK    ),
        .INVALID_TO_UNLOCK(INVALID_TO_UNLOCK)   
    )
    u_top
    (
        .o_LFSR           (o_LFSR           ),
        .o_lock           (o_lock           ),
        .i_clk            (i_clk            ),
        .i_rst            (i_rst            ),
        .i_seed           (i_seed           ),
        .i_valid          (i_valid          ),
        .i_soft_reset     (i_soft_reset     ),
        .i_corrupt        (i_corrupt        )    
    );

endmodule
