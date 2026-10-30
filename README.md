# YECMAT — Gestión de materiales DM

Modelo normalizado para SAP S/4HANA On-Premise: 15 tablas Dictionary
`YMMT_DM_*`, flujos versionados, solicitudes, tareas, segmentos organizativos y
valores configurables. Fuentes abapGit TABL en `src/`, con seis dominios y seis elementos de datos
propios que deben activarse antes de las tablas.

- [Modelo y decisiones](docs/arquitectura/MODELO_DATOS.md)
- [DER Mermaid completo](docs/arquitectura/DER_DM.mmd)
- [Diccionario](docs/arquitectura/DICCIONARIO_DATOS.md)
- [Relaciones y unicidad](docs/arquitectura/RELACIONES.md)
- [Respaldo e inventario de limpieza](docs/arquitectura/LIMPIEZA.md)
- [Validaciones](docs/arquitectura/VALIDACIONES.md)
- [Importación en SAP](docs/deployment.md)

Validación local desde la raíz:

```sh
python3 tools/validate_dm.py
python3 -m unittest discover -s tests -v
```

Estado: fuentes locales, sin activación SAP. Los behaviors y el servicio anterior
para BTP Trial se retiraron; aún no hay servicio OData V4 del nuevo modelo.
No importar bajas sobre un sistema con datos sin un plan de transición separado.
