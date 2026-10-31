const fs = require("node:fs");
const vm = require("node:vm");
const path = require("node:path");
module.exports = function load(name, dependencies = {}) {
  let result;
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, "../webapp/model", name + ".js"), "utf8"), {
    sap: { ui: { define: (deps, factory) => { result = factory(...deps.map(d => dependencies[d])); } } },
    URL, URLSearchParams, fetch, crypto: globalThis.crypto, console, Set, Map, Date
  }, { filename: name + ".js" });
  return result;
};
