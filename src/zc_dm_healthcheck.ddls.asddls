@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'YECMAT repository health check'
define view entity ZC_DM_HealthCheck
  as select from zdm_req_h
{
  key request_uuid as RequestUUID,
      request_no   as RequestNo,
      status       as Status
}
