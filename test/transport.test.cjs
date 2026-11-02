const { test } = require("node:test");
const assert = require("node:assert/strict");
const Transport = require("./load.cjs")("Transport");
const json = (body, options) => new Response(JSON.stringify(body), { headers: { "content-type": "application/json" }, ...options });
test("CSRF expiry retries only the rejected request, and propagates administrator concurrency errors", async () => {
  let tokens = 0, writes = 0;
  const transport = new Transport("http://localhost/service/", async (url, options) => {
    if (!options.method) { return new Response("", { headers: { "x-csrf-token": "T" + ++tokens } }); }
    writes++;
    assert.equal(options.headers["If-Match"], 'W/"1"');
    return writes === 1 ? new Response("", { status: 403, headers: { "x-csrf-token": "Required" } }) : json({ error: { message: "Conflict" } }, { status: 412 });
  });
  await assert.rejects(transport.request("Config/Aplicar", "POST", {}, 'W/"1"'), /Otro usuario/);
  assert.equal(tokens, 2); assert.equal(writes, 2);
});
test("paging follows query-only nextLink without losing collection path", async () => {
  let count = 0;
  const transport = new Transport("http://localhost/service/", async url => {
    assert.equal(url.pathname, "/service/Campos");
    return ++count === 1 ? json({ value: [{ CampoId: "A" }], "@odata.nextLink": "?$skiptoken=2" }) : json({ value: [{ CampoId: "B" }] });
  });
  assert.equal((await transport.list("Campos")).length, 2);
});
test("paging refuses links outside the service before transmitting cookies or tokens", async () => {
  let count = 0;
  const transport = new Transport("http://localhost/service/", async () => { count++; return json({ value: [], "@odata.nextLink": "https://other.test/" }); });
  await assert.rejects(transport.list("Campos"), /fuera del servicio/); assert.equal(count, 1);
});
test("an HTTP 200 login page is diagnosed as an authentication response rather than empty data", async () => {
  const transport = new Transport("http://localhost/service/", async () => new Response('<html><script>location="login"</script></html>'));
  await assert.rejects(transport.list("Campos"), error => error.code === "AUTH_REQUIRED");
});
