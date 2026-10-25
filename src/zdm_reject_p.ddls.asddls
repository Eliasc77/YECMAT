// YECMAT RAP - parámetro de devolución a un área
@EndUserText.label: 'DM parámetro de rechazo'
define abstract entity ZDM_REJECT_P {
  Area   : abap.char(5);
  Reason : abap.char(255);
}
