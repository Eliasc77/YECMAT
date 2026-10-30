# Arquitectura DM vigente

El contrato de la rama ABAP Cloud Trial se encuentra en
[RAP_DINAMICO.md](arquitectura/RAP_DINAMICO.md). La persistencia y su ampliación
se describen en [MODELO_DATOS.md](arquitectura/MODELO_DATOS.md), el
[DER](arquitectura/DER_DM.mmd), [diccionario](arquitectura/DICCIONARIO_DATOS.md)
y [relaciones](arquitectura/RELACIONES.md).

La antigua implementación ZDM_* permanece en el historial y en el respaldo
registrado en [LIMPIEZA.md](arquitectura/LIMPIEZA.md). Esta rama implementa nuevos
objetos YI/YC/YBP_DM sobre las tablas normalizadas, sin restaurar aquellos objetos.
