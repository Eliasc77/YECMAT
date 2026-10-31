const { test } = require("node:test");
const assert = require("node:assert/strict");
const Service = require("./load.cjs")("Service");
const root = "http://localhost/sap/service/";
const uuid = "12345678-1234-1234-1234-123456789abc";
const json = (body, options) => new Response(JSON.stringify(body), { headers: { "content-type": "application/json" }, ...options });

test("paging resolves query-only nextLink against the current entity collection", async () => {
  const urls = [];
  const service = new Service(root, async url => {
    urls.push(url);
    return urls.length === 1 ? json({ value: [{ CampoId: "A" }], "@odata.nextLink": "?$skiptoken=2" }) : json({ value: [{ CampoId: "B" }] });
  });
  assert.equal((await service.list("Campos")).length, 2);
  assert.equal(urls[1].pathname, "/sap/service/Campos");
  assert.equal(urls[1].searchParams.get("sap-client"), "100");
});

test("external nextLink is refused before forwarding any request or credentials", async () => {
  let calls = 0;
  const service = new Service(root, async () => { calls++; return json({ value: [], "@odata.nextLink": "https://other.test/" }); });
  await assert.rejects(service.list("Campos"), /fuera del servicio/);
  assert.equal(calls, 1);
});

test("PATCH includes the original ETag and CSRF; a 412 never retries the write", async () => {
  const requests = [];
  const service = new Service(root, async (url, options) => {
    requests.push(options);
    if (options.method === undefined) { return new Response("", { headers: { "x-csrf-token": "token" } }); }
    return json({ error: { message: "Conflict" } }, { status: 412 });
  });
  await assert.rejects(service.saveValue(uuid, "PRICE", "12.30", { "@odata.etag": 'W/"old"' }), /Otro usuario/);
  assert.equal(requests.length, 2);
  assert.equal(requests[1].headers["If-Match"], 'W/"old"');
  assert.equal(requests[1].headers["X-CSRF-Token"], "token");
  assert.equal(JSON.parse(requests[1].body).Valor, "12.30");
});

test("expired CSRF retries only after explicit Required response, once", async () => {
  let fetches = 0, writes = 0;
  const service = new Service(root, async (url, options) => {
    if (options.method === undefined) { fetches++; return new Response("", { headers: { "x-csrf-token": "token" + fetches } }); }
    writes++;
    return writes === 1 ? new Response("", { status: 403, headers: { "x-csrf-token": "Required" } }) : json({ SolicitudUUID: uuid });
  });
  await service.createRequest({ NumeroSolicitud: "TEST" });
  assert.equal(writes, 2); assert.equal(fetches, 2);
});

test("login HTML produces an actionable authentication error", async () => {
  const service = new Service(root, async () => new Response("<!DOCTYPE html><title>Login</title>"));
  await assert.rejects(service.requests(), /inicio de sesion/);
});

test("bound actions use namespace, instance key, parameters and original ETag", async () => {
  let call;
  const service = new Service(root, async (url, options) => { call = { url, options }; return json({}); });
  service.token = "token";
  await service.action("Solicitudes", { SolicitudUUID: uuid, "@odata.etag": 'W/"1"' }, "Iniciar", { ClasificacionBpm: "B" });
  assert.match(call.url.pathname, /Solicitudes\(.*\)\/com.sap.gateway.srvd.yui_dm_o4.v0001.Iniciar$/);
  assert.equal(JSON.parse(call.options.body).ClasificacionBpm, "B");
  assert.equal(call.options.headers["If-Match"], 'W/"1"');
});

test("missing ETag prevents any update request", async () => {
  const service = new Service(root, async () => { throw new Error("Should not reach network"); });
  await assert.rejects(service.saveValue(uuid, "PRICE", "1", {}), /ETag/);
});

test("204 PATCH fetches persisted entity to obtain the next ETag", async () => {
  const methods = [];
  const service = new Service(root, async (url, options) => {
    methods.push(options.method);
    return options.method === "PATCH" ? new Response(null, { status: 204 }) : json({ Valor: "1", "@odata.etag": 'W/"new"' });
  });
  service.token = "token";
  const result = await service.saveValue(uuid, "A/B?C", "1", { "@odata.etag": 'W/"old"' });
  assert.deepEqual(methods, ["PATCH", "GET"]);
  assert.equal(result["@odata.etag"], 'W/"new"');
});

test("failed reread after a committed PATCH is marked as committed, avoiding another POST", async () => {
  const service = new Service(root, async (url, options) => options.method === "PATCH" ? new Response(null, { status: 204 }) : json({ error: { message: "Unavailable" } }, { status: 503 }));
  service.token = "token";
  await assert.rejects(service.saveValue(uuid, "PRICE", "1", { "@odata.etag": 'W/"old"' }), error => error.committed === true && /se guardo/.test(error.message));
});
