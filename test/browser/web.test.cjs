const { test } = require("node:test");
const assert = require("node:assert/strict");
const { spawn } = require("node:child_process");
const { chromium } = require("playwright");
const path = require("node:path");
const fs = require("node:fs/promises");
const load = require("../load.cjs"), Schema = load("Schema");
const Demo = load("DemoService", { "./Schema": Schema });
const seed = require("../../webapp/model/demo.json");

function contract(namespace = "test.admin.v0002", wrong = false) {
  const sets = ["Configuration", ...Schema.sets].filter(s => !wrong || s !== "Configuration").map(name => `<EntitySet Name="${name}" EntityType="${namespace}.${name}Type"/>`).join("");
  const params = Schema.parameters.map(name => `<Parameter Name="${name}" Type="${["Longitud", "Decimales", "Orden", "Version", "VersionDestino"].includes(name) ? "Edm.Int32" : ["Activo", "Obligatorio"].includes(name) ? "Edm.Boolean" : "Edm.String"}"/>`).join("");
  return `<edmx:Edmx xmlns:edmx="http://docs.oasis-open.org/odata/ns/edmx" Version="4.0"><edmx:DataServices><Schema xmlns="http://docs.oasis-open.org/odata/ns/edm" Namespace="${namespace}" Alias="self"><EntityContainer Name="Container">${sets}</EntityContainer><Action Name="Aplicar" IsBound="true"><Parameter Name="_it" Type="self.ConfigurationType"/>${params}</Action></Schema></edmx:DataServices></edmx:Edmx>`;
}
async function setup(t) {
  const base = path.resolve(__dirname, "../.."), port = 8084;
  const server = spawn(process.execPath, [path.join(base, "node_modules/@ui5/cli/bin/ui5.cjs"), "serve", "--config", "ui5-demo.yaml", "--port", String(port)], { cwd: base, env: process.env, stdio: ["ignore", "pipe", "pipe"] });
  let logs = ""; server.stdout.on("data", d => { logs += d; }); server.stderr.on("data", d => { logs += d; });
  t.after(() => server.kill());
  await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => { clearInterval(poll); reject(new Error(logs)); }, 45000);
    const poll = setInterval(() => { if (logs.includes("Server started")) { clearInterval(poll); clearTimeout(timeout); resolve(); } }, 100);
    server.once("exit", code => { clearInterval(poll); clearTimeout(timeout); reject(new Error("Server exit " + code + ": " + logs)); });
  });
  const browser = await chromium.launch({ executablePath: process.env.DM_CHROMIUM_PATH || undefined }); t.after(() => browser.close());
  return { browser, url: `http://localhost:${port}/index.html` };
}
function actions(page) {
  const button = name => {
    const locator = page.getByRole("button", { name, exact: true }), click = locator.click.bind(locator);
    locator.click = async (...args) => { if (!await locator.isVisible()) { await page.locator(".sapMOTBOverflowButton:visible").last().click(); } return click(...args); };
    return locator;
  };
  return { button, tab: name => page.getByRole("tab", { name: new RegExp(name) }).click(), dialog: () => page.locator(".sapMDialog") };
}

test("web: CSV preview/import/export, version review and SAP connection diagnostics", { timeout: 180000 }, async t => {
  const { browser, url } = await setup(t);
  const page = await browser.newPage({ viewport: { width: 1600, height: 1100 } });
  const errors = [];
  page.on("pageerror", e => errors.push(e.message));
  const { button, tab, dialog } = actions(page);
  await page.goto(url + "?mode=demo"); await page.getByText("MAKT_MAKTX", { exact: true }).waitFor();
  await tab("Secciones"); await button("Importar CSV").click();
  const csv = 'SeccionId;Descripcion;Orden;Activo\nBULK_A;Seccion A;1;true\nBULK_B;Seccion B;2;true';
  await dialog().locator('input[type="file"]').setInputFiles({ name: "secciones.csv", mimeType: "text/csv", buffer: Buffer.from(csv) });
  await dialog().getByRole("textbox").filter({ hasNot: page.locator('input[type="file"]') }).last().waitFor();
  await button("Validar archivo").click();
  await page.getByText(/2 registros; 0 con errores/).waitFor();
  await button("Importar registros").click(); await dialog().waitFor({ state: "hidden" });
  await page.getByText("Importacion completada: 2 registros confirmados en Secciones", { exact: true }).waitFor();
  await page.getByText("BULK_A", { exact: true }).waitFor();
  const downloadEvent = page.waitForEvent("download"); await button("Exportar CSV").click();
  const download = await downloadEvent;
  assert.ok((await fs.readFile(await download.path(), "utf8")).includes('"BULK_B"'));
  await button("Importar CSV").click();
  await dialog().getByPlaceholder(/CSV UTF-8/).fill(csv); await button("Validar archivo").click();
  await page.getByText(/2 registros; 2 con errores/).waitFor();
  assert.equal(await button("Importar registros").isEnabled(), false); await button("Cancelar").click();
  await tab("Versiones"); await page.getByText("DM_DEMO_ZFER", { exact: true }).click();
  await button("Revisar version").click();
  await page.getByText(/Sin pendientes detectados/).waitFor(); await button("Cerrar").click();
  await button("Copiar version").click(); await button("Guardar").click(); await dialog().waitFor({ state: "hidden" });
  await page.getByRole("row").filter({ has: page.getByText("2", { exact: true }) }).click();
  await button("Revisar version").click(); await page.getByText(/Coincide con DM_DEMO_ZFER/).waitFor(); await button("Cerrar").click();
  await button("Ver reglas").click(); await page.getByText("MARM_UMREZ", { exact: true }).waitFor();
  if (process.env.DM_SCREENSHOT_PATH) { await page.screenshot({ path: process.env.DM_SCREENSHOT_PATH, fullPage: true }); }

  // This page exercises the real XML/JSON transport using an intercepted service, not the demo path.
  const live = await browser.newPage({ viewport: { width: 1600, height: 1100 } });
  live.on("pageerror", e => errors.push(e.message));
  const ui = actions(live), backend = new Demo(seed), calls = [];
  let mode = "login", failKey = "FAIL_B", concurrentKey = "RACE_A";
  await live.route("**/sap/opu/odata4/**", async route => {
    const req = route.request(), uri = decodeURIComponent(new URL(req.url()).pathname), tail = uri.split("/0001/")[1] || "";
    calls.push({ method: req.method(), tail });
    const json = (body, status = 200, headers = {}) => route.fulfill({ status, contentType: "application/json", headers, body: JSON.stringify(body) });
    if (tail === "$metadata") {
      return route.fulfill({ contentType: mode === "login" ? "text/html" : "application/xml", body: mode === "login" ? '<html><script>location="oauth/authorize"</script></html>' : contract("test.admin.v0002", mode === "wrong") });
    }
    if (mode !== "ok" && mode !== "setup") { return json({ error: { message: "Unexpected request" } }, 500); }
    const snap = await backend.load();
    if (!tail) { return json({}, 200, { "x-csrf-token": "token" }); }
    if (tail === "Configuration('GLOBAL')") { return mode === "setup" ? json({ error: { message: "Not initialized" } }, 404) : json(snap.root); }
    if (tail === "Configuration('GLOBAL')/test.admin.v0002.Aplicar") {
      const command = req.postDataJSON();
      if (command.SeccionId === failKey) { return json({ error: { message: "Fallo simulado sin confirmar el registro" } }, 500); }
      try {
        await backend.apply(command, { "@odata.etag": req.headers()["if-match"] });
        if (command.SeccionId === concurrentKey) {
          const current = await backend.load();
          await backend.apply(Schema.command("Secciones", { SeccionId: "EXTERNAL", Descripcion: "Otro administrador", Orden: 5, Activo: true }, "CREAR"), current.root);
        }
        return json((await backend.load()).root);
      } catch (error) { return json({ error: { message: error.message } }, 400); }
    }
    if (Schema.sets.includes(tail)) { return json({ value: snap.state[tail] }); }
    return json({ error: { message: "Ruta no esperada: " + tail } }, 404);
  });
  await live.goto(url); await live.getByText(/SAP solicita iniciar sesion/).waitFor();
  assert.equal(await ui.button("Nuevo").isEnabled(), false);
  assert.equal(calls.filter(c => c.tail !== "$metadata").length, 0);
  mode = "wrong"; await ui.button("Actualizar").click();
  await live.getByText(/Este servicio no es el mantenimiento esperado/).waitFor();
  assert.equal(await ui.button("Nuevo").isEnabled(), false);
  mode = "setup"; await ui.button("Actualizar").click();
  await live.getByText(/GLOBAL no esta disponible/).waitFor();
  await live.getByText(/Esta version de prueba no requiere una lista de administradores/).waitFor();
  assert.equal(await ui.button("Nuevo").isEnabled(), false);
  mode = "ok"; await ui.button("Actualizar").click(); await live.getByText("MAKT_MAKTX", { exact: true }).waitFor();
  await live.getByText("Conectado a SAP", { exact: true }).waitFor();
  await live.getByText(/el rol especifico de administrador DM aun no se aplica/).waitFor();
  await ui.tab("Secciones"); await ui.button("Importar CSV").click();
  await ui.dialog().getByPlaceholder(/CSV UTF-8/).fill('SeccionId;Descripcion;Orden;Activo\nOK_A;Confirmado;1;true\nFAIL_B;Pendiente;2;true');
  await ui.button("Validar archivo").click(); await live.getByText(/2 registros; 0 con errores/).waitFor();
  await ui.button("Importar registros").click(); await ui.dialog().waitFor({ state: "hidden" });
  await live.getByText(/Carga detenida: 1 registros confirmados/).waitFor();
  assert.equal(await ui.button("Nuevo").isEnabled(), false);
  let snap = await backend.load();
  assert.ok(snap.state.Secciones.some(s => s.SeccionId === "OK_A")); assert.ok(!snap.state.Secciones.some(s => s.SeccionId === "FAIL_B"));
  await ui.button("Actualizar").click(); await live.getByText("Conectado a SAP", { exact: true }).waitFor();
  await ui.button("Importar CSV").click();
  await ui.dialog().getByPlaceholder(/CSV UTF-8/).fill('SeccionId;Descripcion;Orden;Activo\nRACE_A;Propio;1;true\nRACE_B;No enviar;2;true');
  await ui.button("Validar archivo").click(); await live.getByText(/2 registros; 0 con errores/).waitFor();
  await ui.button("Importar registros").click(); await ui.dialog().waitFor({ state: "hidden" });
  await live.getByText(/Otro administrador cambio la configuracion durante la carga/).waitFor();
  snap = await backend.load();
  assert.ok(snap.state.Secciones.some(s => s.SeccionId === "EXTERNAL")); assert.ok(!snap.state.Secciones.some(s => s.SeccionId === "RACE_B"));
  assert.equal(calls.filter(c => c.method === "POST").length, 3, "no request may silently use a new administrator revision");
  assert.deepEqual(errors, []);
});
