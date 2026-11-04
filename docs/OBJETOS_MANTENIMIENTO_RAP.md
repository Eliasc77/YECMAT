# Objetos de la migracion RAP

Base: e415d2f. 47 objetos SAP afectados.

| Estado | Tipo | Objeto |
|---|---|---|
| Modificado | CLAS | `YBP_I_DM_CFG` |
| Modificado | TABL | `YMMT_DM_CAMPO` |
| Modificado | TABL | `YMMT_DM_CFG_CTL` |
| Modificado | TABL | `YMMT_DM_FLUJO` |
| Modificado | TABL | `YMMT_DM_FLUJO_VR` |
| Modificado | TABL | `YMMT_DM_PASO` |
| Modificado | TABL | `YMMT_DM_REGLA` |
| Modificado | TABL | `YMMT_DM_SECCION` |
| Nuevo | BDEF | `YC_DM_M_CAMPO` |
| Nuevo | BDEF | `YC_DM_M_FLUJO` |
| Nuevo | BDEF | `YC_DM_M_SECCION` |
| Nuevo | BDEF | `YI_DM_M_CAMPO` |
| Nuevo | BDEF | `YI_DM_M_FLUJO` |
| Nuevo | BDEF | `YI_DM_M_SECCION` |
| Nuevo | CLAS | `YBP_I_DM_M_CAMPO` |
| Nuevo | CLAS | `YBP_I_DM_M_FLUJO` |
| Nuevo | CLAS | `YBP_I_DM_M_SECCION` |
| Nuevo | CLAS | `YCL_DM_MNT_ACCESO` |
| Nuevo | CLAS | `YCL_DM_MNT_MODEL` |
| Nuevo | CLAS | `YCL_DM_MNT_SETUP` |
| Nuevo | CLAS | `YCL_DM_MNT_TRANS` |
| Nuevo | DDLS | `YC_DM_M_CAMPO` |
| Nuevo | DDLS | `YC_DM_M_FLUJO` |
| Nuevo | DDLS | `YC_DM_M_FLUJO_VR` |
| Nuevo | DDLS | `YC_DM_M_PASO` |
| Nuevo | DDLS | `YC_DM_M_REGLA` |
| Nuevo | DDLS | `YC_DM_M_SECCION` |
| Nuevo | DDLS | `YD_DM_M_COPIAR` |
| Nuevo | DDLS | `YI_DM_M_CAMPO` |
| Nuevo | DDLS | `YI_DM_M_FLUJO` |
| Nuevo | DDLS | `YI_DM_M_FLUJO_VR` |
| Nuevo | DDLS | `YI_DM_M_PASO` |
| Nuevo | DDLS | `YI_DM_M_REGLA` |
| Nuevo | DDLS | `YI_DM_M_SECCION` |
| Nuevo | DDLX | `YC_DM_M_CAMPO_UI` |
| Nuevo | DDLX | `YC_DM_M_FLUJO_UI` |
| Nuevo | DDLX | `YC_DM_M_FLUJO_VR_UI` |
| Nuevo | DDLX | `YC_DM_M_PASO_UI` |
| Nuevo | DDLX | `YC_DM_M_REGLA_UI` |
| Nuevo | DDLX | `YC_DM_M_SECCION_UI` |
| Nuevo | SRVD | `YUI_DM_MNT_O4` |
| Nuevo | TABL | `YMMT_DM_D_CAMPO` |
| Nuevo | TABL | `YMMT_DM_D_FLUJO` |
| Nuevo | TABL | `YMMT_DM_D_FLUJO_VR` |
| Nuevo | TABL | `YMMT_DM_D_PASO` |
| Nuevo | TABL | `YMMT_DM_D_REGLA` |
| Nuevo | TABL | `YMMT_DM_D_SECCION` |

Crear manualmente en ADT el Service Binding **YBD_DM_MNT_O4**, OData V4 - UI,
para **YUI_DM_MNT_O4** y publicarlo. No se cambia el binding antiguo.

Orden y cambio de escritor: [MIGRACION_MANTENIMIENTO_RAP.md](MIGRACION_MANTENIMIENTO_RAP.md).
