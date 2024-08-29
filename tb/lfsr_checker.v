module lfsr_checker
    #(
        parameter DEF_SEED            = 300                                        ,   //! Semilla por defecto
        parameter VALID_TO_LOCK       = 5                                          ,   //! Cantidad de Datos Validos para activar bloqueo
        parameter INVALID_TO_UNLOCK   = 3                                              //! Cantidad de Datos Invalidos para desactivar bloqueo
    )
    (
        output                          o_lock                                     ,   //! Bandera de Bloqueo
        input       [15 : 0]            i_LFSR                                     ,   //! Señal obtenida a la salida del generador LFSR
        input       [15 : 0]            i_seed                                     ,   //! Entrada de Semilla
        input                           i_valid                                    ,   //! Señal para habilitar generador LFSR
        input                           i_clk                                      ,   //! Entrada de Reloj
        input                           i_rst                                      ,   //! Entrada de Reset asincrono
        input                           i_soft_reset                                   //! Entrada de Reset sincrono
    );

    reg             [2  : 0]            valid_count                                ;   //! Contador de datos validos
    reg             [1  : 0]            invalid_count                              ;   //! Contador de datos invalidos
    reg             [15 : 0]            LFSR_calc                                  ;   //! Calculo de siguiente valor de LFSR
    reg             [15 : 0]            LFSR_next                                  ;   //! Registro para almacenar el valor de la entrada
    reg                                 valid_next                                 ;   //! Registro para almacenar el siguiente valor de la señal valid 
    reg                                 feedback                                   ;   //! Retroalimentacion de LFSR
    reg                                 lock_reg                                   ;   //! Registro para almacenar el estado de bloqueo
    reg                                 match_LFSR                                 ;   //! Indicador de coincidencia entre el valor generado y el calculado

    always @(*) begin
        // Calculo del siguiente valor que debe generar el  generador de LFSR
        feedback                      = LFSR_next[15] ^ (LFSR_next[14 : 0] == 'd0) ;

        if (i_rst || i_soft_reset) begin                                               // Reset de registros

            LFSR_calc                 = 16'b0                                      ;
            valid_count               =   'd0                                      ;
            invalid_count             =   'd0                                      ;
            lock_reg                  =   'd0                                      ;

        end else begin
            
            if (valid_next) begin

                LFSR_calc[0 ]         = feedback                                   ;
                LFSR_calc[1 ]         = LFSR_next[0 ]                              ;
                LFSR_calc[2 ]         = LFSR_next[1 ] ^ feedback                   ;
                LFSR_calc[3 ]         = LFSR_next[2 ] ^ feedback                   ;
                LFSR_calc[4 ]         = LFSR_next[3 ]                              ;
                LFSR_calc[5 ]         = LFSR_next[4 ] ^ feedback                   ;
                LFSR_calc[6 ]         = LFSR_next[5 ]                              ;
                LFSR_calc[7 ]         = LFSR_next[6 ]                              ;
                LFSR_calc[8 ]         = LFSR_next[7 ]                              ;    
                LFSR_calc[9 ]         = LFSR_next[8 ]                              ;
                LFSR_calc[10]         = LFSR_next[9 ]                              ;
                LFSR_calc[11]         = LFSR_next[10]                              ;
                LFSR_calc[12]         = LFSR_next[11]                              ;
                LFSR_calc[13]         = LFSR_next[12]                              ;
                LFSR_calc[14]         = LFSR_next[13]                              ;
                LFSR_calc[15]         = LFSR_next[14]                              ;

                if (match_LFSR) begin                                                  // Si hubo una coincidencia entre el dato generado y el calculado
                    
                    valid_count       = valid_count + 1                            ;   // Se incrementa en 1 la cantidad de datos validos
                    invalid_count     =  'd0                                       ;   // Se resetea la cantidad de datos invalidos
                    if (valid_count >= VALID_TO_LOCK) begin                            // Si la cantidad de datos validos es igual o mayor a la cantidad de datos necesarios para establecer el bloqueo
                        lock_reg      = 1'b1                                       ;   // Se establece estado de bloqueo
                        valid_count   =  'd0                                       ;   // Se resetea la cuenta de datos validos
                    end else begin                                                     // Si la cantidad de datos validos es menor a la cantidad de datos necesarios para establecer el bloqueo
                        lock_reg      = lock_reg                                   ;   // El estado de bloqueo permanece igual
                    end

                end else begin                                                         // Si no hubo coincidencia entre el dato generado y el calculado
                    
                    valid_count       =  'd0                                       ;   // Se resetea la cantida de datos validos
                    invalid_count     = invalid_count + 1                          ;   // Se incrementa en 1 la cantida de datos invalidos
                    if (invalid_count >= INVALID_TO_UNLOCK) begin                      // Si la cantidad de datos invalidos es igual o mayor a la cantidad de datos necesarios para deshabilitar el bloqueo
                        lock_reg      = 1'b0                                       ;   // Se deshabilita el estado de bloqueo
                        invalid_count =  'd0                                       ;   // Se resetea la cuenta de datos invalidos
                    end else begin                                                     // Si la cantidad de datos invalidos es menor a la cantidad de datos necesarios para deshabilitar el bloqueo
                        lock_reg      = lock_reg                                   ;   // El estado de bloqueo permanece igual
                    end

                end

            end else begin

                LFSR_calc             = LFSR_calc                                  ;
                valid_count           = valid_count                                ;
                invalid_count         = invalid_count                              ;
                lock_reg              = lock_reg                                   ;
                
            end
        end
    end

    always @(posedge i_clk or posedge i_rst) begin

        if (i_rst ) begin                                                              // Reset asincrono

            LFSR_next                <= DEF_SEED                                   ;   // Setear semilla por defecto
            valid_next               <= 1'b0                                       ;   // Reestablecer el siguiente valor de valid
            match_LFSR               <= 1'b0                                       ;   // Reestablecer estado de coincidencia

        end else begin

            if (i_soft_reset) begin                                                    // Reset sincrono

                LFSR_next            <= i_seed                                     ;   // Setear semilla de entrada
                valid_next           <= 1'b0                                       ;   // Reestablecer el siguiente valor de valid
                match_LFSR           <= 1'b0                                       ;   // Reestablecer estado de coincidencia

            end else begin

                valid_next           <= i_valid                                    ;   // Almaceno el siguiente valor de valid
                
                if (i_valid) begin                                                  // Si esta habilitado la generacion de LFSR

                    if (LFSR_calc == i_LFSR) begin                                     // Si el valor calculado coincide con el generado
                        match_LFSR   <= 1'b1                                       ;   // Se pone en 1 la bandera que indica coincidencia
                    end else begin                                                     // Si el valor calculado no coincide con el generado
                        match_LFSR   <= 1'b0                                       ;   // Se pone en 0 la bandera que indica coincidencia
                    end

                    if (lock_reg) begin                                                // Si el sistema esta bloqueado
                        LFSR_next    <= LFSR_calc                                  ;   // El siguiente valor con el que se calculara el dato es el ultimo valor calculado
                    end else begin                                                     // Si el sistema no esta bloqueado
                        LFSR_next    <= i_LFSR                                     ;   // El siguiente valor con el que se calculara el dato es la entrada
                    end

                end else begin                                                         // Si no esta habilitado la generacion de LFSR los registros permanecen igual

                    LFSR_next        <= LFSR_next                                  ;
                    match_LFSR       <= match_LFSR                                 ;

                end

            end
        end
    end

    assign o_lock = lock_reg                                                       ;

endmodule
