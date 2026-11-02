sap.ui.define(["./Schema"], function (Schema) {
  "use strict";
  // Semicolon-separated UTF-8 CSV. Quoting supports embedded separators, quotes and newlines.
  function parse(text) {
    if (text.length > 2 * 1024 * 1024) { throw new Error("El CSV supera 2 MB. Divide la carga en archivos mas pequenos."); }
    text = text.replace(/^\uFEFF/, "");
    var rows = [], row = [], value = "", quoted = false, closed = false;
    function cell() { row.push(value); value = ""; closed = false; }
    function line() { cell(); if (row.some(function (v) { return v.trim(); })) { rows.push(row); } row = []; }
    for (var i = 0; i < text.length; i++) {
      var char = text[i];
      if (quoted) {
        if (char === '"' && text[i + 1] === '"') { value += '"'; i++; }
        else if (char === '"') { quoted = false; closed = true; }
        else { value += char; }
      } else if (char === '"') {
        if (value || closed) { throw new Error("Comillas fuera de lugar en el CSV"); } quoted = true;
      } else if (char === ";") { cell(); }
      else if (char === "\n" || char === "\r") { if (char === "\r" && text[i + 1] === "\n") { i++; } line(); }
      else if (closed) { throw new Error("Se esperaba un separador despues de las comillas"); }
      else { value += char; }
    }
    if (quoted) { throw new Error("El CSV tiene comillas sin cerrar"); }
    if (value || row.length || closed) { line(); }
    if (!rows.length) { throw new Error("El CSV esta vacio"); }
    if (rows.length > 501) { throw new Error("Se admiten hasta 500 registros por carga"); }
    return rows;
  }
  function encode(value) {
    var text = value == null ? "" : String(value);
    // Prevent spreadsheet formula execution when opening exports in Excel/LibreOffice.
    if (/^[=+@\-\t\r']/.test(text)) { text = "'" + text; }
    return '"' + text.replace(/"/g, '""') + '"';
  }
  function exportRows(set, rows) {
    var fields = Schema.schemas[set].fields;
    return "\uFEFF" + [fields.map(function (f) { return f.name; }).join(";")].concat(rows.map(function (row) {
      return fields.map(function (f) { return encode(f.type === "boolean" ? row[f.name] ? "true" : "false" : row[f.name]); }).join(";");
    })).join("\r\n");
  }
  function preview(set, text, state, allowUpdates) {
    var schema = Schema.schemas[set], records = parse(text), header = records.shift().map(function (v) { return v.trim(); });
    if (new Set(header).size !== header.length || header.some(function (name) { return !schema.fields.some(function (f) { return f.name === name; }); })) { throw new Error("Cabeceras duplicadas o desconocidas. Descarga la plantilla de este mantenimiento."); }
    var missing = schema.fields.filter(function (f) { return f.required && !header.includes(f.name); });
    if (missing.length) { throw new Error("Faltan columnas obligatorias: " + missing.map(function (f) { return f.name; }).join(", ")); }
    if (!records.length) { throw new Error("El CSV no tiene registros para importar"); }
    var seen = new Set();
    return records.map(function (cells, index) {
      var row = {}, errors = [];
      if (cells.length !== header.length) { errors.push("Cantidad de columnas diferente a la cabecera"); }
      header.forEach(function (name, col) {
        var f = schema.fields.find(function (f) { return f.name === name; }), value = (cells[col] || "").trim();
        if (value.startsWith("'") && /^[=+@\-\t\r']/.test(value.slice(1))) { value = value.slice(1); }
        if (f.type === "boolean") {
          if (!["true", "false", "X", "", "1", "0"].includes(value)) { errors.push(f.label + ": usa true/false o X/vacio"); }
          value = ["true", "X", "1"].includes(value);
        }
        if (f.type === "integer" && /^\d+$/.test(value)) { value = Number(value); }
        row[name] = value;
      });
      var key = Schema.key(set, row), existing = state[set].find(function (r) { return Schema.key(set, r) === key; });
      // An update overlays only explicitly supplied columns; no implicit reset of omitted settings.
      row = Object.assign({}, existing || Schema.defaults(set), row);
      errors = errors.concat(Schema.validate(set, row));
      if (seen.has(key)) { errors.push("Clave repetida en el archivo"); } seen.add(key);
      if (existing && !allowUpdates) { errors.push("La clave ya existe; la carga esta en modo solo crear"); }
      if (existing && Schema.protectedRow(set, existing, state)) {
        if (set !== "Flujos" || schema.fields.some(function (f) { return f.name !== "Activo" && String(existing[f.name] || "") !== String(row[f.name] || ""); })) { errors.push("Registro protegido por una version publicada o retirada"); }
      }
      if (set === "Versiones" && !state.Flujos.some(function (f) { return f.FlujoId === row.FlujoId; })) { errors.push("El flujo no existe"); }
      if (["Pasos", "Reglas"].includes(set)) {
        var parent = state.Versiones.find(function (v) { return v.FlujoId === row.FlujoId && v.Version === Number(row.Version); });
        if (!parent || parent.Estado !== "BORRADOR") { errors.push("Selecciona una version borrador existente"); }
      }
      if (set === "Reglas") {
        if (!state.Campos.some(function (f) { return f.CampoId === row.CampoId && (!row.Activo || f.Activo); })) { errors.push("Campo inexistente o inactivo"); }
        if (!state.Secciones.some(function (s) { return s.SeccionId === row.SeccionId && (!row.Activo || s.Activo); })) { errors.push("Seccion inexistente o inactiva"); }
        if (row.Activo && !state.Pasos.some(function (p) { return p.FlujoId === row.FlujoId && p.Version === Number(row.Version) && p.Area === row.Area && p.Activo; })) { errors.push("Falta un paso activo del area"); }
      }
      return { line: index + 2, key: key, row: row, operation: existing ? "GUARDAR" : "CREAR", errors: errors, message: errors.length ? errors.join("; ") : existing ? "Actualizar" : "Crear" };
    });
  }
  return { parse: parse, exportRows: exportRows, preview: preview };
});
