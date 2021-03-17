--
-- $Id$
--
declare
   cursor c_oh(p_orderid number) is
      select rowid, orderid
         from orderhdr
         where orderid >= p_orderid
           and companycheckok is null;
   cnt integer;
   last_order orderhdr.orderid%type := 0;
begin

   while (1=1)
   loop
      cnt := 0;
      for oh in c_oh(last_order) loop
         last_order := oh.orderid;
         update orderhdr
            set companycheckok = 'N'
            where rowid = oh.rowid;
         cnt := cnt + 1;
         exit when (cnt >= 1000);
      end loop;
      commit;
      exit when (cnt = 0);
   end loop;
end;
/
