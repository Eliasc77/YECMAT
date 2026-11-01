sap.ui.define([], function () {
  "use strict";
  var choices = function (values) { return values.map(function (v) { return typeof v === "string" ? { key: v, text: v } : { key: v[0], text: v[1] }; }); };
  var field = function (name, label, length, required, extra) { return Object.assign({ name: name, label: label, max: length, required: !!required, type: "text" }, extra || {}); };
  var id = function (name, label, length) { return field(name, label, length, true, { key: true, identifier: true }); };
  var flow = function () { return field("FlujoId", "Flujo", 20, true, { key: true, ref: "Flujos" }); };
  var version = function () { return field("Version", "Version", 0, true, { key: true, type: "integer", min: 1, ref: "Versiones" }); };
  var order = function () { return field("Orden", "Orden", 0, true, { type: "integer", min: 0 }); };
  var active = function () { return field("Activo", "Activo", 0, false, { type: "boolean" }); };
  var description = function () { return field("Descripcion", "Descripcion", 80, true); };
  var schemas = {
    Campos: {
      title: "Campos", icon: "sap-icon://form", description: "Define el dato SAP, su nivel organizativo y el tipo de captura.",
      keys: ["CampoId"], columns: ["CampoId", "Descripcion", "TipoSegmento", "TipoDato", "Longitud", "Activo"],
      fields: [id("CampoId", "Identificador del campo", 30), description(), id("TablaSap", "Tabla SAP", 30), id("CampoSap", "Campo SAP", 30),
        field("TipoSegmento", "Contexto", 10, true, { options: choices([["GENERAL", "General"], ["CENTRO", "Centro"], ["ALMACEN", "Almacen"], ["VENTAS", "Ventas"], ["VALORACION", "Valoracion"], ["UNIDAD", "Unidad alternativa"]]) }),
        field("TipoDato", "Tipo de dato", 10, true, { options: choices(["CHAR", "STRING", "NUMC", "DEC", "CURR", "QUAN", "INT1", "INT2", "INT4", "DATS", "BOOL", "UNIT", "CUKY", "LANG"]) }),
        field("Longitud", "Longitud", 0, true, { type: "integer", min: 1, limit: 1333 }), field("Decimales", "Decimales", 0, true, { type: "integer", min: 0, limit: 1333 }),
        field("TipoControl", "Control de captura", 20, true, { options: choices(["Input", "TextArea", "DatePicker", "CheckBox", "Decimal", "Integer"]) }),
        field("AyudaValores", "Referencia de ayuda de valores", 30, false), active()]
    },
    Secciones: { title: "Secciones", icon: "sap-icon://group-2", description: "Agrupa y ordena los campos que se muestran en la captura.", keys: ["SeccionId"], columns: ["SeccionId", "Descripcion", "Orden", "Activo"], fields: [id("SeccionId", "Identificador de seccion", 20), description(), order(), active()] },
    Flujos: { title: "Flujos", icon: "sap-icon://workflow-tasks", description: "Define para que tipo de material y operacion se utiliza cada flujo.", keys: ["FlujoId"], columns: ["FlujoId", "Descripcion", "TipoMaterial", "TipoOperacion", "CentroCriterio", "Activo"], fields: [id("FlujoId", "Identificador del flujo", 20), description(), id("TipoMaterial", "Tipo de material", 4), field("TipoOperacion", "Operacion", 1, true, { options: choices([["C", "C · Crear / copiar"], ["M", "M · Modificar"], ["I", "I · Inactivar"]]) }), field("CentroCriterio", "Centro criterio (vacio: cualquiera)", 4, false, { identifier: true }), active()] },
    Versiones: { title: "Versiones", icon: "sap-icon://history", description: "Prepara borradores, copia versiones y publica la configuracion validada.", keys: ["FlujoId", "Version"], columns: ["FlujoId", "Version", "Estado", "VigenteDesde", "VigenteHasta"], fields: [flow(), version(), field("VigenteDesde", "Vigente desde", 10, true, { type: "date" }), field("VigenteHasta", "Vigente hasta (vacio: sin fin)", 10, false, { type: "date" })] },
    Pasos: { title: "Pasos", icon: "sap-icon://activity-items", description: "Configura las areas y tareas de cada version. Las tareas se abren en paralelo.", keys: ["FlujoId", "Version", "PasoId"], columns: ["FlujoId", "Version", "PasoId", "Area", "CondicionBpm", "Obligatorio", "Activo"], fields: [flow(), version(), id("PasoId", "Identificador del paso", 20), id("Area", "Area", 10), field("Fase", "Fase (descriptiva)", 20, true, { identifier: true }), field("CondicionBpm", "Clasificacion aplicable", 1, false, { options: choices([["", "A y B"], ["A", "A · Con revision"], ["B", "B · Sin revision"]]) }), order(), field("Obligatorio", "Tarea obligatoria", 0, false, { type: "boolean" }), active()] },
    Reglas: { title: "Reglas", icon: "sap-icon://checklist", description: "Relaciona flujo, version, area y campo. Define obligatoriedad y seccion.", keys: ["FlujoId", "Version", "Area", "CampoId"], columns: ["FlujoId", "Version", "Area", "CampoId", "SeccionId", "EstadoCampo", "Activo"], fields: [flow(), version(), field("Area", "Area", 10, true, { key: true, ref: "Areas" }), field("CampoId", "Campo", 30, true, { key: true, ref: "Campos" }), field("SeccionId", "Seccion", 20, true, { ref: "Secciones" }), field("EstadoCampo", "Estado del campo", 1, true, { options: choices([["M", "M · Obligatorio"], ["O", "O · Opcional"], ["I", "I · Invisible"], ["R", "R · Solo lectura"]]) }), order(), active()] }
  };
  // Only actual row identity fields are immutable. TablaSap/TipoMaterial/Area are not keys by themselves.
  Object.keys(schemas).forEach(function (set) { schemas[set].fields.forEach(function (f) { f.key = schemas[set].keys.includes(f.name); }); });
  var integerNames = ["Longitud", "Decimales", "Orden", "Version", "VersionDestino"];
  var boolNames = ["Activo", "Obligatorio"];
  var allNames = ["EntitySet", "Operation", "CampoId", "Descripcion", "TablaSap", "CampoSap", "TipoSegmento", "TipoDato", "Longitud", "Decimales", "AyudaValores", "TipoControl", "Activo", "SeccionId", "Orden", "FlujoId", "TipoMaterial", "TipoOperacion", "CentroCriterio", "Version", "VigenteDesde", "VigenteHasta", "PasoId", "Area", "Fase", "CondicionBpm", "Obligatorio", "EstadoCampo", "VersionDestino"];
  function defaults(set) {
    var row = { Activo: true, Orden: 10, Longitud: 40, Decimales: 0, TipoSegmento: "GENERAL", TipoDato: "CHAR", TipoControl: "Input", TipoOperacion: "C", EstadoCampo: "O", Version: 1, Fase: "CAPTURA", CondicionBpm: "", Obligatorio: true, VigenteDesde: new Date().toISOString().slice(0, 10), VigenteHasta: "9999-12-31" };
    schemas[set].fields.forEach(function (f) { if (!(f.name in row)) { row[f.name] = ""; } });
    return row;
  }
  function key(set, row) { return schemas[set].keys.map(function (k) { return String(row[k] || ""); }).join(" / "); }
  function protectedRow(set, row, state) {
    if (!row) { return false; }
    function frozen(rule) { var v = state.Versiones.find(function (x) { return x.FlujoId === rule.FlujoId && x.Version === rule.Version; }); return !v || v.Estado !== "BORRADOR"; }
    if (set === "Versiones") { return row.Estado !== "BORRADOR"; }
    if (set === "Pasos" || set === "Reglas") { return frozen(row); }
    if (set === "Campos" || set === "Secciones") {
      var prop = set === "Campos" ? "CampoId" : "SeccionId";
      return state.Reglas.some(function (r) { return r[prop] === row[prop] && frozen(r); });
    }
    if (set === "Flujos") { return state.Versiones.some(function (v) { return v.FlujoId === row.FlujoId && v.Estado !== "BORRADOR"; }); }
    return false;
  }
  function command(set, row, operation) {
    var result = {};
    allNames.forEach(function (name) { result[name] = integerNames.includes(name) ? 0 : boolNames.includes(name) ? false : ""; });
    schemas[set].fields.forEach(function (f) {
      var value = row[f.name];
      if (f.type === "integer") { value = Number(value || 0); }
      else if (f.type === "boolean") { value = !!value; }
      else { value = String(value || "").trim(); }
      if (f.type === "date") { value = value.replace(/-/g, ""); }
      result[f.name] = value;
    });
    result.EntitySet = set; result.Operation = operation || "GUARDAR";
    if (row.VersionDestino) { result.VersionDestino = Number(row.VersionDestino); }
    return result;
  }
  function validate(set, row) {
    var errors = [];
    schemas[set].fields.forEach(function (f) {
      var value = row[f.name];
      if (f.type === "boolean") { return; }
      var text = String(value == null ? "" : value).trim();
      if (f.required && !text) { errors.push(f.label + ": obligatorio"); return; }
      if (!text) { return; }
      if (f.max && text.length > f.max) { errors.push(f.label + ": maximo " + f.max + " caracteres"); }
      if (f.identifier && !/^[A-Z0-9_]+$/.test(text)) { errors.push(f.label + ": usa mayusculas, numeros o guion bajo"); }
      if (f.type === "integer" && (!/^\d+$/.test(text) || Number(text) < f.min || Number(text) > (f.limit || 2147483647))) { errors.push(f.label + ": numero entero fuera de rango"); }
      if (f.type === "date") { var date = new Date(text + "T00:00:00Z"); if (!/^\d{4}-\d{2}-\d{2}$/.test(text) || !Number.isFinite(date.getTime()) || date.toISOString().slice(0, 10) !== text || text.startsWith("0000")) { errors.push(f.label + ": fecha invalida"); } }
      if (f.options && !f.options.some(function (option) { return option.key === text; })) { errors.push(f.label + ": opcion invalida"); }
    });
    if (set === "Campos") {
      if (Number(row.Decimales) > Number(row.Longitud) || !["DEC", "CURR", "QUAN"].includes(row.TipoDato) && Number(row.Decimales) !== 0) { errors.push("Decimales incompatibles con la longitud o el tipo de dato"); }
      if (row.TipoDato === "DATS" && Number(row.Longitud) !== 8 || row.TipoDato === "BOOL" && Number(row.Longitud) !== 1) { errors.push("DATS requiere longitud 8 y BOOL longitud 1"); }
    }
    if (set === "Versiones" && row.VigenteHasta && row.VigenteHasta < row.VigenteDesde) { errors.push("Vigente hasta debe ser igual o posterior a Vigente desde"); }
    return errors;
  }
  function options(set, f, row, state, editing) {
    if (f.options) { return f.options; }
    if (f.ref === "Flujos") { return state.Flujos.map(function (r) { return { key: r.FlujoId, text: r.FlujoId + " · " + r.Descripcion }; }); }
    if (f.ref === "Versiones" && set !== "Versiones") { return state.Versiones.filter(function (v) { return v.FlujoId === row.FlujoId && (v.Estado === "BORRADOR" || editing && v.Version === row.Version); }).map(function (v) { return { key: String(v.Version), text: "Version " + v.Version + " · " + v.Estado }; }); }
    if (f.ref === "Areas") { return Array.from(new Set(state.Pasos.filter(function (p) { return p.FlujoId === row.FlujoId && p.Version === Number(row.Version) && p.Activo; }).map(function (p) { return p.Area; }))).map(function (v) { return { key: v, text: v }; }); }
    if (f.ref === "Campos" || f.ref === "Secciones") { var property = f.ref === "Campos" ? "CampoId" : "SeccionId"; return state[f.ref].map(function (r) { return { key: r[property], text: r[property] + " · " + r.Descripcion }; }); }
    return null;
  }
  return { sets: Object.keys(schemas), schemas: schemas, defaults: defaults, key: key, protectedRow: protectedRow, command: command, validate: validate, options: options, parameters: allNames };
});
