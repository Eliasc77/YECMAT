sap.ui.define(["sap/ui/core/UIComponent", "sap/ui/model/json/JSONModel", "./model/ConfigService", "./model/DemoService", "./model/Schema"], function (UIComponent, JSONModel, ConfigService, DemoService, Schema) {
  "use strict";
  return UIComponent.extend("com.yecmat.dm.admin.Component", {
    metadata: { manifest: "json" },
    init: function () {
      var demo = new URLSearchParams(window.location.search).get("mode") === "demo", state = {};
      Schema.sets.forEach(function (set) { state[set] = []; });
      this.service = demo ? new DemoService() : new ConfigService(this.getManifestEntry("sap.app").dataSources.mainService.uri);
      this.setModel(new JSONModel({ demo: demo, busy: false, error: "", status: "", set: "Campos", title: "Campos", hint: "", root: null,
        state: state, rows: [], selected: null, canEdit: false, canCopy: false, canPublish: false, canRetire: false, flow: "", version: "", search: "", count: 0 }), "vm");
      UIComponent.prototype.init.apply(this, arguments);
    }
  });
});
