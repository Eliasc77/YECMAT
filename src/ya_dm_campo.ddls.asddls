@EndUserText.label: 'DM mantenimiento CAMPO'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YA_DM_CAMPO
  as select from ymmt_dm_campo as Data
    inner join ymmt_dm_cfg_usr as Access
      on Access.user_name = $session.user and Access.active = 'X'
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
