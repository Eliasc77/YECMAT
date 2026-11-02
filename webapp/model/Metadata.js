sap.ui.define(["sap/ui/util/XMLHelper", "./Schema"], function (XMLHelper, Schema) {
  "use strict";
  var EDM = "http://docs.oasis-open.org/odata/ns/edm";
  function all(parent, name) { return Array.from(parent.getElementsByTagNameNS(EDM, name)); }
  function failure(message) { var error = new Error(message); error.code = "SERVICE_CONTRACT"; return error; }
  function read(text) {
    var doc = XMLHelper.parse(text);
    if (!doc || doc.getElementsByTagName("parsererror").length || !all(doc, "Schema").length) {
      throw failure("El endpoint no devuelve metadata OData valida. Revisa la ruta y la publicacion del servicio de mantenimiento.");
    }
    var sets = all(doc, "EntitySet");
    var aliases = {};
    all(doc, "Schema").forEach(function (schema) { if (schema.getAttribute("Alias")) { aliases[schema.getAttribute("Alias")] = schema.getAttribute("Namespace"); } });
    function qualified(name) { var pieces = name.split("."); return aliases[pieces[0]] ? aliases[pieces.shift()] + "." + pieces.join(".") : name; }
    var missing = ["Configuration"].concat(Schema.sets).filter(function (name) { return !sets.some(function (set) { return set.getAttribute("Name") === name; }); });
    if (missing.length) { throw failure("Este servicio no es el mantenimiento esperado. Faltan: " + missing.join(", ") + ". Usa el binding de YUI_DM_CFG_O4."); }
    var root = sets.find(function (set) { return set.getAttribute("Name") === "Configuration"; });
    var actions = all(doc, "Action").filter(function (action) {
      if (action.getAttribute("Name") !== "Aplicar" || action.getAttribute("IsBound") !== "true") { return false; }
      var binding = all(action, "Parameter")[0];
      return binding && qualified(binding.getAttribute("Type")) === qualified(root.getAttribute("EntityType"));
    });
    if (actions.length !== 1) { throw failure("No se encontro la accion Aplicar de Configuration. Activa los behaviors y vuelve a publicar el binding."); }
    var action = actions[0], parameters = all(action, "Parameter").slice(1);
    var names = parameters.map(function (p) { return p.getAttribute("Name"); });
    if (Schema.parameters.some(function (name) { return !names.includes(name); }) || names.some(function (name) { return !Schema.parameters.includes(name); })) {
      throw failure("La accion Aplicar tiene parametros diferentes a los de esta app. Actualiza el backend y el frontend de la misma rama.");
    }
    var types = {};
    Schema.parameters.forEach(function (name) { types[name] = ["Longitud", "Decimales", "Orden", "Version", "VersionDestino"].includes(name) ? "Edm.Int32" : ["Activo", "Obligatorio"].includes(name) ? "Edm.Boolean" : "Edm.String"; });
    if (parameters.some(function (p) { return types[p.getAttribute("Name")] !== p.getAttribute("Type"); })) {
      throw failure("Los tipos de parametros de Aplicar no coinciden con esta app. Revisa el $metadata del servicio administrativo.");
    }
    return { namespace: action.parentNode.getAttribute("Namespace"), action: "Aplicar" };
  }
  return { read: read };
});
