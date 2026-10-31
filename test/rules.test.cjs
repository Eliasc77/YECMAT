const { test } = require("node:test");
const assert = require("node:assert/strict");
const load = require("./load.cjs");
const Rules = load("Rules");
const field = (type, length = 11, decimals = 2) => ({ TipoDato: type, Longitud: length, Decimales: decimals, required: true });

test("decimal precision keeps exact text, rejects locale commas and excess scale", () => {
  assert.equal(Rules.validate(field("CURR"), "123456789.12"), "");
  assert.match(Rules.validate(field("CURR"), "1234567890.12"), /Precision/);
  assert.match(Rules.validate(field("CURR"), "1,20"), /punto/);
  assert.match(Rules.validate(field("CURR"), "1.001"), /decimales/);
});
test("partial capture permits empty values but completion requires mandatory fields", () => {
  assert.equal(Rules.validate(field("CHAR"), "", false), "");
  assert.equal(Rules.validate(field("CHAR"), "", true), "Campo obligatorio");
});
test("NUMC preserves leading zeros, calendar dates and SAP unit keys are validated", () => {
  assert.equal(Rules.validate(field("NUMC", 6), "000123"), "");
  assert.equal(Rules.validate(field("DATS", 8), "20240229"), "");
  assert.match(Rules.validate(field("DATS", 8), "20230229"), /Fecha/);
  assert.match(Rules.validate(field("UNIT", 3), "kg"), /mayusculas/);
  assert.match(Rules.validate(field("INT1", 3), "256"), /rango/);
});
test("context payload is a single deep insert and never sends server-generated keys", () => {
  const body = Rules.segmentPayload("request", "ALMACEN", { Centro: "1000", Almacen: "0001" });
  assert.deepEqual(JSON.parse(JSON.stringify(body)), { SolicitudUUID: "request", TipoSegmento: "ALMACEN", _Almacen: { Centro: "1000", Almacen: "0001" } });
  assert.throws(() => Rules.segmentPayload("request", "VENTAS", { OrgVentas: "1000" }), /Canal/);
});
test("field groups follow active sections, context and rule visibility; unknown state is read-only", () => {
  const config = {
    fields: ["M", "I", "R", "OTHER"].map(id => ({ CampoId: id, Activo: true, TipoSegmento: id === "OTHER" ? "CENTRO" : "GENERAL" })),
    sections: [{ SeccionId: "B", Descripcion: "Basics", Orden: 1, Activo: true }],
    rules: ["M", "I", "R", "OTHER"].map(id => ({ CampoId: id, SeccionId: "B", Orden: 1, Activo: true, EstadoCampo: id === "OTHER" ? "M" : id }))
  };
  const groups = Rules.groups(config, "GENERAL");
  assert.equal(groups.length, 1); assert.equal(groups[0].fields.length, 2);
  assert.equal(groups[0].fields[0].required, true);
  assert.equal(groups[0].fields[1].editable, false);
});
test("demo completes PCP capture with all mandatory context values", async () => {
  const Demo = load("DemoService", { "./Rules": Rules }), demo = new Demo();
  const request = (await demo.requests())[0], task = (await demo.tasks(request.SolicitudUUID))[0];
  await assert.rejects(demo.action("Tareas", task, "Finalizar", {}), /contexto obligatorio/);
  const general = await demo.createSegment(Rules.segmentPayload(request.SolicitudUUID, "GENERAL", {}));
  const unit = await demo.createSegment(Rules.segmentPayload(request.SolicitudUUID, "UNIDAD", { UnidadAlternativa: "BOX" }));
  for (const [segment, name, value] of [[general, "MAKT_MAKTX", "Material demo"], [general, "MARA_MEINS", "UN"], [general, "MARA_MATKL", "001"], [unit, "MARM_UMREZ", "10"], [unit, "MARM_UMREN", "1"]]) {
    await demo.saveValue(segment.SegmentoUUID, name, value);
  }
  assert.equal((await demo.action("Tareas", task, "Finalizar", {})).Estado, "FINALIZADA");
});
