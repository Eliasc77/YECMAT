sap.ui.define([
  "sap/ui/core/mvc/Controller", "sap/ui/model/json/JSONModel", "sap/m/Column", "sap/m/Text", "sap/m/ColumnListItem", "sap/m/ObjectStatus",
  "sap/m/MessageBox", "sap/m/MessageToast", "sap/m/Dialog", "sap/m/Button", "sap/m/VBox", "sap/m/Label", "sap/m/Input", "sap/m/Select",
  "sap/ui/core/Item", "sap/m/DatePicker", "sap/m/CheckBox", "sap/ui/layout/form/SimpleForm", "sap/m/MessageStrip", "../model/Schema",
  "../model/Readiness", "../model/Csv", "sap/m/TextArea", "sap/ui/unified/FileUploader", "sap/m/Table"
], function (Controller, JSONModel, Column, Text, ColumnListItem, ObjectStatus, MessageBox, MessageToast, Dialog, Button, VBox, Label, Input, Select,
  Item, DatePicker, CheckBox, SimpleForm, MessageStrip, Schema, Readiness, Csv, TextArea, FileUploader, Table) {
  "use strict";
  var copy = function (data) { return JSON.parse(JSON.stringify(data)); };
  return Controller.extend("com.yecmat.dm.admin.controller.Main", {
    onInit: function () {
      this.vm = this.getOwnerComponent().getModel("vm"); this.api = this.getOwnerComponent().service;
      this.configureTable(); this.run(this.load.bind(this));
    },
    run: async function (work) {
      if (this.vm.getProperty("/busy")) { return; }
      this.vm.setProperty("/busy", true); this.vm.setProperty("/error", "");
      try { await work(); } catch (e) { this.vm.setProperty("/error", e.message); }
      finally { this.vm.setProperty("/busy", false); }
    },
    load: async function () {
      this.vm.setProperty("/ready", false); this.vm.setProperty("/connectionText", "Comprobando conexion...");
      this.vm.setProperty("/errorHelp", "");
      var data;
      try { data = await this.api.load(); }
      catch (error) {
        this.vm.setProperty("/root", null); this.vm.setProperty("/selected", null); this.vm.setProperty("/rows", []);
        this.vm.setProperty("/counts", {});
        this.vm.setProperty("/connectionText", "Conexion pendiente");
        this.vm.setProperty("/errorHelp", error.help || "Comprueba el servicio YUI_DM_CFG_O4, su binding publicado y el usuario administrador. La tabla vacia no confirma que falten datos en SAP.");
        this.selectionState(); throw error;
      }
      var counts = {};
      this.vm.setProperty("/root", data.root); this.vm.setProperty("/state", data.state);
      Schema.sets.forEach(function (set) { counts[set] = data.state[set].length; }); this.vm.setProperty("/counts", counts);
      var filter = this.byId("flowFilter"), selected = this.vm.getProperty("/flow");
      filter.destroyItems(); filter.addItem(new Item({ key: "", text: "Todos los flujos" }));
      data.state.Flujos.forEach(function (flow) { filter.addItem(new Item({ key: flow.FlujoId, text: flow.FlujoId })); });
      filter.setSelectedKey(selected);
      this.vm.setProperty("/ready", true); this.vm.setProperty("/connectionText", this.vm.getProperty("/demo") ? "Demo local" : "Conectado a SAP");
      this.updateRows();
    },
    onRefresh: function () { this.vm.setProperty("/status", ""); this.run(this.load.bind(this)); },
    onSectionSelect: function (event) {
      this.vm.setProperty("/set", event.getParameter("key")); this.vm.setProperty("/selected", null);
      this.vm.setProperty("/search", ""); this.configureTable(); this.updateRows();
    },
    configureTable: function () {
      var set = this.vm.getProperty("/set"), schema = Schema.schemas[set], table = this.byId("records");
      this.vm.setProperty("/title", schema.title); this.vm.setProperty("/hint", schema.description);
      table.unbindItems(); table.destroyColumns();
      schema.columns.forEach(function (name, index) {
        var f = schema.fields.find(function (f) { return f.name === name; });
        var label = { CampoId: "Campo", SeccionId: "Seccion", FlujoId: "Flujo", PasoId: "Paso", TipoSegmento: "Contexto", TipoDato: "Tipo", CondicionBpm: "Clasificacion" }[name] || (f ? f.label : name);
        table.addColumn(new Column({ header: new Text({ text: label }), minScreenWidth: index > 1 ? "Tablet" : "Phone", demandPopin: index > 1 }));
      });
      table.bindItems({ path: "vm>/rows", factory: function (id) {
        return new ColumnListItem(id, { cells: schema.columns.map(function (name) {
          if (name === "Activo" || name === "Obligatorio") { return new ObjectStatus({ text: { path: "vm>" + name, formatter: function (v) { return v ? "Si" : "No"; } }, state: { path: "vm>" + name, formatter: function (v) { return v ? "Success" : "None"; } } }); }
          if (name === "Estado") { return new ObjectStatus({ text: "{vm>Estado}", state: { path: "vm>Estado", formatter: function (v) { return v === "PUBLICADA" ? "Success" : v === "BORRADOR" ? "Information" : "None"; } } }); }
          return new Text({ text: "{vm>" + name + "}" });
        }) });
      } });
    },
    updateRows: function () {
      var set = this.vm.getProperty("/set"), state = this.vm.getProperty("/state"), query = this.vm.getProperty("/search").toLowerCase();
      var flow = this.vm.getProperty("/flow"), version = this.vm.getProperty("/version");
      var previous = this.vm.getProperty("/selected"), oldKey = previous && Schema.key(set, previous);
      var rows = (this.vm.getProperty("/ready") ? state[set] : []).filter(function (row) {
        return (!flow || !["Versiones", "Pasos", "Reglas"].includes(set) || row.FlujoId === flow)
          && (!version || !["Pasos", "Reglas"].includes(set) || row.Version === Number(version))
          && (!query || Object.values(row).join(" ").toLowerCase().includes(query));
      });
      this.vm.setProperty("/rows", rows);
      this.vm.setProperty("/selected", previous ? rows.find(function (row) { return Schema.key(set, row) === oldKey; }) || null : null);
      var table = this.byId("records"), selected = this.vm.getProperty("/selected");
      table.removeSelections(true);
      if (selected) {
        table.getItems().forEach(function (item) {
          if (Schema.key(set, item.getBindingContext("vm").getObject()) === Schema.key(set, selected)) { table.setSelectedItem(item, true); }
        });
      }
      this.selectionState();
    },
    onSearch: function (event) { this.vm.setProperty("/search", event.getParameter("newValue")); this.updateRows(); },
    onFlowFilter: function () { this.updateRows(); },
    onVersionFilter: function () { this.updateRows(); },
    onSelect: function (event) { this.vm.setProperty("/selected", event.getParameter("listItem").getBindingContext("vm").getObject()); this.selectionState(); },
    selectionState: function () {
      var set = this.vm.getProperty("/set"), row = this.vm.getProperty("/ready") && this.vm.getProperty("/selected"), protectedRow = Schema.protectedRow(set, row, this.vm.getProperty("/state"));
      this.vm.setProperty("/canReview", !!row && set === "Versiones");
      this.vm.setProperty("/canEdit", !!row && (!protectedRow || set === "Flujos"));
      this.vm.setProperty("/canCopy", !!row && set === "Versiones");
      this.vm.setProperty("/canPublish", !!row && set === "Versiones" && row.Estado === "BORRADOR");
      this.vm.setProperty("/canRetire", !!row && set === "Versiones" && row.Estado === "PUBLICADA");
      this.vm.setProperty("/selectionHint", protectedRow ? set === "Flujos" ? "Flujo protegido: solo puedes activar o desactivar su uso. Para cambiar criterios, crea otro flujo." : "Registro protegido. Copia la version para cambiar sus pasos o reglas; para redefinir campos o secciones usados, crea otra clave." : row ? Schema.key(set, row) : "Selecciona un registro para editarlo o gestionar su version.");
    },
    dialog: function (title, content, submit) {
      var dialog = new Dialog({ title: title, contentWidth: "40rem", stretchOnPhone: true, content: content,
        beginButton: new Button({ text: "Guardar", type: "Emphasized", press: async function () {
          dialog.setBusy(true);
          try { await submit(); dialog.close(); }
          catch (e) { if (e.committed || e.closeEditor) { dialog.close(); this.vm.setProperty("/error", e.message); } else { MessageBox.error(e.message); } }
          finally { dialog.setBusy(false); }
        }.bind(this) }),
        endButton: new Button({ text: "Cancelar", press: function () { dialog.close(); } }),
        afterClose: function () { if (this.editor === dialog) { this.editor = null; } dialog.destroy(); }.bind(this)
      }).addStyleClass("dmEdit");
      this.getView().addDependent(dialog); this.editor = dialog; dialog.open(); return dialog;
    },
    onCreate: function () { this.edit(false); },
    onEdit: function () { if (this.vm.getProperty("/canEdit")) { this.edit(true); } },
    edit: function (editing) {
      if (!this.vm.getProperty("/ready")) { return; }
      var set = this.vm.getProperty("/set"), schema = Schema.schemas[set], state = this.vm.getProperty("/state");
      var row = editing ? copy(this.vm.getProperty("/selected")) : Schema.defaults(set);
      if (!editing && this.vm.getProperty("/flow")) { row.FlujoId = this.vm.getProperty("/flow"); }
      if (!editing && this.vm.getProperty("/version")) { row.Version = Number(this.vm.getProperty("/version")); }
      var model = new JSONModel(row), controls = {}, old = editing && copy(row), root = copy(this.vm.getProperty("/root"));
      var frozen = editing && Schema.protectedRow(set, row, state);
      var form = new SimpleForm({ editable: true, layout: "ResponsiveGridLayout", labelSpanL: 4, labelSpanM: 4, emptySpanL: 0, columnsL: 1, columnsM: 1 });
      function refreshOptions(changed) {
        if (changed === "FlujoId" && set !== "Versiones") { model.setProperty("/Version", ""); model.setProperty("/Area", ""); }
        if (changed === "Version" && set === "Reglas") { model.setProperty("/Area", ""); }
        schema.fields.forEach(function (f) {
          if (!controls[f.name] || !controls[f.name].isA("sap.m.Select")) { return; }
          var options = Schema.options(set, f, model.getData(), state, editing), selected = String(model.getProperty("/" + f.name) || "");
          controls[f.name].destroyItems();
          if (f.ref || f.required) { controls[f.name].addItem(new Item({ key: "", text: "Seleccionar..." })); }
          (options || []).forEach(function (o) { controls[f.name].addItem(new Item({ key: o.key, text: o.text })); });
          controls[f.name].setSelectedKey(selected);
        });
      }
      schema.fields.forEach(function (f) {
        var disabled = editing && f.key || frozen && set === "Flujos" && f.name !== "Activo", control;
        var options = Schema.options(set, f, row, state, editing);
        if (options) {
          control = new Select({ width: "100%", enabled: !disabled, selectedKey: { path: "edit>/" + f.name, formatter: function (v) { return String(v == null ? "" : v); } }, change: function (event) {
            model.setProperty("/" + f.name, event.getSource().getSelectedKey()); refreshOptions(f.name);
          } });
        } else if (f.type === "boolean") { control = new CheckBox({ selected: "{edit>/" + f.name + "}", enabled: !disabled }); }
        else if (f.type === "date") { control = new DatePicker({ value: "{edit>/" + f.name + "}", valueFormat: "yyyy-MM-dd", displayFormat: "dd/MM/yyyy", editable: !disabled, width: "100%" }); }
        else { control = new Input({ value: "{edit>/" + f.name + "}", maxLength: f.max || 10, editable: !disabled, width: "100%", type: f.type === "integer" ? "Number" : "Text" }); }
        controls[f.name] = control;
        form.addContent(new Label({ text: f.label, labelFor: control, required: f.required })); form.addContent(control);
      });
      form.setModel(model, "edit"); refreshOptions();
      var notice = new MessageStrip({ text: frozen ? "Este flujo ya se utilizo. Solo se permite cambiar Activo." : set === "Versiones" ? "La version se guarda como borrador. Agrega pasos y reglas antes de publicarla." : "Las claves identifican el registro y no se cambian despues de crearlo.", type: "Information", showIcon: true });
      this.dialog((editing ? "Editar " : "Nuevo · ") + schema.title, [notice, form], async function () {
        var data = model.getData(), errors = Schema.validate(set, data);
        if (errors.length) { throw new Error(errors.join("\n")); }
        var id = Schema.key(set, data);
        if (!editing && state[set].some(function (r) { return Schema.key(set, r) === id; })) { throw new Error("Ya existe un registro con esa clave. Seleccionalo y usa Editar."); }
        if (editing && schema.keys.some(function (k) { return String(old[k]) !== String(data[k]); })) { throw new Error("No se pueden cambiar las claves del registro"); }
        await this.perform(Schema.command(set, data, editing ? "GUARDAR" : "CREAR"), root);
      }.bind(this));
    },
    perform: async function (command, root) {
      await this.api.apply(command, root);
      try { await this.load(); }
      catch (e) { e.committed = true; e.message = "Cambio confirmado. No se pudo actualizar la pantalla: pulsa Actualizar antes de continuar. " + e.message; throw e; }
      this.vm.setProperty("/status", command.Operation + " completado en " + command.EntitySet + ". Revision " + this.vm.getProperty("/root/Revision"));
      this.vm.setProperty("/error", ""); MessageToast.show("Configuracion guardada");
    },
    onCopy: function () {
      var row = copy(this.vm.getProperty("/selected")); if (!row) { return; }
      var maximum = Math.max.apply(null, this.vm.getProperty("/state/Versiones").filter(function (v) { return v.FlujoId === row.FlujoId; }).map(function (v) { return v.Version; }));
      var input = new Input({ value: String(maximum + 1), type: "Number" }), root = copy(this.vm.getProperty("/root"));
      this.dialog("Copiar version " + row.Version, [new VBox({ items: [new Text({ text: "Se copiaran los pasos y reglas a una version BORRADOR. La version original conserva sus datos." }), new Label({ text: "Version destino", labelFor: input, required: true }), input] })], async function () {
        var value = input.getValue();
        if (!/^\d+$/.test(value) || Number(value) < 1 || Number(value) > 2147483647) { throw new Error("Version destino positiva requerida"); }
        row.VersionDestino = Number(value); await this.perform(Schema.command("Versiones", row, "COPIAR"), root);
      }.bind(this));
    },
    confirmAction: async function (operation) {
      var row = this.vm.getProperty("/selected"); if (!row || this.vm.getProperty("/set") !== "Versiones") { return; }
      var text = operation === "PUBLICAR" ? "¿Publicar esta version? Se validaran sus referencias y vigencias; sus pasos y reglas quedaran protegidos." : "¿Retirar esta version? No podra elegirse para nuevas solicitudes. Se conservara la configuracion historica.";
      var answer = await new Promise(function (resolve) { MessageBox.confirm(text, { onClose: function (action) { resolve(action === MessageBox.Action.OK); } }); });
      if (answer) { this.run(this.perform.bind(this, Schema.command("Versiones", row, operation), copy(this.vm.getProperty("/root")))); }
    },
    onPublish: function () { this.confirmAction("PUBLICAR"); },
    onRetire: function () { this.confirmAction("RETIRAR"); },
    navigate: function (set, context) {
      this.vm.setProperty("/set", set); this.vm.setProperty("/selected", null); this.vm.setProperty("/search", "");
      if (context) { this.vm.setProperty("/flow", context.FlujoId); this.vm.setProperty("/version", String(context.Version)); }
      this.byId("sections").setSelectedKey(set); this.configureTable(); this.updateRows();
    },
    onGuideStep: function (event) { this.navigate(event.getSource().data("set")); },
    onRelated: function (event) { this.navigate(event.getSource().data("set"), this.vm.getProperty("/selected")); },
    onReview: function () {
      var row = this.vm.getProperty("/selected");
      if (!row || this.vm.getProperty("/set") !== "Versiones" || !this.vm.getProperty("/ready")) { return; }
      var report = Readiness.report(this.vm.getProperty("/state"), row);
      var box = new VBox({ items: [new MessageStrip({ text: report.ready ? "Sin pendientes detectados en esta revision. SAP volvera a validar al publicar." : "Corrige los pendientes antes de publicar. Esta revision no modifica datos.", type: report.ready ? "Success" : "Warning", showIcon: true })] });
      var review = new Dialog({ title: "Revision · " + Schema.key("Versiones", row), contentWidth: "42rem", stretchOnPhone: true, content: box,
        endButton: new Button({ text: "Cerrar", press: function () { review.close(); } }), afterClose: function () { review.destroy(); } }).addStyleClass("dmEdit");
      report.checks.forEach(function (check) {
        box.addItem(new ObjectStatus({ text: check.label, state: check.ok ? "Success" : "Error", icon: check.ok ? "sap-icon://accept" : "sap-icon://alert" }).addStyleClass("sapUiSmallMarginTop"));
        box.addItem(new Text({ text: check.detail }));
        if (!check.ok) { box.addItem(new Button({ text: "Ir a " + check.target, press: function () { review.close(); this.navigate(check.target, row); }.bind(this) })); }
      }, this);
      this.getView().addDependent(review); review.open();
    },
    download: function (name, text, type) {
      var url = URL.createObjectURL(new Blob([text], { type: type })), link = document.createElement("a");
      link.href = url; link.download = name; document.body.appendChild(link); link.click(); link.remove();
      setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
    },
    onTemplate: function () {
      var set = this.vm.getProperty("/set"), row = Schema.defaults(set);
      if (this.vm.getProperty("/flow")) { row.FlujoId = this.vm.getProperty("/flow"); }
      if (this.vm.getProperty("/version")) { row.Version = this.vm.getProperty("/version"); }
      this.download("Plantilla_" + set + ".csv", Csv.exportRows(set, [row]), "text/csv;charset=utf-8");
    },
    onExport: function () {
      var set = this.vm.getProperty("/set");
      this.download(set + ".csv", Csv.exportRows(set, this.vm.getProperty("/rows")), "text/csv;charset=utf-8");
    },
    onImport: function () {
      if (!this.vm.getProperty("/ready")) { return; }
      var set = this.vm.getProperty("/set"), snapshot = copy(this.vm.getProperty("/state")), originalRoot = copy(this.vm.getProperty("/root"));
      var input = new TextArea({ rows: 7, width: "100%", placeholder: "CSV UTF-8 separado por punto y coma; usa la plantilla de este mantenimiento", valueLiveUpdate: true });
      var updates = new CheckBox({ text: "Permitir actualizar registros existentes editables", selected: false });
      var summary = new Text({ text: "Carga o pega un CSV y pulsa Validar archivo. Aun no se guardara nada." });
      var model = new JSONModel({ rows: [] }), preview = [];
      var table = new Table({ growing: true, growingThreshold: 20, columns: [new Column({ header: new Text({ text: "Registro" }) }), new Column({ header: new Text({ text: "Clave" }) }), new Column({ header: new Text({ text: "Revision" }) })] });
      table.setModel(model, "csv"); table.bindItems({ path: "csv>/rows", template: new ColumnListItem({ cells: [new Text({ text: "{csv>line}" }), new Text({ text: "{csv>key}" }), new Text({ text: "{csv>message}" })] }) });
      var dialog;
      var invalidate = function () { preview = []; model.setProperty("/rows", []); if (dialog) { dialog.getBeginButton().setEnabled(false); } summary.setText("Pulsa Validar archivo para revisar el contenido actual."); };
      input.attachLiveChange(invalidate); updates.attachSelect(invalidate);
      var upload = new FileUploader({ buttonOnly: true, buttonText: "Elegir CSV", uploadOnChange: false, sameFilenameAllowed: true, fileType: ["csv"], change: async function (event) {
        var file = event.getParameter("files")[0]; if (!file) { return; }
        invalidate();
        if (file.size > 2 * 1024 * 1024) { MessageBox.error("El archivo supera 2 MB"); return; }
        try { var text = await file.text(); invalidate(); input.setValue(text); } catch (e) { MessageBox.error("No se pudo leer el archivo"); }
      } });
      var validate = new Button({ text: "Validar archivo", press: function () {
        invalidate();
        try {
          preview = Csv.preview(set, input.getValue(), snapshot, updates.getSelected());
          model.setProperty("/rows", preview);
          var errors = preview.filter(function (row) { return row.errors.length; }).length;
          summary.setText(preview.length + " registros; " + errors + " con errores. Usa Mas para ver los registros adicionales. " + (errors ? "Corrige el archivo antes de importar." : "Listo para importar. Cada registro se confirma por separado."));
          dialog.getBeginButton().setEnabled(errors === 0);
        } catch (error) { MessageBox.error(error.message); }
      } });
      dialog = this.dialog("Importar CSV · " + set, [new VBox({ items: [
        new MessageStrip({ text: "La carga usa las mismas validaciones y permisos que el formulario. Si falla un registro, se detiene y conserva los anteriores confirmados. Las versiones se crean como borrador.", type: "Information", showIcon: true }),
        upload, input, updates, validate, summary, table
      ] })], async function () {
        if (!preview.length || preview.some(function (row) { return row.errors.length; })) { throw new Error("Valida y corrige el archivo antes de importar"); }
        var confirmed = 0, root = originalRoot;
        this.vm.setProperty("/status", "");
        try {
          for (var entry of preview) {
            await this.api.apply(Schema.command(set, entry.row, entry.operation), root); confirmed++;
            await this.load();
            var next = copy(this.vm.getProperty("/root"));
            if (Number(next.Revision) !== Number(root.Revision) + 1) { throw new Error("Otro administrador cambio la configuracion durante la carga. Revisa los pendientes antes de continuar."); }
            root = next;
          }
          this.vm.setProperty("/status", "Importacion completada: " + confirmed + " registros confirmados en " + set);
        } catch (error) {
          this.vm.setProperty("/ready", false); this.selectionState();
          this.vm.setProperty("/connectionText", "Actualizar antes de continuar");
          error.closeEditor = true;
          error.message = "Carga detenida: " + confirmed + " registros confirmados. Actualiza y verifica los registros restantes antes de volver a importar. " + error.message;
          throw error;
        }
      }.bind(this));
      dialog.getBeginButton().setText("Importar registros"); dialog.getBeginButton().setEnabled(false);
    }
  });
});
