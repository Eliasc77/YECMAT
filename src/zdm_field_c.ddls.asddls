@EndUserText.label : 'DM matriz dinámica de campos'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
define table zdm_field_c {
  key client            : abap.clnt not null;
  key material_type     : mtart not null;
  key operation         : abap.char(1) not null;
  key area              : abap.char(5) not null;
  key field_name        : abap.char(40) not null;
  field_status          : abap.char(1);
  sequence_no           : abap.int2;
  label                 : abap.char(60);
  default_value         : abap.char(255);
  active                : abap_boolean;
}
