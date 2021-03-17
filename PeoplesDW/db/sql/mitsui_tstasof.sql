--
-- $Id$
--
set serveroutput on
declare
   cursor c_rf is
      select *
         from ed_rejlps
         order by lpid;
   cursor c_lp (p_lpid varchar2) is
      select item, status, lotnumber, unitofmeasure, quantity, invstatus,
             inventoryclass, lasttask
         from plate
         where lpid = p_lpid;
   lp c_lp%rowtype;
   cursor c_dlp (p_lpid varchar2) is
      select item, 'D', lotnumber, unitofmeasure, quantity, invstatus,
             inventoryclass, lasttask
         from deletedplate
         where lpid = p_lpid;
   cursor c_hist(p_lpid varchar2) is
      select * from platehistory
         where lpid = p_lpid
           and trunc(whenoccurred) = '30-JUN-02'
         order by whenoccurred;
   dataloc varchar2(10);
begin
 	dbms_output.enable(1000000);

   for rj in c_rf loop

      lp := null;
      open c_lp(rj.lpid);
      fetch c_lp into lp;
      if c_lp%notfound then
         open c_dlp(rj.lpid);
         fetch c_dlp into lp;
         close c_dlp;
      end if;
      close c_lp;

      if lp.status is null then
         dbms_output.put_line(rj.lpid || ' Not found');
         goto continue_loop;
      end if;

      if rj.new = 'Y' then
         dbms_output.put_line('New: ' || rj.lpid || ' ' || lp.item || '/'
               || nvl(lp.lotnumber, '(none) ')
               || rj.qty || ' ' || lp.unitofmeasure);
         goto continue_loop;
      end if;

      dataloc := 'Plate';
      for ph in c_hist(rj.lpid) loop
         lp.item := ph.item;
         lp.lotnumber := ph.lotnumber;
         lp.unitofmeasure := ph.unitofmeasure;
         lp.quantity := ph.quantity;
         lp.invstatus := ph.invstatus;
         lp.inventoryclass := ph.inventoryclass;
         dataloc := 'History';
      end loop;

		if lp.quantity = 0 then
			select quantity into lp.quantity
				from platehistory
				where lpid = rj.lpid
				  and whenoccurred = (select max(whenoccurred) from platehistory
							where lpid = rj.lpid);
			dataloc := '0'||dataloc;
		end if;

      dbms_output.put_line(lp.status || '.' || dataloc || ': ' || rj.lpid
            || ' ' || lp.item || '/' || nvl(lp.lotnumber, '(none) ')
            || rj.qty || ' ' || lp.unitofmeasure || ' from ' || lp.quantity
            || ' ' || lp.invstatus || ' ' || lp.inventoryclass);

   <<continue_loop>>
      null;
   end loop;
end;
/
