sap.ui.define([
  "sap/ui/core/mvc/Controller", "sap/m/MessageBox", "sap/m/MessageToast", "sap/m/Dialog", "sap/m/Button",
  "sap/m/VBox", "sap/m/Label", "sap/m/Input", "sap/m/Select", "sap/ui/core/Item", "sap/ui/layout/form/SimpleForm",
  "sap/ui/core/Title", "sap/m/Text", "sap/m/TextArea", "sap/m/DatePicker", "sap/m/CheckBox",
  "sap/ui/model/Filter", "sap/ui/model/FilterOperator", "../model/Rules"
], function (Controller, MessageBox, MessageToast, Dialog, Button, VBox, Label, Input, Select, Item, SimpleForm,
  Title, Text, TextArea, DatePicker, CheckBox, Filter, FilterOperator, Rules) {
  "use strict";
  return Controller.extend("com.yecmat.dm.controller.Main", {
    onInit: function () {
      this.vm = this.getOwnerComponent().getModel("vm");
      this.api = this.getOwnerComponent().service;
      this.inputs = []; this.allSegments = [];
      this.beforeUnload = function (event) { if (this.vm.getProperty("/dirty")) { event.preventDefault(); event.returnValue = ""; } }.bind(this);
      window.addEventListener("beforeunload", this.beforeUnload);
      this.run(this.loadRequests.bind(this));
    },
    onExit: function () { window.removeEventListener("beforeunload", this.beforeUnload); },
    run: async function (work) {
      if (this.vm.getProperty("/busy")) { return; }
      this.vm.setProperty("/busy", true); this.vm.setProperty("/error", "");
      try { await work(); } catch (e) { this.vm.setProperty("/error", e.message); }
      finally { this.vm.setProperty("/busy", false); }
    },
    clean: function () {
      if (this.vm.getProperty("/dirty")) { MessageBox.information("Guarda los valores antes de cambiar de seleccion o ejecutar acciones. Para descartar, usa Actualizar."); return false; }
      return true;
    },
    confirm: function (message) {
      return new Promise(function (resolve) { MessageBox.confirm(message, { actions: [MessageBox.Action.OK, MessageBox.Action.CANCEL], onClose: function (action) { resolve(action === MessageBox.Action.OK); } }); });
    },
    clearCapture: function () {
      this.vm.setProperty("/segment", null); this.vm.setProperty("/dirty", false);
      this.inputs = []; this.byId("dynamicForms").destroyItems(); this.byId("segments").removeSelections(true);
    },
    loadRequests: async function () {
      this.vm.setProperty("/requests", await this.api.requests());
    },
    reloadRequest: async function (id, taskId, segmentId) {
      await this.loadRequests();
      var row = this.vm.getProperty("/requests").find(function (r) { return r.SolicitudUUID === id; });
      if (!row) { this.vm.setProperty("/request", null); this.vm.setProperty("/task", null); this.clearCapture(); return; }
      await this.openRequest(row);
      if (taskId) {
        var task = this.vm.getProperty("/tasks").find(function (t) { return t.TareaUUID === taskId; });
        if (task) { await this.openTask(task); }
      }
      if (segmentId && this.vm.getProperty("/task")) {
        var segment = this.vm.getProperty("/segments").find(function (s) { return s.SegmentoUUID === segmentId; });
        if (segment) { await this.openSegment(segment); }
      }
      this.selectRow("requests", "SolicitudUUID", id);
      this.selectRow("tasks", "TareaUUID", taskId);
      this.selectRow("segments", "SegmentoUUID", segmentId);
    },
    selectRow: function (controlId, key, value) {
      var list = this.byId(controlId);
      list.removeSelections(true);
      list.getItems().forEach(function (item) { if (item.getBindingContext("vm").getProperty(key) === value) { list.setSelectedItem(item, true); } });
    },
    onRefresh: async function () {
      if (this.vm.getProperty("/dirty") && !await this.confirm("Se descartaran los valores sin guardar. ¿Continuar?")) { return; }
      this.vm.setProperty("/dirty", false);
      var request = this.vm.getProperty("/request"), task = this.vm.getProperty("/task"), segment = this.vm.getProperty("/segment");
      this.run(async function () {
        if (request) { await this.reloadRequest(request.SolicitudUUID, task && task.TareaUUID, segment && segment.SegmentoUUID); }
        else { await this.loadRequests(); }
        this.vm.setProperty("/status", "Datos actualizados");
      }.bind(this));
    },
    onClearError: function () { this.vm.setProperty("/error", ""); },
    onSearch: function (event) {
      var value = event.getParameter("newValue");
      this.byId("requests").getBinding("items").filter(value ? [new Filter({ filters: [
        new Filter("NumeroSolicitud", FilterOperator.Contains, value), new Filter("Material", FilterOperator.Contains, value)
      ], and: false })] : []);
    },
    onRequestSelect: function (event) {
      var row = event.getParameter("listItem").getBindingContext("vm").getObject();
      if (!this.clean()) { this.selectRow("requests", "SolicitudUUID", this.vm.getProperty("/request/SolicitudUUID")); return; }
      this.run(this.openRequest.bind(this, row));
    },
    openRequest: async function (row) {
      this.clearCapture(); this.vm.setProperty("/task", null); this.vm.setProperty("/segments", []);
      this.vm.setProperty("/request", row); this.vm.setProperty("/tasks", []); this.vm.setProperty("/status", "");
      this.byId("tasks").removeSelections(true);
      var result = await Promise.all([this.api.tasks(row.SolicitudUUID), this.api.segments(row.SolicitudUUID)]);
      this.vm.setProperty("/tasks", result[0]); this.allSegments = result[1];
    },
    onTaskSelect: function (event) {
      var row = event.getParameter("listItem").getBindingContext("vm").getObject();
      if (!this.clean()) { this.selectRow("tasks", "TareaUUID", this.vm.getProperty("/task/TareaUUID")); return; }
      this.run(this.openTask.bind(this, row));
    },
    openTask: async function (row) {
      this.clearCapture(); this.vm.setProperty("/task", row); this.vm.setProperty("/segments", []);
      var request = this.vm.getProperty("/request");
      this.vm.setProperty("/canEdit", request.Estado === "EN_CURSO" && ["PENDIENTE", "EN_CURSO"].includes(row.Estado));
      this.vm.setProperty("/canContext", ["BORRADOR", "EN_CURSO"].includes(request.Estado) && ["PENDIENTE", "EN_CURSO"].includes(row.Estado));
      this.config = await this.api.configuration(request, row.Area);
      var types = new Set(this.config.fields.filter(function (f) {
        return f.Activo && this.config.rules.some(function (r) { return r.Activo && r.EstadoCampo !== "I" && r.CampoId === f.CampoId; });
      }, this).map(function (f) { return f.TipoSegmento; }));
      this.types = Array.from(types).filter(function (type) { return Rules.contexts[type]; });
      this.vm.setProperty("/segments", this.allSegments.filter(function (s) { return types.has(s.TipoSegmento); }).map(function (s) { return Object.assign({}, s, { _label: Rules.label(s) }); }));
      if (!this.types.length) { this.vm.setProperty("/status", "No hay reglas activas visibles para esta area. Revisa Campos, Secciones y Reglas."); }
    },
    onSegmentSelect: function (event) {
      var row = event.getParameter("listItem").getBindingContext("vm").getObject();
      if (!this.clean()) { this.selectRow("segments", "SegmentoUUID", this.vm.getProperty("/segment/SegmentoUUID")); return; }
      this.run(this.openSegment.bind(this, row));
    },
    openSegment: async function (row) {
      this.clearCapture();
      var values = await this.api.values(row.SegmentoUUID);
      this.vm.setProperty("/segment", row); this.renderFields(values);
      this.selectRow("segments", "SegmentoUUID", row.SegmentoUUID);
    },
    renderFields: function (values) {
      var container = this.byId("dynamicForms"), byField = new Map(values.map(function (v) { return [v.CampoId, v]; }));
      var segment = this.vm.getProperty("/segment"), groups = Rules.groups(this.config, segment.TipoSegmento);
      container.destroyItems(); this.inputs = [];
      groups.forEach(function (group) {
        var form = new SimpleForm({ editable: true, layout: "ResponsiveGridLayout", labelSpanXL: 4, labelSpanL: 4, labelSpanM: 4, emptySpanXL: 0, emptySpanL: 0, columnsL: 1, columnsM: 1 }).addStyleClass("dmForm");
        form.addContent(new Title({ text: group.title }));
        group.fields.forEach(function (field) {
          var existing = byField.get(field.CampoId), value = existing ? existing.Valor : "";
          var editable = this.vm.getProperty("/canEdit") && field.editable && (!existing || !existing.__EntityControl || existing.__EntityControl.Updatable !== false);
          var input, read, write;
          var change = function () { this.vm.setProperty("/dirty", this.inputs.some(function (i) { return i.read() !== i.original; })); }.bind(this);
          if (field.TipoDato === "BOOL") {
            input = new CheckBox({ selected: value === "X", enabled: editable, select: change });
            read = function () { return input.getSelected() ? "X" : ""; };
          } else if (field.TipoDato === "DATS") {
            input = new DatePicker({ value: value, valueFormat: "yyyyMMdd", displayFormat: "dd/MM/yyyy", editable: editable, change: change, width: "100%" });
            read = function () { return input.getValue(); };
          } else if (field.TipoControl === "TextArea" || field.TipoDato === "STRING" && field.Longitud > 100) {
            input = new TextArea({ value: value, valueLiveUpdate: true, maxLength: Math.min(1333, field.Longitud), rows: 3, editable: editable, liveChange: change, width: "100%" });
            read = function () { return input.getValue(); };
          } else {
            input = new Input({ value: value, valueLiveUpdate: true, maxLength: /^(DEC|CURR|QUAN|INT1|INT2|INT4)$/.test(field.TipoDato) ? 1333 : Math.min(1333, field.Longitud), editable: editable, liveChange: change, width: "100%" });
            // Keep numeric strings intact: no JS floating point conversion or locale formatting.
            read = function () { return input.getValue(); };
          }
          write = function (state, message) {
            if (input.setValueState) { input.setValueState(state); }
            if (input.setValueStateText) { input.setValueStateText(message || ""); }
          };
          form.addContent(new Label({ text: field.Descripcion || field.CampoId, required: field.required, labelFor: input }));
          var help = "Maximo " + field.Longitud + " caracteres";
          if (/^(INT1|INT2|INT4|NUMC)$/.test(field.TipoDato)) { help = "Hasta " + field.Longitud + " digitos"; }
          if (/^(DEC|CURR|QUAN)$/.test(field.TipoDato)) { help = "Hasta " + field.Longitud + " digitos, " + field.Decimales + " decimales · Usa punto decimal"; }
          if (field.TipoDato === "DATS") { help = "Selecciona una fecha"; }
          if (field.TipoDato === "BOOL") { help = "Marca la casilla para indicar Si"; }
          if (/^(UNIT|CUKY|LANG)$/.test(field.TipoDato)) { help += " · Usa la clave interna SAP en mayusculas"; }
          if (field.AyudaValores) { help += " · Ayuda " + field.AyudaValores + ": introduce la clave SAP"; }
          input.setTooltip(help);
          form.addContent(new VBox({ items: [input, new Text({ text: help }).addStyleClass("dmFieldHelp")] }));
          this.inputs.push({ field: field, control: input, read: read, state: write, existing: existing, original: value, editable: editable });
        }, this);
        container.addItem(form);
      }, this);
      if (!groups.length) { container.addItem(new Text({ text: "No hay campos configurados para este contexto y area." })); }
    },
    onSave: function () { this.run(this.save.bind(this)); },
    save: async function () {
      if (!this.vm.getProperty("/canEdit")) { throw new Error("La tarea no admite captura"); }
      var changed = this.inputs.filter(function (i) { return i.editable && i.read() !== i.original; });
      var invalid = changed.filter(function (i) { var message = Rules.validate(i.field, i.read(), false); i.state(message ? "Error" : "None", message); return !!message; });
      if (invalid.length) { throw new Error("Corrige los campos marcados antes de guardar"); }
      var saved = 0, segmentId = this.vm.getProperty("/segment/SegmentoUUID");
      try {
        // Each value is committed separately. Finalizar/Cerrar run only after a complete save.
        for (var input of changed) {
          var value = input.read();
          var result;
          try { result = await this.api.saveValue(segmentId, input.field.CampoId, value, input.existing); }
          catch (error) {
            if (error.committed) { input.original = value; input.existing = { Valor: value }; saved++; }
            throw error;
          }
          input.original = value; input.existing = result; saved++;
        }
        this.vm.setProperty("/dirty", false);
        this.vm.setProperty("/status", saved + " valor(es) guardado(s). Finaliza la tarea cuando completes todos sus contextos.");
        MessageToast.show("Valores guardados");
      } catch (e) {
        this.vm.setProperty("/dirty", this.inputs.some(function (i) { return i.read() !== i.original; }));
        throw new Error(saved + " valor(es) confirmado(s). Los restantes siguen pendientes. " + e.message);
      }
    },
    dialog: function (title, controls, submit) {
      var dialog = new Dialog({ title: title, contentWidth: "34rem", stretchOnPhone: true,
        content: [new VBox({ items: controls }).addStyleClass("sapUiMediumMargin")],
        beginButton: new Button({ text: "Continuar", type: "Emphasized", press: async function () {
          dialog.setBusy(true);
          try { await submit(); dialog.close(); }
          catch (e) { MessageBox.error(e.message); }
          finally { dialog.setBusy(false); }
        } }),
        endButton: new Button({ text: "Cancelar", press: function () { dialog.close(); } }), afterClose: function () { dialog.destroy(); }
      });
      this.getView().addDependent(dialog); dialog.open(); return dialog;
    },
    onCreateRequest: function () {
      if (!this.clean()) { return; }
      this.run(async function () {
        var flows = await this.api.flows();
        if (!flows.length) { throw new Error("No hay flujos activos. Ejecuta primero la carga de configuracion."); }
        var number = new Input({ maxLength: 20 }), material = new Input({ maxLength: 40 });
        var type = new Input({ maxLength: 4 }), operation = new Select({ selectedKey: "C", items: [new Item({ key: "C", text: "C · Crear" }), new Item({ key: "M", text: "M · Modificar" }), new Item({ key: "I", text: "I · Inactivar" })] });
        var version = new Select({ width: "100%" }), flow = new Select({ width: "100%", selectedKey: flows[0].FlujoId, items: flows.map(function (f) { return new Item({ key: f.FlujoId, text: f.FlujoId + " · " + f.Descripcion }); }) });
        var loading = false, generation = 0;
        var loadVersions = async function () {
          var selected = flow.getSelectedKey(), token = ++generation;
          loading = true; version.destroyItems();
          var metadata = flows.find(function (f) { return f.FlujoId === selected; });
          type.setValue(metadata.TipoMaterial || ""); operation.setSelectedKey(metadata.TipoOperacion || "C");
          try {
            var versions = await this.api.versions(selected);
            if (token !== generation) { return; }
            var today = new Date().toISOString().slice(0, 10);
            versions.filter(function (v) { return v.VigenteDesde <= today && v.VigenteHasta >= today; }).forEach(function (v) { version.addItem(new Item({ key: String(v.Version), text: "Version " + v.Version })); });
            if (version.getItems().length) { version.setSelectedKey(version.getItems()[0].getKey()); }
          } finally { if (token === generation) { loading = false; } }
        }.bind(this);
        flow.attachChange(function () { loadVersions().catch(function (e) { MessageBox.error(e.message); }); });
        await loadVersions();
        this.dialog("Nueva solicitud", [new Label({ text: "Numero de solicitud", required: true }), number,
          new Label({ text: "Flujo", required: true }), flow, new Label({ text: "Version publicada y vigente", required: true }), version,
          new Label({ text: "Tipo de material", required: true }), type, new Label({ text: "Operacion", required: true }), operation,
          new Label({ text: "Material (obligatorio para M / I)" }), material], async function () {
          if (loading || !number.getValue().trim() || !type.getValue().trim() || !version.getSelectedKey()) { throw new Error("Completa los campos obligatorios y elige una version vigente"); }
          if (operation.getSelectedKey() !== "C" && !material.getValue().trim()) { throw new Error("Indica el material para esta operacion"); }
          var row = await this.api.createRequest({ NumeroSolicitud: number.getValue().trim(), FlujoId: flow.getSelectedKey(), Version: Number(version.getSelectedKey()), TipoMaterial: type.getValue().trim().toUpperCase(), TipoOperacion: operation.getSelectedKey(), Material: material.getValue().trim() });
          await this.reloadRequest(row.SolicitudUUID);
          MessageToast.show("Solicitud creada. Ya puedes iniciar el flujo.");
        }.bind(this));
      }.bind(this));
    },
    onCreateSegment: function () {
      if (!this.clean() || !this.vm.getProperty("/canContext")) { return; }
      if (!this.types.length) { MessageBox.information("No hay tipos de contexto configurados para esta area"); return; }
      var type = new Select({ width: "100%", selectedKey: this.types[0], items: this.types.map(function (t) { return new Item({ key: t, text: Rules.contexts[t].label }); }) });
      var fields = new VBox(), controls;
      var render = function () {
        fields.destroyItems(); controls = {};
        Rules.contexts[type.getSelectedKey()].fields.forEach(function (f) {
          var input = new Input({ maxLength: f[2], placeholder: "Clave interna SAP en mayusculas" });
          fields.addItem(new Label({ text: f[1], required: f[3], labelFor: input })); fields.addItem(input); controls[f[0]] = input;
        });
      };
      type.attachChange(render); render();
      this.dialog("Agregar contexto", [new Label({ text: "Tipo", required: true }), type, fields], async function () {
        var request = this.vm.getProperty("/request"), task = this.vm.getProperty("/task"), values = {};
        Object.keys(controls).forEach(function (key) { values[key] = controls[key].getValue(); });
        var row = await this.api.createSegment(Rules.segmentPayload(request.SolicitudUUID, type.getSelectedKey(), values));
        await this.reloadRequest(request.SolicitudUUID, task.TareaUUID, row.SegmentoUUID);
      }.bind(this));
    },
    execute: async function (set, name, parameters) {
      var request = this.vm.getProperty("/request"), task = this.vm.getProperty("/task"), segment = this.vm.getProperty("/segment");
      await this.api.action(set, set === "Solicitudes" ? request : task, name, parameters);
      await this.reloadRequest(request.SolicitudUUID, task && task.TareaUUID, segment && segment.SegmentoUUID);
      this.vm.setProperty("/status", "Accion " + name + " completada");
    },
    onStartRequest: function () {
      if (!this.clean()) { return; }
      var classification = new Select({ width: "100%", selectedKey: "A", items: [new Item({ key: "A", text: "A · Requiere revision antes de integrar" }), new Item({ key: "B", text: "B · Lista para integrar al cerrar captura" })] });
      this.dialog("Iniciar flujo", [new Label({ text: "Clasificacion BPM", required: true }), classification], this.execute.bind(this, "Solicitudes", "Iniciar", { get ClasificacionBpm() { return classification.getSelectedKey(); } }));
    },
    onStartTask: function () { if (this.clean()) { this.run(this.execute.bind(this, "Tareas", "Iniciar", {})); } },
    onFinishTask: async function () {
      if (!this.clean()) { return; }
      if (await this.confirm("Se validaran los campos obligatorios de todos los contextos del area. ¿Finalizar la tarea?")) { this.run(this.execute.bind(this, "Tareas", "Finalizar", {})); }
    },
    onCloseRequest: async function () {
      if (!this.clean()) { return; }
      if (await this.confirm("¿Cerrar la captura de la solicitud? Todas las tareas obligatorias deben estar finalizadas.")) { this.run(this.execute.bind(this, "Solicitudes", "Cerrar", {})); }
    },
    onApproveRequest: async function () {
      if (!this.clean()) { return; }
      if (await this.confirm("¿Aprobar la solicitud y dejarla lista para integracion?")) { this.run(this.execute.bind(this, "Solicitudes", "Aprobar", {})); }
    },
    onReopenTask: async function () {
      if (!this.clean()) { return; }
      var task = this.vm.getProperty("/task");
      if (task && await this.confirm("¿Reabrir la tarea de " + task.Area + "?")) { this.run(this.execute.bind(this, "Solicitudes", "Reabrir", { TareaUUID: task.TareaUUID })); }
    }
  });
});
