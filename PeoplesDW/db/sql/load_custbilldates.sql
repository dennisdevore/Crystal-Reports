--
-- $Id$
--
set serveroutput on
declare
errmsg varchar2(400);
rc integer;
  CURSOR C_CUST IS
    SELECT custid
      FROM customer;


begin

   dbms_output.enable(1000000);

   for crec in C_CUST loop
       zbill.set_custbilldates(
           crec.custid,
       'RON',
           errmsg
       );
   end loop;

end;
/
