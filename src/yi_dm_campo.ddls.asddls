@EndUserText.label: 'DM CAMPO'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YI_DM_CAMPO
  as select from ymmt_dm_campo as Data
{
  key Data.campo_id as CampoId,
      Data.descripcion as Descripcion,
      Data.tabla_sap as TablaSap,
      Data.campo_sap as CampoSap,
      Data.tipo_segmento as TipoSegmento,
      Data.tipo_dato as TipoDato,
      Data.longitud as Longitud,
      Data.decimales as Decimales,
      Data.ayuda_valores as AyudaValores,
      Data.tipo_control as TipoControl,
      Data.activo as Activo
}
