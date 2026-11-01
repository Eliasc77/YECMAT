const { test } = require("node:test");
const assert = require("node:assert/strict");
const load = require("./load.cjs");
const Schema = load("Schema");
const Demo = load("DemoService", { "./Schema": Schema });
const ConfigService = load("ConfigService", { "./Schema": Schema, "./Transport": class {} });
const seed = require("../webapp/model/demo.json");
const params = require("../docs/action-parameters.json");

test("commands contain exactly the backend abstract parameters, preserve booleans and canonical dates", () => {
  const cmd = Schema.command("Versiones", { FlujoId: "FLOW", Version: "2", VigenteDesde: "2026-11-01", VigenteHasta: "" }, "CREAR");
  assert.deepEqual(Object.keys(cmd).sort(), Object.keys(params).sort());
  assert.equal(cmd.Version, 2); assert.equal(cmd.VigenteDesde, "20261101");
  assert.equal(cmd.VigenteHasta, ""); assert.equal(cmd.Activo, false);
  assert.ok(!("ReglaUUID" in cmd)); assert.ok(!("Estado" in cmd));
});
test("field configuration rejects incompatible decimals, bad IDs and impossible dates", () => {
  const field = Object.assign(Schema.defaults("Campos"), { CampoId: "F", Descripcion: "Field", TablaSap: "MARA", CampoSap: "MATKL", TipoDato: "CHAR", Decimales: 2 });
  assert.ok(Schema.validate("Campos", field).some(s => /Decimales/.test(s)));
  field.Decimales = 0; field.CampoId = "lower";
  assert.ok(Schema.validate("Campos", field).some(s => /mayusculas/.test(s)));
  assert.ok(Schema.validate("Versiones", { FlujoId: "FLOW", Version: 1, VigenteDesde: "2026-02-30" }).some(s => /fecha invalida/.test(s)));
});
test("demo copy produces a new draft and independent rule UUIDs, without modifying the published source", async () => {
  const demo = new Demo(seed), before = await demo.load(), source = before.state.Versiones[0];
  await demo.apply(Schema.command("Versiones", { ...source, VersionDestino: 2 }, "COPIAR"), before.root);
  const after = await demo.load();
  assert.equal(after.state.Versiones[1].Estado, "BORRADOR");
  assert.deepEqual(after.state.Versiones[0], source);
  assert.equal(after.state.Reglas.filter(r => r.Version === 2).length, 9);
  assert.notEqual(after.state.Reglas[0].ReglaUUID, after.state.Reglas.find(r => r.Version === 2).ReglaUUID);
});
test("published rule changes are rejected; edits on the copied draft leave the original untouched", async () => {
  const demo = new Demo(seed); let snap = await demo.load();
  const rule = snap.state.Reglas.find(r => r.CampoId === "MARM_UMREZ");
  await assert.rejects(demo.apply(Schema.command("Reglas", { ...rule, EstadoCampo: "O" }), snap.root), /protegido/);
  assert.equal((await demo.load()).root.Revision, 0);
  await demo.apply(Schema.command("Versiones", { ...snap.state.Versiones[0], VersionDestino: 2 }, "COPIAR"), snap.root);
  snap = await demo.load();
  const draftRule = snap.state.Reglas.find(r => r.Version === 2 && r.CampoId === "MARM_UMREZ");
  await demo.apply(Schema.command("Reglas", { ...draftRule, EstadoCampo: "O" }), snap.root);
  snap = await demo.load();
  assert.equal(snap.state.Reglas.find(r => r.Version === 1 && r.CampoId === "MARM_UMREZ").EstadoCampo, "M");
  assert.equal(snap.state.Reglas.find(r => r.Version === 2 && r.CampoId === "MARM_UMREZ").EstadoCampo, "O");
});
test("published overlap is rejected and retirement allows publishing the copied draft", async () => {
  const demo = new Demo(seed); let snap = await demo.load();
  await demo.apply(Schema.command("Versiones", { ...snap.state.Versiones[0], VersionDestino: 2 }, "COPIAR"), snap.root);
  snap = await demo.load();
  await assert.rejects(demo.apply(Schema.command("Versiones", snap.state.Versiones[1], "PUBLICAR"), snap.root), /solapada/);
  await demo.apply(Schema.command("Versiones", snap.state.Versiones[0], "RETIRAR"), snap.root);
  snap = await demo.load();
  await demo.apply(Schema.command("Versiones", snap.state.Versiones[1], "PUBLICAR"), snap.root);
  snap = await demo.load();
  assert.equal(snap.state.Versiones[1].Estado, "PUBLICADA");
  assert.equal(snap.state.Versiones[0].Estado, "RETIRADA");
});
test("a stale administrator snapshot cannot overwrite a concurrent configuration change", async () => {
  const demo = new Demo(seed), snap = await demo.load();
  const version = { ...snap.state.Versiones[0], VersionDestino: 2 };
  await demo.apply(Schema.command("Versiones", version, "COPIAR"), snap.root);
  await assert.rejects(demo.apply(Schema.command("Versiones", { ...version, VersionDestino: 3 }, "COPIAR"), snap.root), /Otro administrador/);
  assert.equal((await demo.load()).state.Versiones.length, 2);
});
test("a create with an existing key is rejected rather than implicitly updating it", async () => {
  const demo = new Demo(seed), snap = await demo.load();
  await assert.rejects(demo.apply(Schema.command("Campos", snap.state.Campos[0], "CREAR"), snap.root), /Ya existe/);
  assert.equal((await demo.load()).root.Revision, 0);
});
test("a step cannot be deactivated while its area has active rules", async () => {
  const demo = new Demo(seed); let snap = await demo.load();
  await demo.apply(Schema.command("Versiones", { ...snap.state.Versiones[0], VersionDestino: 2 }, "COPIAR"), snap.root);
  snap = await demo.load();
  const step = snap.state.Pasos.find(p => p.Version === 2 && p.Area === "PCP");
  await assert.rejects(demo.apply(Schema.command("Pasos", { ...step, Activo: false }), snap.root), /reglas activas/);
});
test("catalog protection and draft version choices match the effective configuration", () => {
  assert.equal(Schema.protectedRow("Campos", seed.Campos[0], seed), true);
  const opt = Schema.options("Reglas", { ref: "Versiones" }, { FlujoId: seed.Flujos[0].FlujoId }, seed, false);
  assert.equal(opt.length, 0, "no draft exists in the initial seed");
});
test("load detects a changing revision while loading collections and retries a consistent snapshot", async () => {
  const service = new ConfigService("/service/"); let reads = 0, lists = 0;
  service.transport = {
    request: async () => ({ "@odata.etag": reads++ === 0 ? 'W/"1"' : 'W/"2"', Revision: 2 }),
    list: async () => { lists++; return []; }
  };
  const snap = await service.load(); assert.equal(snap.root.Revision, 2); assert.equal(lists, 12);
});
test("administrative writes target the new service action and use the original root ETag", async () => {
  const service = new ConfigService("/service/"); let args;
  service.transport = { request: async (...input) => { args = input; } };
  await service.apply({ Operation: "CREAR" }, { "@odata.etag": 'W/"old"' });
  assert.equal(args[0], "Configuration('GLOBAL')/com.sap.gateway.srvd.yui_dm_cfg_o4.v0001.Aplicar");
  assert.equal(args[3], 'W/"old"');
  await assert.rejects(service.apply({}, {}), /Actualiza/);
});
