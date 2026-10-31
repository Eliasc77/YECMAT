const { test } = require("node:test");
const assert = require("node:assert/strict");
const { spawn } = require("node:child_process");
const { chromium } = require("playwright");
const path = require("node:path");

test("browser: request creation and complete demo capture across PCP, LOG and CONT", { timeout: 120000 }, async t => {
  const project = path.resolve(__dirname, "../..");
  const server = spawn(process.execPath, [path.join(project, "node_modules/@ui5/cli/bin/ui5.cjs"), "serve", "--config", "ui5-demo.yaml", "--port", "8082"], { cwd: project, env: process.env, stdio: ["ignore", "pipe", "pipe"] });
  let logs = "";
  server.stdout.on("data", data => { logs += data; });
  server.stderr.on("data", data => { logs += data; });
  t.after(() => { server.kill(); });
  await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => { clearInterval(poll); reject(new Error("Server startup failed: " + logs)); }, 45000);
    const poll = setInterval(() => { if (logs.includes("Server started")) { clearInterval(poll); clearTimeout(timeout); resolve(); } }, 100);
    server.once("exit", code => { clearInterval(poll); clearTimeout(timeout); reject(new Error("Server exit " + code + ": " + logs)); });
  });
  const browser = await chromium.launch({ executablePath: process.env.DM_CHROMIUM_PATH || undefined, headless: true });
  t.after(() => browser.close());
  const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
  const errors = [], sapCalls = [];
  page.on("pageerror", error => errors.push(error.message));
  page.on("console", message => { if (message.type() === "error") { errors.push(message.text()); } });
  page.on("request", request => { if (new URL(request.url()).pathname.startsWith("/sap/")) { sapCalls.push(request.url()); } });
  const button = name => page.getByRole("button", { name, exact: true });
  const dialog = () => page.locator(".sapMDialog");
  const waitAction = name => page.getByText("Accion " + name + " completada", { exact: true }).waitFor();
  async function addContext(type, values = {}) {
    console.log("Context:", type);
    await button("Agregar contexto").click();
    await dialog().locator(".sapMSlt").click();
    await page.getByRole("option", { name: type, exact: true }).click();
    // Context labels are followed by inputs; these inputs use SAPUI5 generated IDs.
    const inputs = dialog().locator("input.sapMInputBaseInner");
    let index = 0;
    for (const value of Object.values(values)) { await inputs.nth(index++).fill(value); }
    await button("Continuar").click();
    await dialog().waitFor({ state: "hidden" });
  }
  async function save(values) {
    console.log("Save:", Object.keys(values).join(", "));
    for (const [label, value] of Object.entries(values)) { await page.getByLabel(label, { exact: true }).fill(value); }
    await button("Guardar valores").click();
    await page.getByText(Object.keys(values).length + " valor(es) guardado(s). Finaliza la tarea cuando completes todos sus contextos.", { exact: true }).waitFor();
  }
  async function finish() { await button("Finalizar tarea").click(); await button("OK").click(); await waitAction("Finalizar"); }

  await page.goto("http://localhost:8082/index.html?mode=demo");
  await page.getByText("DEMO-001", { exact: true }).click();
  await page.getByText("PCP", { exact: true }).click();
  await addContext("General");
  await page.getByLabel("Descripcion del material", { exact: true }).fill("Material de prueba");
  await page.getByText("LOG", { exact: true }).click();
  await page.getByText("Guarda los valores antes de cambiar de seleccion o ejecutar acciones. Para descartar, usa Actualizar.", { exact: true }).waitFor();
  await button("OK").click();
  await save({ "Descripcion del material": "Material de prueba", "Unidad base": "UN", "Grupo de articulos": "001" });
  await addContext("Unidad alternativa", { UnidadAlternativa: "BOX" });
  await save({ "Numerador de conversion": "10", "Denominador de conversion": "1" });
  await finish();
  assert.equal(await button("Guardar valores").isEnabled(), false);

  await page.getByText("LOG", { exact: true }).click();
  await button("Iniciar tarea").click(); await waitAction("Iniciar");
  await addContext("Centro", { Centro: "1000" });
  await save({ "Grupo de compras": "001" }); await finish();

  await page.getByText("CONT", { exact: true }).click();
  await addContext("Valoracion", { AreaValoracion: "1000", TipoValoracion: "" });
  await save({ "Precio estandar": "123.45" }); await finish();
  await button("Cerrar captura").click(); await button("OK").click(); await waitAction("Cerrar");
  await page.getByText("LISTA_INTEG", { exact: true }).first().waitFor();

  await button("Nueva solicitud").click();
  await dialog().locator("input.sapMInputBaseInner").nth(0).fill("TEST-002");
  await button("Continuar").click(); await dialog().waitFor({ state: "hidden" });
  await page.getByText("TEST-002", { exact: true }).first().waitFor();
  await button("Iniciar flujo").click();
  await button("Continuar").click(); await dialog().waitFor({ state: "hidden" }); await waitAction("Iniciar");
  await page.getByText("PCP", { exact: true }).waitFor();

  // Phone rendering must retain the main navigation without horizontal overflow.
  await page.setViewportSize({ width: 390, height: 844 });
  const sizes = await page.evaluate(() => ({ client: document.documentElement.clientWidth, scroll: document.documentElement.scrollWidth }));
  assert.ok(sizes.scroll <= sizes.client + 1, "phone viewport must not overflow");
  assert.deepEqual(sapCalls, [], "demo must never call SAP");
  assert.deepEqual(errors, [], "browser must not report runtime errors");
});
