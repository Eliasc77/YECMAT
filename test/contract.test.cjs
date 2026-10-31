const { test } = require("node:test");
const assert = require("node:assert/strict");
const contract = require("../docs/service-contract.json");
const Rules = require("./load.cjs")("Rules");

test("all context deep inserts target actual single-valued compositions in the supplied SAP metadata", () => {
  for (const context of Object.values(Rules.contexts)) {
    if (!context.nav) { continue; }
    const target = contract.entities.Segmentos.navigation[context.nav];
    assert.ok(target && !target.startsWith("Collection("));
    const entity = Object.values(contract.entities).find(e => e.navigation._Segmento && context.fields.every(f => e.properties[f[0]]));
    assert.ok(entity, "context fields must exist in the exported service contract");
  }
});
test("bound actions and input types match the supplied namespace and UUID keys", () => {
  assert.equal(contract.namespace, "com.sap.gateway.srvd.yui_dm_o4.v0001");
  assert.equal(contract.entities.Datos.properties.Valor, "Edm.String");
  assert.deepEqual(contract.entities.Datos.keys, ["SegmentoUUID", "CampoId"]);
  assert.equal(contract.entities.Solicitudes.properties.SolicitudUUID, "Edm.Guid");
  assert.equal(contract.actions.find(a => a.name === "Reabrir").parameters.TareaUUID, "Edm.Guid");
  assert.equal(contract.actions.filter(a => a.name === "Iniciar").length, 2);
});
