# Importación de la rama RAP en ABAP Cloud Trial (TRL_EN)

El destino fue confirmado como ABAP Cloud Trial. La rama
`feature/dm-rap-dinamico` parte de `83a47aa` y añade la capa RAP dinámica;
`work` y `main` se conservan. No hay activación SAP ejecutada desde este entorno.

1. Revisar [RAP_DINAMICO.md](arquitectura/RAP_DINAMICO.md), especialmente los cinco
   campos añadidos, los permisos Trial y el índice único nuevo de SEG.
2. Para tablas de prueba existentes: antes de activar SEG.Z02, comprobar que cada
   segmento tiene CONTEXTO_CLAVE correcto y único. Recrear la tabla de prueba y
   sus dependientes si no se necesita conservar datos; no hay script destructivo
   en Git. No retirar dominios usados ni cambiar PK. No publicar bajas locales.
3. En abapGit seleccionar la rama nueva e importar TODOS los objetos nuevos y
   modificados. Revisar que la lista incluya TABL, DDLS, DCLS, BDEF, CLAS y SRVD.
4. Activar primero los seis dominios YMMD_DM_* y seis elementos YMME_DM_*.
   Confirmar disponibilidad de los tipos estándar y ABAP_BOOLEAN y
   ABP_LOCINST_LASTCHANGE_TSTMPL en Trial. El aviso BOOLE_D se elimina al sustituirlo.
5. Activar las 15 tablas, padres antes que hijos. Orden: FLUJO/CAMPO/SECCION,
   FLUJO_VR, PASO/REGLA/SOL, SEG/TAREA, subtipos y DATO (prefijo YMMT_DM_).
6. Activar los DDLS (interfaces, auxiliares, parámetros y consumo/proyección)
   en conjunto: existen asociaciones y composiciones con dependencias cíclicas.
7. Activar en conjunto BDEF de interfaz, behavior pools YBP_I_DM_* y YCL_DM_RULES.
   EML entre los cuatro BO exige resolverlos juntos. Después activar BDEF de
   proyección, DCL y YUI_DM_O4. No activar únicamente los archivos .asddls sueltos:
   abapGit también requiere su metadata XML y los otros objetos.
8. Ejecutar ATC y los cinco métodos ABAP Unit de YCL_DM_RULES. Revisar errores
   completos en ADT; el parser local no certifica las reglas de release SAP.
9. Cargar configuración publicada y hacer pruebas EML/OData de captura, permisos,
   obligatorios, segmentos duplicados, ETags y dos sesiones concurrentes.
10. Crear manualmente un Service Binding OData V4 Web API para YUI_DM_O4, asignar
    el acceso IAM adecuado y publicar solo después de validar. Esta rama no crea
    ni publica automáticamente un binding, destino HTTP o credenciales.

La futura UI será freestyle: la preview Fiori Elements no construye un formulario
EAV a partir de las filas del catálogo. El backend conserva anotaciones semánticas,
no anotaciones UI con campos funcionales fijos.

El estado LISTA_INTEG no activa materiales ni crea outbox. La integración HTTP
con un S/4 externo y la autorización especializada de Calidad quedan fuera de
esta rama. Consultar el contrato de acciones y los límites Trial documentados.
