// YECMAT RAP - proyección UI de campos dinámicos
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'DM Campos - consumo'
@Metadata.allowExtensions: true
define root view entity ZC_DM_FieldValue
  provider contract transactional_query
  as projection on ZI_DM_FieldValue
{
  key FieldValueUUID,
      RequestUUID,
      Area,
      FieldName,
      FieldValue,
      ValueUnit,
      LastChangedBy,
      LastChangedAt
}
