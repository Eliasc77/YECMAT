sap.ui.define(["sap/ui/core/UIComponent", "sap/ui/model/json/JSONModel", "./model/Service", "./model/DemoService"],
  function (UIComponent, JSONModel, Service, DemoService) {
    "use strict";
    return UIComponent.extend("com.yecmat.dm.Component", {
      metadata: { manifest: "json" },
      init: function () {
        var demo = new URLSearchParams(window.location.search).get("mode") === "demo";
        this.service = demo ? new DemoService() : new Service(this.getManifestEntry("sap.app").dataSources.mainService.uri);
        this.setModel(new JSONModel({ demo: demo, busy: false, requests: [], tasks: [], segments: [],
          request: null, task: null, segment: null, dirty: false, canEdit: false, canContext: false,
          error: "", status: "", search: "" }), "vm");
        UIComponent.prototype.init.apply(this, arguments);
      }
    });
  });
