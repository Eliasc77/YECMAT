sap.ui.define(["./Schema"], function (Schema) {
  "use strict";
  function report(state, row) {
    var checks = [], issues = [];
    function check(label, messages, target) {
      checks.push({ label: label, ok: !messages.length, detail: messages.length ? messages.join("\n") : "Completo", target: target });
      issues = issues.concat(messages);
    }
    var flow = state.Flujos.find(function (f) { return f.FlujoId === row.FlujoId; });
    check("Flujo activo", !flow ? ["El flujo no existe"] : !flow.Activo ? ["Activa el flujo antes de publicar"] : Schema.validate("Flujos", flow), "Flujos");
    check("Vigencia", Schema.validate("Versiones", row), "Versiones");
    var steps = state.Pasos.filter(function (p) { return p.FlujoId === row.FlujoId && p.Version === row.Version && p.Activo; });
    var stepErrors = [];
    ["A", "B"].forEach(function (kind) { if (!steps.some(function (p) { return !p.CondicionBpm || p.CondicionBpm === kind; })) { stepErrors.push("Faltan pasos activos aplicables a " + kind); } });
    steps.forEach(function (step) { Schema.validate("Pasos", step).forEach(function (e) { stepErrors.push(step.PasoId + ": " + e); }); });
    check("Pasos y areas", stepErrors, "Pasos");
    var rules = state.Reglas.filter(function (r) { return r.FlujoId === row.FlujoId && r.Version === row.Version && r.Activo; });
    var ruleErrors = [], keys = new Set();
    if (!rules.length) { ruleErrors.push("Agrega al menos una regla activa"); }
    rules.forEach(function (rule) {
      var key = Schema.key("Reglas", rule);
      if (keys.has(key)) { ruleErrors.push("Regla duplicada: " + key); } keys.add(key);
      Schema.validate("Reglas", rule).forEach(function (error) { ruleErrors.push(rule.CampoId + ": " + error); });
      var field = state.Campos.find(function (f) { return f.CampoId === rule.CampoId; });
      var section = state.Secciones.find(function (s) { return s.SeccionId === rule.SeccionId; });
      if (!field || !field.Activo) { ruleErrors.push(rule.CampoId + ": campo inexistente o inactivo"); }
      else { Schema.validate("Campos", field).forEach(function (error) { ruleErrors.push(rule.CampoId + ": " + error); }); }
      if (!section || !section.Activo) { ruleErrors.push(rule.CampoId + ": seccion inexistente o inactiva"); }
      if (!steps.some(function (p) { return p.Area === rule.Area; })) { ruleErrors.push(rule.CampoId + ": falta un paso activo para el area " + rule.Area); }
    });
    check("Reglas, campos y secciones", ruleErrors, "Reglas");
    var overlaps = [];
    if (flow) {
      state.Versiones.forEach(function (v) {
        if (v.Estado !== "PUBLICADA" || v.FlujoId === row.FlujoId && v.Version === row.Version) { return; }
        var other = state.Flujos.find(function (f) { return f.FlujoId === v.FlujoId; });
        var matches = v.FlujoId === row.FlujoId || other && other.Activo && other.TipoMaterial === flow.TipoMaterial && other.TipoOperacion === flow.TipoOperacion && (!other.CentroCriterio || !flow.CentroCriterio || other.CentroCriterio === flow.CentroCriterio);
        if (matches && v.VigenteDesde <= (row.VigenteHasta || "9999-12-31") && row.VigenteDesde <= (v.VigenteHasta || "9999-12-31")) { overlaps.push("Coincide con " + v.FlujoId + " / version " + v.Version + ". Revisa las fechas o retira la version anterior cuando corresponda."); }
      });
    }
    check("Versiones publicadas sin solapamiento", overlaps, "Versiones");
    return { ready: issues.length === 0, checks: checks, issues: issues, steps: steps.length, rules: rules.length };
  }
  return { report: report };
});
