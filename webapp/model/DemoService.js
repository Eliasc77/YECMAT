/* In-memory demonstration only. No SAP network calls and no persistence. */
sap.ui.define(["./Rules"], function (Rules) {
  "use strict";
  var copy = function (data) { return JSON.parse(JSON.stringify(data)); };
  var id = function () { return crypto.randomUUID(); };
  function DemoService() {
    this.data = { requests: [], tasks: [], segments: [], values: [] };
    this.config = { fields: [], sections: [], rules: [] };
    var profile = [
      ["MAKT_MAKTX", "Descripcion del material", "GENERAL", "CHAR", 40, 0, "PCP", "BASICOS", "Datos basicos", "M"],
      ["MARA_MEINS", "Unidad base", "GENERAL", "UNIT", 3, 0, "PCP", "BASICOS", "Datos basicos", "M"],
      ["MARA_MATKL", "Grupo de articulos", "GENERAL", "CHAR", 9, 0, "PCP", "BASICOS", "Datos basicos", "M"],
      ["MARC_EKGRP", "Grupo de compras", "CENTRO", "CHAR", 3, 0, "LOG", "COMPRAS", "Compras", "M"],
      ["MARD_LGPBE", "Ubicacion de almacen", "ALMACEN", "CHAR", 10, 0, "LOG", "ALMACEN", "Almacen", "O"],
      ["MVKE_MTPOS", "Grupo de tipos de posicion", "VENTAS", "CHAR", 4, 0, "PCP", "VENTAS", "Ventas", "O"],
      ["MBEW_STPRS", "Precio estandar", "VALORACION", "CURR", 11, 2, "CONT", "VALORACION", "Valoracion", "M"],
      ["MARM_UMREZ", "Numerador de conversion", "UNIDAD", "DEC", 5, 0, "PCP", "UNIDADES", "Unidades", "M"],
      ["MARM_UMREN", "Denominador de conversion", "UNIDAD", "DEC", 5, 0, "PCP", "UNIDADES", "Unidades", "M"]
    ];
    profile.forEach(function (p, index) {
      this.config.fields.push({ CampoId: p[0], Descripcion: p[1], TipoSegmento: p[2], TipoDato: p[3], Longitud: p[4], Decimales: p[5], TipoControl: p[3] === "CURR" || p[3] === "DEC" ? "Decimal" : "Input", Activo: true });
      if (!this.config.sections.some(function (s) { return s.SeccionId === p[7]; })) { this.config.sections.push({ SeccionId: p[7], Descripcion: p[8], Orden: index * 10, Activo: true }); }
      this.config.rules.push({ CampoId: p[0], Area: p[6], SeccionId: p[7], EstadoCampo: p[9], Orden: index * 10, Activo: true });
    }, this);
    var request = { SolicitudUUID: id(), NumeroSolicitud: "DEMO-001", FlujoId: "DM_DEMO_ZFER", Version: 1, TipoMaterial: "ZFER", TipoOperacion: "C", Estado: "EN_CURSO", CreadoPor: "DEMO", CreadoEl: new Date().toISOString(), ClasificacionBpm: "B", "@odata.etag": 'W/"1"' };
    this.data.requests.push(request); this.makeTasks(request);
    this.data.tasks[0].Estado = "EN_CURSO";
  }
  DemoService.prototype.makeTasks = function (r) {
    ["PCP", "LOG", "CONT"].forEach(function (area) { this.data.tasks.push({ TareaUUID: id(), SolicitudUUID: r.SolicitudUUID, Area: area, PasoId: area + "_CAPTURA", Estado: "PENDIENTE", Responsable: "DEMO", "@odata.etag": 'W/"1"' }); }, this);
  };
  DemoService.prototype.requests = async function () { return copy(this.data.requests); };
  DemoService.prototype.tasks = async function (request) { return copy(this.data.tasks.filter(function (t) { return t.SolicitudUUID === request; })); };
  DemoService.prototype.segments = async function (request) { return copy(this.data.segments.filter(function (s) { return s.SolicitudUUID === request; })); };
  DemoService.prototype.values = async function (segment) { return copy(this.data.values.filter(function (v) { return v.SegmentoUUID === segment; })); };
  DemoService.prototype.configuration = async function (r, area) { var result = copy(this.config); result.rules = result.rules.filter(function (rule) { return rule.Area === area; }); return result; };
  DemoService.prototype.flows = async function () { return [{ FlujoId: "DM_DEMO_ZFER", Descripcion: "Demo materiales", TipoMaterial: "ZFER", TipoOperacion: "C", Activo: true }]; };
  DemoService.prototype.versions = async function () { return [{ Version: 1, Estado: "PUBLICADA", VigenteDesde: "2020-01-01", VigenteHasta: "9999-12-31" }]; };
  DemoService.prototype.createRequest = async function (body) {
    if (this.data.requests.some(function (r) { return r.NumeroSolicitud === body.NumeroSolicitud; })) { throw new Error("Numero de solicitud duplicado"); }
    var row = Object.assign({}, body, { SolicitudUUID: id(), Estado: "BORRADOR", CreadoPor: "DEMO", CreadoEl: new Date().toISOString(), "@odata.etag": 'W/"1"' });
    this.data.requests.unshift(row); return copy(row);
  };
  DemoService.prototype.createSegment = async function (body) {
    var signature = JSON.stringify(body);
    if (this.data.segments.some(function (s) { return s._signature === signature; })) { throw new Error("El contexto ya existe"); }
    var row = Object.assign(copy(body), { SegmentoUUID: id(), _signature: signature });
    this.data.segments.push(row); return copy(row);
  };
  DemoService.prototype.saveValue = async function (segment, field, value, existing) {
    var row = this.data.values.find(function (v) { return v.SegmentoUUID === segment && v.CampoId === field; });
    if (existing && row && row["@odata.etag"] !== existing["@odata.etag"]) { throw new Error("Conflicto de version demo"); }
    if (!row) { row = { SegmentoUUID: segment, CampoId: field }; this.data.values.push(row); }
    Object.assign(row, { Valor: value, "@odata.etag": 'W/"' + Date.now() + '"' }); return copy(row);
  };
  DemoService.prototype.action = async function (set, row, name, params) {
    var request = this.data.requests.find(function (r) { return r.SolicitudUUID === row.SolicitudUUID; });
    var task = this.data.tasks.find(function (t) { return t.TareaUUID === row.TareaUUID; });
    if (set === "Tareas") {
      if (name === "Finalizar") {
        var config = await this.configuration(request, task.Area), segments = await this.segments(request.SolicitudUUID);
        var requiredTypes = new Set(config.rules.filter(function (r) { return r.EstadoCampo === "M"; }).map(function (r) { return config.fields.find(function (f) { return f.CampoId === r.CampoId; }).TipoSegmento; }));
        requiredTypes.forEach(function (type) { if (!segments.some(function (s) { return s.TipoSegmento === type; })) { throw new Error("Falta el contexto obligatorio: " + type); } });
        segments.forEach(function (s) { Rules.groups(config, s.TipoSegmento).forEach(function (g) { g.fields.forEach(function (f) {
          var value = this.data.values.find(function (v) { return v.SegmentoUUID === s.SegmentoUUID && v.CampoId === f.CampoId; });
          var error = Rules.validate(f, value && value.Valor, true); if (error) { throw new Error(f.Descripcion + ": " + error); }
        }, this); }, this); }, this);
        task.Estado = "FINALIZADA";
      } else { task.Estado = "EN_CURSO"; }
      return copy(task);
    }
    if (name === "Iniciar") { request.Estado = "EN_CURSO"; request.ClasificacionBpm = params.ClasificacionBpm; this.makeTasks(request); }
    if (name === "Cerrar") {
      if (this.data.tasks.some(function (t) { return t.SolicitudUUID === request.SolicitudUUID && t.Estado !== "FINALIZADA"; })) { throw new Error("Finaliza todas las tareas antes de cerrar"); }
      request.Estado = request.ClasificacionBpm === "A" ? "REVISION" : "LISTA_INTEG";
    }
    if (name === "Aprobar") { request.Estado = "LISTA_INTEG"; }
    if (name === "Reabrir") {
      var reopen = this.data.tasks.find(function (t) { return t.TareaUUID === params.TareaUUID && t.SolicitudUUID === request.SolicitudUUID; });
      if (!reopen) { throw new Error("Selecciona una tarea de la solicitud"); }
      reopen.Estado = "PENDIENTE"; request.Estado = "EN_CURSO";
    }
    return copy(request);
  };
  return DemoService;
});
