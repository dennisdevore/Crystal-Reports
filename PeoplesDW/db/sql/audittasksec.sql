--
-- $Id$
--
declare
   cursor c_task is
      select facility, fromloc, fromsection, rowid
         from tasks
			where curruserid is null;
   sect varchar2(20);
   updflag varchar2(1);
begin

   updflag := '&&1';

   dbms_output.enable(1000000);
   for t in c_task loop
      select section into sect
         from location
         where facility = t.facility
           and locid = t.fromloc;
		if (sect != t.fromsection) then
         dbms_output.put_line(t.facility || '.' || t.fromloc);
         if (updflag = 'Y') then
            update tasks
               set fromsection = sect
               where rowid = t.rowid;
            commit;
         end if;
      end if;
   end loop;
end;
/
