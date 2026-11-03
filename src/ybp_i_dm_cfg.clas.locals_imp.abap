
CLASS lhc_Configuration DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations
      FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Configuration
      RESULT result.

    METHODS get_instance_authorizations
      FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Configuration
      RESULT result.

    METHODS Aplicar
      FOR MODIFY
      IMPORTING keys FOR ACTION Configuration~Aplicar
      RESULT result.

ENDCLASS.

CLASS lhc_Configuration IMPLEMENTATION.

  METHOD get_global_authorizations.

    DATA(allow) = COND #(
      WHEN ycl_dm_cfg_store=>can_maintain( ) = abap_true
      THEN if_abap_behv=>auth-allowed
      ELSE if_abap_behv=>auth-unauthorized
    ).

    result = VALUE #(
      %update        = if_abap_behv=>auth-unauthorized
      %action-Aplicar = allow
    ).

  ENDMETHOD.

  METHOD get_instance_authorizations.

    DATA(allow) = COND #(
      WHEN ycl_dm_cfg_store=>can_maintain( ) = abap_true
      THEN if_abap_behv=>auth-allowed
      ELSE if_abap_behv=>auth-unauthorized
    ).

    result = VALUE #(
      FOR key IN keys
      (
        %tky           = key-%tky
        %update        = if_abap_behv=>auth-unauthorized
        %action-Aplicar = allow
      )
    ).

  ENDMETHOD.

  METHOD Aplicar.

    LOOP AT keys INTO DATA(key).

      DATA(error) = CONV string( '' ).

      IF key-ConfigId <> 'GLOBAL'
         OR ycl_dm_cfg_store=>can_maintain( ) = abap_false.

        error = 'Sin acceso al mantenimiento DM'.

      ELSEIF lines( keys ) <> 1
         OR ycl_dm_cfg_store=>pending( ) = abap_true.

        error = 'Una sola operacion de configuracion por peticion'.

      ENDIF.

      IF error IS INITIAL.

        READ ENTITIES OF yi_dm_cfg IN LOCAL MODE
          ENTITY Configuration
          ALL FIELDS
          WITH VALUE #( ( %tky = key-%tky ) )
          RESULT DATA(rows).

        IF rows IS INITIAL.
          error = 'Ejecutar primero YCL_DM_CFG_SETUP para inicializar la administracion'.
        ENDIF.

      ENDIF.

      IF error IS INITIAL.

        DATA(current) = ycl_dm_cfg_store=>read_state( ).

        ycl_dm_cfg_model=>plan(
          EXPORTING
            current = current
            command = key-%param
          IMPORTING
            next    = DATA(next)
            error   = error
        ).

      ENDIF.

      IF error IS INITIAL.

        DATA(revision) = rows[ 1 ]-Revision + 1.

        ycl_dm_cfg_store=>stage(
          EXPORTING
            before = current
            after  = next
          IMPORTING
            error  = error
        ).

      ENDIF.

      IF error IS NOT INITIAL.

        APPEND VALUE #(
          %tky = key-%tky
        ) TO failed-configuration.

        APPEND VALUE #(
          %tky = key-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = error
          )
        ) TO reported-configuration.

        CONTINUE.

      ENDIF.

      MODIFY ENTITIES OF yi_dm_cfg IN LOCAL MODE
        ENTITY Configuration
        UPDATE FIELDS ( Revision )
        WITH VALUE #(
          (
            %tky     = key-%tky
            Revision = revision
          )
        )
        FAILED DATA(update_failed).

      IF update_failed-configuration IS NOT INITIAL.

        ycl_dm_cfg_store=>clear( ).

        APPEND VALUE #(
          %tky = key-%tky
        ) TO failed-configuration.

        CONTINUE.

      ENDIF.

      READ ENTITIES OF yi_dm_cfg IN LOCAL MODE
        ENTITY Configuration
        ALL FIELDS
        WITH VALUE #( ( %tky = key-%tky ) )
        RESULT DATA(done).

      result = VALUE #(
        FOR row IN done
        (
          %tky   = row-%tky
          %param = row
        )
      ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_Configuration DEFINITION
  INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.
    METHODS cleanup REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_Configuration IMPLEMENTATION.

  METHOD save_modified.

    ycl_dm_cfg_store=>persist( ).

  ENDMETHOD.

  METHOD cleanup.

    ycl_dm_cfg_store=>clear( ).

  ENDMETHOD.

  METHOD cleanup_finalize.

    ycl_dm_cfg_store=>clear( ).

  ENDMETHOD.

ENDCLASS.

