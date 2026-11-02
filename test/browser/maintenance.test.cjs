const { test } = require("node:test");
const assert = require("node:assert/strict");
const { spawn } = require("node:child_process");
const { chromium } = require("playwright");
const path = require("node:path");

test("browser: maintain six catalogs, publish a new flow and edit rules on a copied version", { timeout: 180000 }, async t => {
  const base = path.resolve(__dirname, "../..");
  const server = spawn(process.execPath, [path.join(base, "node_modules/@ui5/cli/bin/ui5.cjs"), "serve", "--config", "ui5-demo.yaml", "--port", "8083"], { cwd: base, env: process.env, stdio: ["ignore", "pipe", "pipe"] });
  let logs = "";
  server.stdout.on("data", d => { logs += d; }); server.stderr.on("data", d => { logs += d; });
  t.after(() => server.kill());
  await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => { clearInterval(poll); reject(new Error(logs)); }, 45000);
    const poll = setInterval(() => { if (logs.includes("Server started")) { clearInterval(poll); clearTimeout(timeout); resolve(); } }, 100);
    server.once("exit", code => { clearInterval(poll); clearTimeout(timeout); reject(new Error("Server exit " + code + ": " + logs)); });
  });
  const browser = await chromium.launch({ executablePath: process.env.DM_CHROMIUM_PATH || undefined });
  t.after(() => browser.close());
  const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
  const errors = [], sapCalls = [];
  page.on("pageerror", e => errors.push(e.message));
  page.on("console", m => { if (m.type() === "error") { errors.push(m.text()); } });
  page.on("request", r => { if (new URL(r.url()).pathname.startsWith("/sap/")) { sapCalls.push(r.url()); } });
  const button = name => {
    const locator = page.getByRole("button", { name, exact: true }), click = locator.click.bind(locator);
    locator.click = async (...args) => {
      if (!await locator.isVisible()) { await page.locator(".sapMOTBOverflowButton:visible").last().click(); }
      return click(...args);
    };
    return locator;
  };
  const dialog = () => page.locator(".sapMDialog");
  const tab = name => page.getByRole("tab", { name: new RegExp(name) }).click();
  const input = (label, value) => dialog().getByLabel(label, { exact: true }).fill(value);
  async function choose(label, text) {
    const control = dialog().getByLabel(label, { exact: true });
    await control.locator('xpath=ancestor-or-self::*[contains(concat(" ", normalize-space(@class), " "), " sapMSlt ")][1]').click();
    await page.getByRole("option", { name: text, exact: true }).click();
  }
  async function save(set, operation = "CREAR") {
    await button("Guardar").click(); await dialog().waitFor({ state: "hidden" });
    await page.getByText(new RegExp(operation + " completado en " + set)).waitFor();
  }
  await page.goto("http://localhost:8083/index.html?mode=demo");
  await page.getByText("MAKT_MAKTX", { exact: true }).waitFor();
  await page.getByText("MAKT_MAKTX", { exact: true }).click();
  assert.equal(await button("Editar").isEnabled(), false, "published fields must be protected");

  console.log("Creating field, section and flow");
  await button("Nuevo").click();
  await input("Identificador del campo", "TEST_FIELD"); await input("Descripcion", "Campo de prueba");
  await input("Tabla SAP", "MARA"); await input("Campo SAP", "ZZ_TEST");
  await save("Campos");
  await tab("Secciones"); await button("Nuevo").click();
  await input("Identificador de seccion", "TEST_SEC"); await input("Descripcion", "Seccion de prueba"); await save("Secciones");
  await tab("Flujos"); await button("Nuevo").click();
  await input("Identificador del flujo", "TEST_FLOW"); await input("Descripcion", "Flujo de prueba"); await input("Tipo de material", "ZROH"); await save("Flujos");

  console.log("Creating draft, step and rule");
  await tab("Versiones"); await button("Nuevo").click();
  await choose("Flujo", "TEST_FLOW · Flujo de prueba"); await save("Versiones");
  await tab("Pasos"); await button("Nuevo").click();
  await choose("Flujo", "TEST_FLOW · Flujo de prueba"); await choose("Version", "Version 1 · BORRADOR");
  await input("Identificador del paso", "PCP_TEST"); await input("Area", "PCP"); await save("Pasos");
  await tab("Reglas"); await button("Nuevo").click();
  await choose("Flujo", "TEST_FLOW · Flujo de prueba"); await choose("Version", "Version 1 · BORRADOR");
  await choose("Area", "PCP"); await choose("Campo", "TEST_FIELD · Campo de prueba");
  await choose("Seccion", "TEST_SEC · Seccion de prueba"); await choose("Estado del campo", "M · Obligatorio"); await save("Reglas");
  await tab("Versiones");
  await page.getByRole("row").filter({ has: page.getByText("TEST_FLOW", { exact: true }) }).click();
  await button("Publicar").click(); await button("OK").click();
  await page.getByText(/PUBLICAR completado en Versiones/).waitFor();
  assert.equal(await button("Editar").isEnabled(), false);

  console.log("Copying the demo and changing an optional unit rule");
  await page.getByRole("row").filter({ has: page.getByText("DM_DEMO_ZFER", { exact: true }) }).click();
  await button("Copiar version").click(); await save("Versiones", "COPIAR");
  await tab("Reglas");
  await page.getByPlaceholder("Version", { exact: true }).fill("2"); await page.getByPlaceholder("Version", { exact: true }).press("Tab");
  await page.getByText("MARM_UMREZ", { exact: true }).click(); await button("Editar").click();
  await choose("Estado del campo", "O · Opcional"); await save("Reglas", "GUARDAR");
  await page.getByRole("row").filter({ has: page.getByText("MARM_UMREZ", { exact: true }) }).getByText("O", { exact: true }).waitFor();
  if (process.env.DM_SCREENSHOT_PATH) { await page.screenshot({ path: process.env.DM_SCREENSHOT_PATH, fullPage: true }); }

  console.log("Checking phone rendering and isolated demo data");
  await page.setViewportSize({ width: 390, height: 844 });
  const size = await page.evaluate(() => ({ w: document.documentElement.clientWidth, s: document.documentElement.scrollWidth }));
  assert.ok(size.s <= size.w + 1, "phone must not overflow horizontally");
  assert.deepEqual(sapCalls, []); assert.deepEqual(errors, []);
});
