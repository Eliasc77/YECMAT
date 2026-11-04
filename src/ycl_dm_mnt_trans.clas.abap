CLASS ycl_dm_mnt_trans DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS registrar IMPORTING raiz TYPE string clave TYPE string
      RETURNING VALUE(error) TYPE string.
    CLASS-METHODS limpiar.
  PRIVATE SECTION.
    CLASS-DATA raiz_actual TYPE string.
    CLASS-DATA clave_actual TYPE string.
ENDCLASS.
CLASS ycl_dm_mnt_trans IMPLEMENTATION.
  METHOD registrar.
    IF raiz_actual IS INITIAL.
      raiz_actual = raiz. clave_actual = clave.
    ELSEIF raiz_actual <> raiz OR clave_actual <> clave.
      error = 'Guardar un solo campo, seccion o flujo por transaccion; sus detalles pueden guardarse juntos'.
    ENDIF.
  ENDMETHOD.
  METHOD limpiar.
    CLEAR: raiz_actual, clave_actual.
  ENDMETHOD.
ENDCLASS.
