# Autorización por rol: pendiente y comentada

## Comportamiento actual solicitado para la prueba

La app utiliza **una sola tabla adicional de soporte: `YMMT_DM_CFG_CTL`**. Las seis tablas existentes siguen guardando los campos, secciones, flujos, versiones, pasos y reglas.

No hay lista de administradores propia ni comprobación activa del rol específico de administrador DM. Un usuario con sesión y acceso al servicio SAP puede consultar y mantener configuración. El método `YCL_DM_CFG_STORE=>can_maintain` comprueba únicamente que exista usuario técnico en el contexto.

No se elimina el login SAP ni las autorizaciones externas para acceder al servicio. La DCL raíz concede lectura sin filtro específico DM y la proyección hereda esa condición. Los seis catálogos `YA_DM_*` consultan directamente las tablas existentes, sin joins a usuarios.

La cabecera de la web indica esta condición de prueba. Las validaciones funcionales, versiones protegidas, ETags y bloqueos siguen activos. `YCL_DM_CFG_SETUP` solo inicializa `GLOBAL`; no crea usuarios ni concede roles.

## Diseño del rol para una etapa posterior

Estos son **nombres propuestos, no objetos entregados ni activados**:

| Elemento | Ejemplo |
| --- | --- |
| Objeto de autorización | `Y_DM_MNT` |
| Campo | `ACTVT` |
| Consultar | `03` |
| Cambiar configuración, publicar, retirar y copiar | `02` |
| Rol de negocio administrador | `Z_BR_DM_ADMIN` |

El rol debe incluir las autorizaciones y el acceso IAM del servicio. El nombre del rol no se consulta desde ABAP: el código comprueba el objeto de autorización y sus valores.

## Activar el control de escritura en RAP

Primero crea/activa el objeto `Y_DM_MNT` con el campo `ACTVT` y configura sus autorizaciones en la IAM App/Business Catalog correspondiente a `YUI_DM_CFG_O4`. Después, mediante la administración SAP disponible en tu sistema, crea y asigna el Business Role a los usuarios de prueba. Con acceso solo a ADT se prepara la parte técnica; la asignación del Business Role requiere la administración del sistema.

Cuando exista el objeto y estén asignados los permisos, **reemplaza** la implementación temporal de `YCL_DM_CFG_STORE=>can_maintain` por:

```abap
AUTHORITY-CHECK OBJECT 'Y_DM_MNT'
  ID 'ACTVT' FIELD '02'.
allowed = xsdbool( sy-subrc = 0 ).
```

El ejemplo ya está comentado en ese método. No agregues una asignación `allowed = abap_true` después del check. Las autorizaciones globales/de instancia y la acción Aplicar en `YBP_I_DM_CFG` llaman al mismo método; `stage` vuelve a comprobarlo. La actualización directa de la revisión continúa denegada fuera de la lógica interna RAP.

## Activar también el control de lectura

Limitar únicamente la acción no restringe las consultas. Sustituye el grant temporal de `YR_I_DM_CFG` por una condición de lectura basada en el objeto y actividad `03`. Ejemplo de DCL, a activar **después** de crear el objeto de autorización:

```abap
@EndUserText.label: 'DM acceso de lectura por autorizacion'
@MappingRole: true
define role YR_I_DM_CFG {
  grant select on YI_DM_CFG
    where ( ) = aspect pfcg_auth( Y_DM_MNT, ACTVT = '03' );
}
```

`YR_C_DM_CFG` ya hereda las condiciones de `YI_DM_CFG`; conserva esa herencia. Para cada catálogo administrativo (`YA_DM_CAMPO`, `YA_DM_SECCION`, `YA_DM_FLUJO`, `YA_DM_FLUJO_VR`, `YA_DM_PASO`, `YA_DM_REGLA`):

1. Cambia `@AccessControl.authorizationCheck` de `#NOT_REQUIRED` a `#CHECK`.
2. Crea una DCL de ese catálogo con la misma condición `ACTVT = '03'`. No dejes un grant sin restricción en paralelo: los grants pueden ampliar el acceso.

Ejemplo del cuerpo para Campos, dentro de su propia definición de rol DCL:

```abap
grant select on YA_DM_CAMPO
  where ( ) = aspect pfcg_auth( Y_DM_MNT, ACTVT = '03' );
```

Los objetos DCL adicionales y el objeto de autorización **no forman parte de esta entrega temporal**. También será necesario adaptar los mensajes de acceso de la web y retirar el aviso de rol pendiente cuando el control se haya activado realmente. El control de lectura de `GLOBAL` puede devolver un registro no visible cuando faltan autorizaciones; no debe confundirse con una inicialización pendiente.

## Comprobación al habilitarlo

- Usuario con `03` y `02`: consulta y modifica configuración.
- Usuario solo con `03`: consulta, pero una llamada directa a Aplicar debe rechazarse.
- Usuario sin autorización DM: las lecturas quedan restringidas y Aplicar se rechaza, aunque tenga acceso de entrada al servicio.
- Comprobar lo mismo desde la web y mediante peticiones directas al servicio; ocultar botones no reemplaza DCL/RAP.

Esta autorización administrativa no define los permisos PCP/LOG/CONT de captura ni los responsables de tareas: son controles de negocio distintos.
