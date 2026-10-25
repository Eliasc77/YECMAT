@EndUserText.label : 'DM cola transaccional de material'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zdm_outbox {
  key client            : abap.clnt not null;
  key event_uuid        : sysuuid_x16 not null;
  request_uuid          : sysuuid_x16;
  event_type            : abap.char(12);
  status                : abap.char(1);
  retry_count           : abap.int2;
  next_attempt_at       : abap.utclong;
  message_text          : abap.char(255);
  created_at            : abap.utclong;
  processed_at          : abap.utclong;
}
