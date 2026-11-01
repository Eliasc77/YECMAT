sap.ui.define(["./Transport", "./Schema"], function (Transport, Schema) {
  "use strict";
  function ConfigService(root, fetcher) { this.transport = new Transport(root, fetcher); }
  ConfigService.prototype.load = async function (retry) {
    var first = await this.transport.request("Configuration('GLOBAL')");
    if (!first || !first["@odata.etag"]) { throw new Error("Administracion sin revision disponible. Activa el servicio y ejecuta YCL_DM_CFG_SETUP con tu usuario administrador."); }
    var rows = await Promise.all(Schema.sets.map(function (set) { return this.transport.list(set); }, this));
    var last = await this.transport.request("Configuration('GLOBAL')");
    if (first["@odata.etag"] !== last["@odata.etag"]) {
      if (!retry) { return this.load(true); }
      throw new Error("La configuracion esta cambiando. Espera y pulsa Actualizar.");
    }
    var state = {};
    Schema.sets.forEach(function (set, index) { state[set] = rows[index]; });
    return { root: last, state: state };
  };
  ConfigService.prototype.apply = async function (command, root) {
    if (!root || !root["@odata.etag"]) { throw new Error("Actualiza la configuracion antes de guardar"); }
    return this.transport.request("Configuration('GLOBAL')/com.sap.gateway.srvd.yui_dm_cfg_o4.v0001.Aplicar", "POST", command, root["@odata.etag"]);
  };
  return ConfigService;
});
