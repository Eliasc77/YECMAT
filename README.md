# YECMAT — Gestión de materiales con captura dinámica

Rama `feature/dm-rap-dinamico`, destinada a ABAP Cloud Trial (TRL_EN), basada en
el modelo normalizado publicado en `work`.

- 15 tablas, con dominios/elementos propios y cinco atributos de soporte RAP.
- 15 CDS de interfaz, 9 proyecciones transaccionales y 6 CDS de consumo de metadata.
- 4 CDS auxiliares/parámetros, 18 DCL, 4 behaviors de interfaz y 4 de proyección.
- 4 behavior pools managed y servicio `YUI_DM_O4` con 15 entity sets.
- Captura EAV por contexto, reglas I/O/M/R aplicadas también en backend, ETags y
  locks por tarea durante los guardados y cierres.

El formulario se construye por datos de CAMPO/REGLA/SECCION; no hay anotaciones UI
que fijen los campos funcionales. Las propiedades del servicio OData son estables.

- [Contrato RAP y limitaciones del Trial](docs/arquitectura/RAP_DINAMICO.md)
- [Importación y activación](docs/deployment.md)
- [DER](docs/arquitectura/DER_DM.mmd)
- [Diccionario](docs/arquitectura/DICCIONARIO_DATOS.md)
- [Modelo base y ampliaciones](docs/arquitectura/MODELO_DATOS.md)
- [Validaciones](docs/arquitectura/VALIDACIONES.md)

Comprobaciones locales:

```sh
python3 tools/validate_dm.py
python3 -m tools.validate_rap
python3 -m unittest discover -s tests -v
npx --yes @abaplint/cli@2.120.92 abaplint.json
```

`python3 tools/generate_rap.py` regenera tablas/CDS/BDEF/metadata a partir del
contrato JSON. Los handlers, reglas y pruebas ABAP Unit son código mantenido
manualmente. Revisar diferencias antes de publicar.

Estado: fuentes comprobadas localmente, sin compilación/activación SAP. Binding,
UI freestyle, mapeo IAM de Calidad e integración Product Master quedan pendientes.
`LISTA_INTEG` no significa material creado ni evento encolado.
