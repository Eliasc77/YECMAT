# Plan de pruebas

## Obligatorias

1. Crear una solicitud ZFER/1000 como PCP y clasificarla BPM.
2. Abrir AR, CONT y LOG con tres usuarios; modificar y guardar simultáneamente.
   Ningún usuario debe recibir bloqueo por la edición de otro área.
3. Finalizar un área omitiendo un campo `M`: debe fallar con el nombre técnico.
4. Guardar progreso con el mismo campo vacío: debe ser permitido.
5. Finalizar las tres áreas: BPM pasa a revisión, no BPM crea un único outbox.
6. Rechazar CONT: solo CONT vuelve a `R`; AR/LOG permanecen `V`.
7. Aprobar BPM: se genera un único evento aun repitiendo la petición.
8. Simular error HTTP: solicitud `ERROR`, mensaje persistido y sin cambio parcial.
9. Reprocesar: mismo evento, una sola creación física.
10. Verificar auditoría con usuario, instante, área y valores anterior/nuevo.

## Rendimiento

- 50 solicitudes y al menos 20 sesiones paralelas.
- Sin esperas de enqueue entre áreas de una misma solicitud.
- Índices/selectividad revisados con SQL Monitor y ST05.

## Seguridad

- Cada rol solo ve/edita sus campos.
- Intentos directos por OData se rechazan en behavior implementation; la
  visibilidad de Fiori no sustituye la autorización backend.
