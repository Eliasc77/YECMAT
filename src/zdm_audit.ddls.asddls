@EndUserText.label : 'DM auditoría fina'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zdm_audit {
  key client            : abap.clnt not null;
  key audit_uuid        : sysuuid_x16 not null;
  request_uuid          : sysuuid_x16;
  area                  : abap.char(5);
  event_type            : abap.char(12);
  field_name            : abap.char(40);
  old_value             : abap.string(0);
  new_value             : abap.string(0);
  changed_by            : syuname;
  changed_at            : abap.utclong;
}
