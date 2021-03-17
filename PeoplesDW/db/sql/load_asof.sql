--
-- $Id$
--
set serveroutput on
declare
errmsg varchar2(400);
rc integer;
  CURSOR C_PLATE IS
    SELECT *
      FROM PLATE
     WHERE status not in ('P','U', 'D')
       AND TYPE = 'PA';

  CURSOR C_SHIPPINGPLATE IS
    SELECT SP.*, NVL(P.creationdate,DP.creationdate) creationdate
      FROM DELETEDPLATE DP, PLATE P, SHIPPINGPLATE SP
     WHERE SP.status in ('L','P', 'S')
       AND SP.type in ('F', 'P')
       AND SP.fromlpid = P.lpid(+)
       AND SP.fromlpid = DP.lpid(+);

begin

   for crec in C_PLATE loop
       zbill.add_asof_inventory(
           crec.facility,
           crec.custid,
           crec.item,
           crec.lotnumber,
           crec.unitofmeasure,
           --trunc(sysdate),
            trunc(crec.creationdate -360),
           crec.quantity,
           'INITIAL',
           'RONG',
           errmsg
       );
   end loop;

   for crec in C_SHIPPINGPLATE loop
       zbill.add_asof_inventory(
           crec.facility,
           crec.custid,
           crec.item,
           crec.lotnumber,
           crec.unitofmeasure,
           -- trunc(sysdate),
           trunc(crec.creationdate),
           crec.quantity,
           'INITIAL',
           'RONG',
           errmsg
       );
   end loop;

end;
/
