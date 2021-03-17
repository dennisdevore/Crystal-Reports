--
-- $Id$
--
set serveroutput on
declare
   cursor c_mp is
      select lpid
         from plate P
         where P.facility = 'DTV'
           and P.custid = '17131'
           and P.type = 'MP'
           and not exists (select * from plate C
		            where C.facility = 'DTV'
		              and C.custid = '17131'
		              and C.parentlpid=P.lpid);
   cnt pls_integer := 0;
   msg varchar2(80) := null;
begin

   dbms_output.enable(1000000);
   for mp in c_mp loop
      zlp.plate_to_deletedplate(mp.lpid, 'CFARLEY', null, msg);
	   if (msg is not null) then
         dbms_output.put_line(mp.lpid || ' NOT deleted');
		   rollback;
	   else
         dbms_output.put_line(mp.lpid || ' deleted');
         cnt := cnt + 1;
		   commit;
	   end if;
   end loop;
   dbms_output.put_line(cnt || ' deleted');
end;
/
