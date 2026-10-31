/* OData V4 transport: sequential writes, CSRF, server paging and optimistic locking. */
sap.ui.define([], function () {
  "use strict";
  var NS = "com.sap.gateway.srvd.yui_dm_o4.v0001";
  function quote(value) { return "'" + String(value).replace(/'/g, "''") + "'"; }
  function guid(value) {
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)) {
      throw new Error("UUID invalido");
    }
    return value;
  }
  function Service(root, transport) {
    this.root = new URL(root, typeof window === "undefined" ? "http://localhost" : window.location.origin);
    this.fetch = transport || fetch.bind(globalThis);
    this.token = null;
  }
  Service.quote = quote;
  Service.guid = guid;
  Service.prototype.url = function (path) {
    var url = new URL(path, this.root);
    if (url.origin !== this.root.origin || !url.pathname.startsWith(this.root.pathname)) {
      throw new Error("El enlace OData esta fuera del servicio configurado");
    }
    url.searchParams.set("sap-client", "100");
    return url;
  };
  Service.prototype.csrf = async function () {
    var response = await this.fetch(this.url(""), { credentials: "same-origin", headers: { "X-CSRF-Token": "Fetch", "Accept": "application/json" } });
    this.token = response.headers.get("x-csrf-token");
    if (!response.ok || !this.token || this.token.toLowerCase() === "required") {
      throw new Error("No se pudo obtener la sesion SAP. Conecta el sistema ABAP Cloud en SAP Fiori tools y vuelve a intentarlo.");
    }
  };
  Service.prototype.request = async function (path, method, body, etag, retried) {
    method = method || "GET";
    var write = method !== "GET";
    if (write && !this.token) { await this.csrf(); }
    var headers = { "Accept": "application/json", "OData-Version": "4.0" };
    if (write) { headers["X-CSRF-Token"] = this.token; headers["Content-Type"] = "application/json"; headers.Prefer = "return=representation"; }
    if (etag) { headers["If-Match"] = etag; }
    var response = await this.fetch(this.url(path), { method: method, credentials: "same-origin", headers: headers,
      body: body === undefined ? undefined : JSON.stringify(body) });
    if (response.status === 403 && /required/i.test(response.headers.get("x-csrf-token") || "") && !retried) {
      this.token = null; await this.csrf(); return this.request(path, method, body, etag, true);
    }
    var text = await response.text(), payload;
    if (text) { try { payload = JSON.parse(text); } catch (e) {
      throw new Error("SAP devolvio una pagina en lugar de JSON. Revisa el inicio de sesion de SAP Fiori tools y el proxy.");
    } }
    if (!response.ok) {
      var error = payload && payload.error;
      var message = error && (typeof error.message === "string" ? error.message : error.message && error.message.value);
      var details = error && error.details || [];
      var lines = [message].concat(details.map(function (d) { return d.message; })).filter(Boolean);
      var failure = new Error(response.status === 412 ? "Otro usuario modifico el registro. Recarga antes de volver a guardar." : lines.join("\n") || "Error SAP " + response.status);
      failure.status = response.status; throw failure;
    }
    if (payload && response.headers.get("etag")) { payload["@odata.etag"] = response.headers.get("etag"); }
    return payload;
  };
  Service.prototype.list = async function (set, query) {
    var params = new URLSearchParams(query || {});
    var path = set + (params.size ? "?" + params : ""), rows = [], visited = new Set();
    while (path) {
      if (visited.has(path)) { throw new Error("Paginacion OData circular"); }
      visited.add(path);
      var page = await this.request(path);
      if (!page || !Array.isArray(page.value)) { throw new Error("Respuesta OData sin coleccion"); }
      rows = rows.concat(page.value);
      path = page["@odata.nextLink"] ? new URL(page["@odata.nextLink"], this.url(path)).href : null;
    }
    return rows;
  };
  Service.prototype.requests = function () { return this.list("Solicitudes", { "$orderby": "CreadoEl desc" }); };
  Service.prototype.tasks = function (id) { return this.list("Tareas", { "$filter": "SolicitudUUID eq " + guid(id) }); };
  Service.prototype.segments = function (id) { return this.list("Segmentos", { "$filter": "SolicitudUUID eq " + guid(id), "$expand": "_Centro,_Almacen,_Ventas,_Valoracion,_Unidad" }); };
  Service.prototype.values = function (id) { return this.list("Datos", { "$filter": "SegmentoUUID eq " + guid(id) }); };
  Service.prototype.configuration = async function (request, area) {
    var result = await Promise.all([
      this.list("Campos", { "$filter": "Activo eq true" }),
      this.list("Secciones", { "$filter": "Activo eq true" }),
      this.list("Reglas", { "$filter": "FlujoId eq " + quote(request.FlujoId) + " and Version eq " + Number(request.Version) + " and Area eq " + quote(area) + " and Activo eq true" })
    ]);
    return { fields: result[0], sections: result[1], rules: result[2] };
  };
  Service.prototype.flows = function () { return this.list("Flujos", { "$filter": "Activo eq true" }); };
  Service.prototype.versions = function (flow) { return this.list("Versiones", { "$filter": "FlujoId eq " + quote(flow) + " and Estado eq 'PUBLICADA'" }); };
  Service.prototype.createRequest = function (body) { return this.request("Solicitudes", "POST", body); };
  Service.prototype.createSegment = function (body) { return this.request("Segmentos", "POST", body); };
  Service.prototype.action = function (set, row, name, parameters) {
    var id = set === "Solicitudes" ? row.SolicitudUUID : row.TareaUUID;
    if (!row["@odata.etag"]) { throw new Error("Falta ETag. Recarga el registro antes de ejecutar la accion."); }
    return this.request(set + "(" + guid(id) + ")/" + NS + "." + name, "POST", parameters || {}, row["@odata.etag"]);
  };
  Service.prototype.saveValue = async function (segment, field, value, existing) {
    var key = "Datos(SegmentoUUID=" + guid(segment) + ",CampoId=" + encodeURIComponent(quote(field)) + ")";
    var result;
    if (existing) {
      if (!existing["@odata.etag"]) { throw new Error("Falta ETag del valor. Recarga los datos."); }
      result = await this.request(key, "PATCH", { Valor: value }, existing["@odata.etag"]);
    } else {
      result = await this.request("Datos", "POST", { SegmentoUUID: guid(segment), CampoId: field, Valor: value });
    }
    if (result && result["@odata.etag"]) { return result; }
    try { return await this.request(key); }
    catch (error) {
      error.committed = true;
      error.message = "El valor se guardo, pero no se pudo releer su version. Usa Actualizar antes de editarlo otra vez. " + error.message;
      throw error;
    }
  };
  return Service;
});
