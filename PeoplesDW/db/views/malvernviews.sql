create or replace view malvern_stage_carton
(
    importfileid,
    facility,
    custid,
    lpid,
    termid
)
as
    select 'TERM1234-001-99999999.csv', facility, custid, lpid, 'TERM' termid from plate;

exit;
