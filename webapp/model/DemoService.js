/* Demo repository: simulates maintenance locally; SAP remains the authoritative validator. */
sap.ui.define(["./Schema"], function (Schema) {
  "use strict";
  var clone = function (data) { return JSON.parse(JSON.stringify(data)); };
  function DemoService(seed) {
    this.revision = 0;
    this.ready = seed ? Promise.resolve(seed) : fetch(sap.ui.require.toUrl("com/yecmat/dm/admin/model/demo.json")).then(function (r) { if (!r.ok) { throw new Error("No se pudo cargar la configuracion demo"); } return r.json(); });
  }
  DemoService.prototype.load = async function () {
    if (!this.state) { this.state = clone(await this.ready); }
    return { root: { ConfigId: "GLOBAL", Revision: this.revision, LastChangedBy: "DEMO", "@odata.etag": 'W/"' + this.revision + '"' }, state: clone(this.state) };
  };
  DemoService.prototype.validateVersion = function (state, row) {
    var flow = state.Flujos.find(function (f) { return f.FlujoId === row.FlujoId; });
    if (!flow || !flow.Activo) { throw new Error("El flujo debe estar activo"); }
    var steps = state.Pasos.filter(function (p) { return p.FlujoId === row.FlujoId && p.Version === row.Version && p.Activo; });
    if (!["A", "B"].every(function (kind) { return steps.some(function (p) { return !p.CondicionBpm || p.CondicionBpm === kind; }); })) { throw new Error("La version requiere pasos activos para A y para B"); }
    var rules = state.Reglas.filter(function (r) { return r.FlujoId === row.FlujoId && r.Version === row.Version && r.Activo; });
    if (!rules.length) { throw new Error("La version requiere al menos una regla activa"); }
    rules.forEach(function (r) {
      if (!state.Campos.some(function (f) { return f.CampoId === r.CampoId && f.Activo; }) || !state.Secciones.some(function (s) { return s.SeccionId === r.SeccionId && s.Activo; }) || !steps.some(function (p) { return p.Area === r.Area; })) { throw new Error("Reglas con referencias inactivas o inexistentes"); }
    });
    var overlap = state.Versiones.some(function (v) {
      if (v.Estado !== "PUBLICADA" || v === row || v.FlujoId === row.FlujoId && v.Version === row.Version) { return false; }
      var other = state.Flujos.find(function (f) { return f.FlujoId === v.FlujoId; });
      var criteria = other && other.Activo && other.TipoMaterial === flow.TipoMaterial && other.TipoOperacion === flow.TipoOperacion && (!other.CentroCriterio || !flow.CentroCriterio || other.CentroCriterio === flow.CentroCriterio);
      return (v.FlujoId === row.FlujoId || criteria) && v.VigenteDesde <= (row.VigenteHasta || "9999-12-31") && row.VigenteDesde <= (v.VigenteHasta || "9999-12-31");
    });
    if (overlap) { throw new Error("Vigencia solapada con una version publicada. Retira la anterior antes de publicar"); }
  };
  DemoService.prototype.apply = async function (command, root) {
    await this.load();
    if (!root || root["@odata.etag"] !== 'W/"' + this.revision + '"') { throw new Error("Otro administrador modifico la configuracion. Actualiza antes de guardar."); }
    var state = clone(this.state), set = command.EntitySet, schema = Schema.schemas[set];
    if (!schema) { throw new Error("Mantenimiento desconocido"); }
    var row = {};
    schema.fields.forEach(function (f) { var value = command[f.name]; if (f.type === "date" && value) { value = value.slice(0, 4) + "-" + value.slice(4, 6) + "-" + value.slice(6, 8); } row[f.name] = value; });
    var existing = state[set].find(function (r) { return Schema.key(set, r) === Schema.key(set, row); });
    if (command.Operation === "CREAR" && existing) { throw new Error("Ya existe un registro con esa clave"); }
    if (command.Operation !== "CREAR" && !existing) { throw new Error("El registro no existe"); }
    if (command.Operation === "CREAR" || command.Operation === "GUARDAR") {
      var errors = Schema.validate(set, row); if (errors.length) { throw new Error(errors.join("\n")); }
      if (existing && Schema.protectedRow(set, existing, state)) {
        var onlyActive = set === "Flujos" && schema.fields.every(function (f) { return f.name === "Activo" || existing[f.name] === row[f.name]; });
        if (!onlyActive) { throw new Error("Registro protegido por una version publicada: crea una nueva clave o copia la version"); }
      }
      if (set === "Versiones" && !state.Flujos.some(function (f) { return f.FlujoId === row.FlujoId; })) { throw new Error("El flujo no existe"); }
      if (set === "Pasos" || set === "Reglas") {
        var parent = state.Versiones.find(function (v) { return v.FlujoId === row.FlujoId && v.Version === row.Version; });
        if (!parent || parent.Estado !== "BORRADOR") { throw new Error("Solo puedes editar una version borrador"); }
      }
      if (set === "Reglas") {
        if (!state.Campos.some(function (f) { return f.CampoId === row.CampoId && (!row.Activo || f.Activo); }) || !state.Secciones.some(function (s) { return s.SeccionId === row.SeccionId && (!row.Activo || s.Activo); }) || row.Activo && !state.Pasos.some(function (p) { return p.FlujoId === row.FlujoId && p.Version === row.Version && p.Area === row.Area && p.Activo; })) { throw new Error("Regla sin campo, seccion o paso del area activo"); }
      }
      if (set === "Pasos") {
        var prospective = state.Pasos.filter(function (p) { return p !== existing; }).concat(row);
        if (state.Reglas.some(function (r) { return r.FlujoId === row.FlujoId && r.Version === row.Version && r.Activo && !prospective.some(function (p) { return p.FlujoId === r.FlujoId && p.Version === r.Version && p.Area === r.Area && p.Activo; }); })) { throw new Error("No se puede dejar un area con reglas activas sin pasos activos"); }
      }
      if (existing) { Object.assign(existing, row); } else { if (set === "Versiones") { row.Estado = "BORRADOR"; } state[set].push(row); }
      if (set === "Flujos" && row.Activo) { state.Versiones.filter(function (v) { return v.FlujoId === row.FlujoId && v.Estado === "PUBLICADA"; }).forEach(this.validateVersion.bind(this, state)); }
    } else if (set === "Versiones") {
      if (command.Operation === "COPIAR") {
        if (!Number.isInteger(command.VersionDestino) || command.VersionDestino < 1 || state.Versiones.some(function (v) { return v.FlujoId === row.FlujoId && v.Version === command.VersionDestino; })) { throw new Error("La version destino debe ser nueva y positiva"); }
        state.Versiones.push(Object.assign({}, existing, { Version: command.VersionDestino, Estado: "BORRADOR" }));
        ["Pasos", "Reglas"].forEach(function (child) { state[child].filter(function (r) { return r.FlujoId === row.FlujoId && r.Version === row.Version; }).forEach(function (r) { var copy = Object.assign({}, r, { Version: command.VersionDestino }); if (child === "Reglas") { copy.ReglaUUID = crypto.randomUUID(); } state[child].push(copy); }); });
      } else if (command.Operation === "PUBLICAR") {
        if (existing.Estado !== "BORRADOR") { throw new Error("Solo se publica un borrador"); }
        this.validateVersion(state, existing); existing.Estado = "PUBLICADA";
      } else if (command.Operation === "RETIRAR") {
        if (existing.Estado !== "PUBLICADA") { throw new Error("Solo se retira una version publicada"); }
        existing.Estado = "RETIRADA";
      } else { throw new Error("Operacion desconocida"); }
    } else { throw new Error("Operacion desconocida"); }
    this.state = state; this.revision++;
  };
  return DemoService;
});
