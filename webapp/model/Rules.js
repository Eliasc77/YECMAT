sap.ui.define([], function () {
  "use strict";
  var contexts = {
    GENERAL: { label: "General", fields: [] },
    CENTRO: { label: "Centro", nav: "_Centro", fields: [["Centro", "Centro", 4, true]] },
    ALMACEN: { label: "Almacen", nav: "_Almacen", fields: [["Centro", "Centro", 4, true], ["Almacen", "Almacen", 4, true]] },
    VENTAS: { label: "Ventas", nav: "_Ventas", fields: [["OrgVentas", "Organizacion de ventas", 4, true], ["Canal", "Canal", 2, true]] },
    VALORACION: { label: "Valoracion", nav: "_Valoracion", fields: [["AreaValoracion", "Area de valoracion", 4, true], ["TipoValoracion", "Tipo de valoracion", 10, false]] },
    UNIDAD: { label: "Unidad alternativa", nav: "_Unidad", fields: [["UnidadAlternativa", "Unidad alternativa", 3, true]] }
  };
  function groups(config, type) {
    var fields = new Map(config.fields.filter(function (f) { return f.Activo && f.TipoSegmento === type; }).map(function (f) { return [f.CampoId, f]; }));
    var sections = new Map(config.sections.filter(function (s) { return s.Activo; }).map(function (s) { return [s.SeccionId, s]; }));
    var grouped = new Map(), seen = new Set();
    config.rules.filter(function (r) { return r.Activo && r.EstadoCampo !== "I" && fields.has(r.CampoId) && sections.has(r.SeccionId); })
      .sort(function (a, b) { return a.Orden - b.Orden || a.CampoId.localeCompare(b.CampoId); }).forEach(function (rule) {
        if (seen.has(rule.CampoId)) { throw new Error("Reglas duplicadas para " + rule.CampoId + ". Corrige la configuracion."); }
        seen.add(rule.CampoId);
        var section = sections.get(rule.SeccionId);
        if (!grouped.has(section.SeccionId)) { grouped.set(section.SeccionId, { id: section.SeccionId, title: section.Descripcion, order: section.Orden, fields: [] }); }
        grouped.get(section.SeccionId).fields.push(Object.assign({}, fields.get(rule.CampoId), { required: rule.EstadoCampo === "M", editable: rule.EstadoCampo === "M" || rule.EstadoCampo === "O" }));
      });
    return Array.from(grouped.values()).sort(function (a, b) { return a.order - b.order || a.title.localeCompare(b.title); });
  }
  function validate(field, value, required) {
    value = String(value || "");
    if (!value) { return required && field.required ? "Campo obligatorio" : ""; }
    var type = field.TipoDato.toUpperCase(), numeric = /^(DEC|CURR|QUAN|INT1|INT2|INT4)$/.test(type);
    if (value.length > 1333 || (!numeric && value.length > field.Longitud)) { return "Longitud maxima: " + field.Longitud; }
    if (type === "NUMC" && !/^\d+$/.test(value)) { return "Usa solo digitos"; }
    if (/^INT[124]$/.test(type)) {
      var number = Number(value), bounds = { INT1: [0, 255], INT2: [-32768, 32767], INT4: [-2147483648, 2147483647] }[type];
      if (!/^-?\d+$/.test(value) || value.replace(/^-/, "").length > field.Longitud || number < bounds[0] || number > bounds[1]) { return "Entero fuera de formato o rango"; }
    }
    if (/^(DEC|CURR|QUAN)$/.test(type)) {
      if (!/^-?\d+(\.\d+)?$/.test(value)) { return "Usa punto decimal, sin separador de miles"; }
      var parts = value.replace(/^-/, "").split(".");
      if ((parts[1] || "").length > field.Decimales || parts.join("").length > field.Longitud) { return "Precision maxima: " + field.Longitud + "; decimales: " + field.Decimales; }
    }
    if (type === "DATS") {
      var date = new Date(value.slice(0, 4) + "-" + value.slice(4, 6) + "-" + value.slice(6, 8) + "T00:00:00Z");
      if (!/^\d{8}$/.test(value) || !Number(value.slice(0, 4)) || !Number.isFinite(date.getTime()) || date.toISOString().slice(0, 10).replace(/-/g, "") !== value) { return "Fecha valida con formato YYYYMMDD"; }
    }
    if (type === "BOOL" && value !== "X") { return "Valor permitido: X o vacio"; }
    if (/^(UNIT|CUKY|LANG)$/.test(type) && value !== value.toUpperCase()) { return "Usa la clave interna SAP en mayusculas"; }
    if (!/^(CHAR|STRING|NUMC|INT1|INT2|INT4|DEC|CURR|QUAN|DATS|BOOL|UNIT|CUKY|LANG)$/.test(type)) { return "Tipo de dato no soportado"; }
    return "";
  }
  function segmentPayload(requestId, type, values) {
    var context = contexts[type];
    if (!context) { throw new Error("Tipo de contexto desconocido"); }
    var body = { SolicitudUUID: requestId, TipoSegmento: type }, child = {};
    context.fields.forEach(function (f) {
      var value = String(values[f[0]] || "").trim();
      if ((f[3] && !value) || value.length > f[2] || value !== value.toUpperCase()) { throw new Error(f[1] + ": ingresa una clave SAP en mayusculas (maximo " + f[2] + ")"); }
      child[f[0]] = value;
    });
    // Single-valued composition: create root and subtype in ONE deep insert.
    if (context.nav) { body[context.nav] = child; }
    return body;
  }
  function label(segment) {
    var context = contexts[segment.TipoSegmento];
    if (!context) { return segment.TipoSegmento; }
    if (!context.nav) { return context.label; }
    var child = segment[context.nav];
    return context.label + " · " + (child ? context.fields.map(function (f) { return child[f[0]]; }).filter(Boolean).join(" / ") : segment.ContextoClave || "");
  }
  return { contexts: contexts, groups: groups, validate: validate, segmentPayload: segmentPayload, label: label };
});
