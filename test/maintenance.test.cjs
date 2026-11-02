const { test } = require("node:test");
const assert = require("node:assert/strict");
const load = require("./load.cjs"), Schema = load("Schema");
const Csv = load("Csv", { "./Schema": Schema });
const Readiness = load("Readiness", { "./Schema": Schema });
const seed = require("../webapp/model/demo.json");
const clone = value => JSON.parse(JSON.stringify(value));

test("CSV supports quoted separators, multiline descriptions and escaped quotes", () => {
  const rows = Csv.parse('CampoId;Descripcion\r\nF;"Nombre; con ""comillas""\ny linea"\r\n');
  assert.equal(rows[1][1], 'Nombre; con "comillas"\ny linea');
  assert.throws(() => Csv.parse('A;B\n"sin cierre'), /sin cerrar/);
  assert.throws(() => Csv.parse('A;B\n"cerrado"x;valor'), /se esperaba/i);
});
test("CSV export escapes spreadsheet formulas and imports the original description", () => {
  const state = clone(seed); state.Secciones = [];
  for (const text of ['=HYPERLINK("url")', "'texto", "'=texto", '+formula', '-texto', '@texto']) {
    const row = { SeccionId: "SEC", Descripcion: text, Orden: 1, Activo: true };
    const csv = Csv.exportRows("Secciones", [row]);
    assert.ok(csv.includes("\"'"));
    const preview = Csv.preview("Secciones", csv, state, false);
    assert.equal(preview[0].row.Descripcion, text); assert.equal(preview[0].errors.length, 0);
  }
});
test("CSV preview rejects duplicates and protects existing rows unless updates were explicitly selected", () => {
  const csv = Csv.exportRows("Campos", [seed.Campos[0], seed.Campos[0]]);
  const preview = Csv.preview("Campos", csv, seed, false);
  assert.ok(preview[0].errors.some(e => /ya existe/.test(e)));
  assert.ok(preview[1].errors.some(e => /repetida/.test(e)));
  const protectedRows = Csv.preview("Campos", Csv.exportRows("Campos", [seed.Campos[0]]), seed, true);
  assert.ok(protectedRows[0].errors.some(e => /protegido/.test(e)));
});
test("CSV updates preserve omitted settings and the false value; unknown columns and invalid booleans fail", () => {
  const state = clone(seed); state.Reglas = [];
  const name = state.Secciones[0].SeccionId;
  const preview = Csv.preview("Secciones", 'SeccionId;Descripcion;Orden;Activo\n' + name + ';Nuevo;0;false', state, true);
  assert.equal(preview[0].row.Activo, false); assert.equal(preview[0].row.Orden, 0);
  assert.equal(preview[0].errors.length, 0);
  const withoutActive = Csv.preview("Secciones", 'SeccionId;Descripcion;Orden\n' + name + ';Nuevo;1', state, true);
  assert.equal(withoutActive[0].row.Activo, true);
  assert.throws(() => Csv.preview("Secciones", 'SeccionId;Descripcio\nA;B', state, true), /desconocidas/);
  assert.ok(Csv.preview("Secciones", 'SeccionId;Descripcion;Orden;Activo\nN;Nuevo;1;yes', state, true)[0].errors.length);
});
test("CSV rule import checks existing draft, area, field and section references before any writes", () => {
  const state = clone(seed), rule = { ...state.Reglas[0], Version: 2 };
  const preview = Csv.preview("Reglas", Csv.exportRows("Reglas", [rule]), state, false);
  assert.ok(preview[0].errors.some(e => /borrador/.test(e)));
  assert.ok(preview[0].errors.some(e => /paso activo/.test(e)));
});
test("a copied draft reports the actual overlap and can be reviewed without changing any state", () => {
  const state = clone(seed), row = { ...state.Versiones[0], Version: 2, Estado: "BORRADOR" };
  state.Versiones.push(row);
  for (const set of ["Pasos", "Reglas"]) { state[set].push(...state[set].map(r => ({ ...r, Version: 2 }))); }
  const before = JSON.stringify(state);
  const report = Readiness.report(state, row);
  assert.equal(report.ready, false); assert.ok(report.issues.some(e => /Coincide/.test(e)));
  assert.equal(JSON.stringify(state), before);
  state.Versiones[0].Estado = "RETIRADA";
  assert.equal(Readiness.report(state, row).ready, true);
});
test("readiness pinpoints missing areas, inactive fields and invalid definitions", () => {
  const state = clone(seed), row = state.Versiones[0];
  state.Pasos = []; state.Campos[0].Activo = false;
  const report = Readiness.report(state, row);
  assert.equal(report.ready, false);
  assert.ok(report.issues.some(e => /pasos activos aplicables a A/.test(e)));
  assert.ok(report.issues.some(e => /campo inexistente o inactivo/.test(e)));
});
test("CSV size and row limits prevent unintended oversized imports", () => {
  assert.throws(() => Csv.parse("x".repeat(2 * 1024 * 1024 + 1)), /2 MB/);
  assert.throws(() => Csv.parse("ID\n" + "row\n".repeat(501)), /500 registros/);
});
test("integer keys are canonicalized before CSV duplicate and existing-row checks", () => {
  const csv = 'FlujoId;Version;VigenteDesde;VigenteHasta\nDM_DEMO_ZFER;02;2026-01-01;9999-12-31\nDM_DEMO_ZFER;2;2026-01-01;9999-12-31';
  const preview = Csv.preview("Versiones", csv, seed, false);
  assert.equal(preview[0].row.Version, 2);
  assert.ok(preview[1].errors.some(error => /repetida/.test(error)));
});
