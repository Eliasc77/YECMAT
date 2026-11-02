/* OData V4 transport: sequential writes, CSRF, server paging and optimistic locking. */
sap.ui.define([], function () {
  "use strict";
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
  function loginError(status) {
    var error = new Error("SAP solicita iniciar sesion. Deten y vuelve a ejecutar npm start; completa el acceso de SAP Fiori tools.");
    error.code = "AUTH_REQUIRED"; error.status = status;
    error.help = "El proxy debe usar el host API .abap. con authenticationType: reentranceTicket. La sesion de la pagina remota de SAP no sustituye la sesion del proxy.";
    return error;
  }
  Service.prototype.metadata = async function () {
    var response = await this.fetch(this.url("$metadata"), { credentials: "same-origin", cache: "no-store", headers: { "Accept": "application/xml" } });
    var text = await response.text();
    if (response.status === 401 || /<html[\s>]/i.test(text) && /oauth|login|authorize/i.test(text)) { throw loginError(response.status); }
    if (!response.ok) {
      var error = new Error(response.status === 403 ? "SAP denego el acceso al servicio administrativo. Revisa sus autorizaciones de acceso." : "No se pudo leer el servicio de mantenimiento. Revisa la URI del manifest y publica el binding YBD_DM_CFG_O4.");
      error.code = response.status === 403 ? "SERVICE_ACCESS" : "SERVICE_UNAVAILABLE"; error.status = response.status; throw error;
    }
    return text;
  };
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
      throw loginError(response.status);
    }
  };
  Service.prototype.request = async function (path, method, body, etag, retried) {
    method = method || "GET";
    var write = method !== "GET";
    if (write && !this.token) { await this.csrf(); }
    var headers = { "Accept": "application/json", "OData-Version": "4.0" };
    if (write) { headers["X-CSRF-Token"] = this.token; headers["Content-Type"] = "application/json"; headers.Prefer = "return=representation"; }
    if (etag) { headers["If-Match"] = etag; }
    var response = await this.fetch(this.url(path), { method: method, credentials: "same-origin", cache: "no-store", headers: headers,
      body: body === undefined ? undefined : JSON.stringify(body) });
    if (response.status === 403 && /required/i.test(response.headers.get("x-csrf-token") || "") && !retried) {
      this.token = null; await this.csrf(); return this.request(path, method, body, etag, true);
    }
    var text = await response.text(), payload;
    if (response.status === 401 || /<html[\s>]/i.test(text) && /oauth|login|authorize/i.test(text)) { throw loginError(response.status); }
    if (text) { try { payload = JSON.parse(text); } catch (e) {
      var invalid = new Error("El servicio devolvio una pagina en lugar de datos OData. Revisa el inicio de sesion y la ruta del binding.");
      invalid.code = "INVALID_RESPONSE"; invalid.status = response.status; throw invalid;
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
  return Service;
});
