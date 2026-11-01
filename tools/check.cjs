const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
let count = 0;
function check(dir) {
  for (const name of fs.readdirSync(dir)) {
    const file = path.join(dir, name);
    if (fs.statSync(file).isDirectory()) { check(file); }
    else if (name.endsWith(".js")) { new vm.Script(fs.readFileSync(file, "utf8"), { filename: file }); count++; }
    else if (name.endsWith(".json")) { JSON.parse(fs.readFileSync(file, "utf8")); count++; }
  }
}
check("webapp");
console.log(count + " JavaScript/JSON files checked");
