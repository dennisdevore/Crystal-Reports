--
-- $Id$
--
set serveroutput on
declare
errmsg varchar2(400);
errno  integer;
warnno  integer;
rc integer;
RATE custrate%rowtype;

CURSOR C_POSTHDR
IS
  SELECT rowid, PH.* from posthdr PH;

CURSOR C_INVMST(in_invoice varchar2)
RETURN invoicemaster%rowtype
IS
  SELECT *
    FROM invoicemaster
   WHERE masterinvoice = in_invoice;

IM invoicemaster%rowtype;

inv varchar2(8);

begin

   dbms_output.enable(1000000);


   for crec in C_POSTHDR loop
       IM := null;

       inv := substr(to_char(crec.invoice,'09999999'),2);
       OPEN C_INVMST(substr(to_char(crec.invoice,'09999999'),2));
       FETCH C_INVMST into IM;
       CLOSE C_INVMST;

      -- zut.prt('Inv:'||inv||'<<');
      -- zut.prt('IM:'||IM.facility||'<<');


       update posthdr
          set facility = IM.facility
        where rowid = crec.rowid;

   end loop;

zut.prt('Errno:'||errno||' Msg:'||errmsg);
end;

/

