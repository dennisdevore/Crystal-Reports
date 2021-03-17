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
   msg varchar2(255);
   selcnt integer := 0;
   updcnt integer := 0;
begin
 	dbms_output.enable(1000000);

   for rj in c_rf loop
      selcnt := selcnt + 1;

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
         zbill.add_asof_inventory('107', '8475', lp.item, lp.lotnumber,
               lp.unitofmeasure, '30-JUN-02', rj.qty, 'PIFix', 'AD',
               'RG', 'AV', 'SYNAPSE', msg);
         if (msg = 'OKAY') then
            updcnt := updcnt + 1;
         else
  	         dbms_output.put_line(rj.lpid || ' error: ' || msg);
         end if;
         goto continue_loop;
      end if;

      for ph in c_hist(rj.lpid) loop
         lp.item := ph.item;
         lp.lotnumber := ph.lotnumber;
         lp.unitofmeasure := ph.unitofmeasure;
         lp.quantity := ph.quantity;
         lp.invstatus := ph.invstatus;
         lp.inventoryclass := ph.inventoryclass;
      end loop;

		if lp.quantity = 0 then
			select quantity into lp.quantity
				from platehistory
				where lpid = rj.lpid
				  and whenoccurred = (select max(whenoccurred) from platehistory
							where lpid = rj.lpid);
		end if;

      zbill.add_asof_inventory('107', '8475', lp.item, lp.lotnumber,
         lp.unitofmeasure, '30-JUN-02', rj.qty-lp.quantity, 'PIFix', 'AD',
         lp.inventoryclass, lp.invstatus, 'SYNAPSE', msg);
      if (msg = 'OKAY') then
         updcnt := updcnt + 1;
      else
  	      dbms_output.put_line(rj.lpid || ' error: ' || msg);
      end if;

   <<continue_loop>>
      null;
   end loop;
  	dbms_output.put_line('Selected: ' || selcnt);
  	dbms_output.put_line('Updated: ' || updcnt);
end;
/
