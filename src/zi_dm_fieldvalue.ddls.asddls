@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'DM Valor de campo'
define root view entity ZI_DM_FieldValue
  as select from zdm_req_f
{
  key field_value_uuid    as FieldValueUUID,
      request_uuid        as RequestUUID,
      area                as Area,
      field_name          as FieldName,
      field_value         as FieldValue,
      value_unit          as ValueUnit,
      last_changed_by     as LastChangedBy,
      last_changed_at     as LastChangedAt
}
