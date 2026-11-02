sap.ui.define(["./Transport", "./Schema", "./Metadata"], function (Transport, Schema, Metadata) {
  "use strict";
  function ConfigService(root, fetcher) { this.transport = new Transport(root, fetcher); }
  ConfigService.prototype.load = async function (retry) {
    if (!retry) { this.contract = Metadata.read(await this.transport.metadata()); }
    var first;
    try { first = await this.transport.request("Configuration('GLOBAL')"); }
    catch (error) {
      if (error.status === 404) {
        error.code = "SETUP_OR_ACCESS";
        error.message = "GLOBAL no esta visible para tu usuario. Comprueba la inicializacion y el permiso de administrador.";
        error.help = "Ejecuta YCL_DM_CFG_SETUP una sola vez con el administrador inicial. Si ya se inicializo, revisa el usuario tecnico activo en YMMT_DM_CFG_USR; no borres las tablas para repetir el alta.";
      }
      throw error;
    }
    if (!first || !first["@odata.etag"] || !Number.isInteger(first.Revision) || first.Revision < 0) { throw new Error("Administracion sin revision disponible. Activa el servicio y ejecuta YCL_DM_CFG_SETUP con tu usuario administrador."); }
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
    if (!this.contract) { this.contract = Metadata.read(await this.transport.metadata()); }
    return this.transport.request("Configuration('GLOBAL')/" + this.contract.namespace + "." + this.contract.action, "POST", command, root["@odata.etag"]);
  };
  return ConfigService;
});
