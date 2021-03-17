--
-- $Id$
--
declare
   cursor c_lp is
      select lpid, rowid
         from deletedplate
         where facility = 'DTV'
           and trunc(lastupdate) = '09-MAR-02';
   cnt integer;
   totdel integer := 0;
begin

   while (1=1)
   loop
      cnt := 0;
      for lp in c_lp loop
         delete deletedplate where rowid = lp.rowid;
         delete platehistory where lpid = lp.lpid;
         cnt := cnt + 1;
         totdel := totdel + 1;
         exit when (cnt >= 1000);
      end loop;
      commit;
      exit when (cnt = 0);
   end loop;
 	dbms_output.enable(1000000);
  	dbms_output.put_line('Total deleted: ' || totdel);
end;
/
exit;
