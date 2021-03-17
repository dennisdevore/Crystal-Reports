--
-- $Id$
--
set serveroutput on
set feedback off
set verify off
prompt
prompt This script will update the weight of all plates in the system.
prompt The current weight will be incremented by the current quantity
prompt times the tare weight for the base uom.
prompt
prompt This script should NOT be run more than once since the tare weight
prompt will be added each time.
prompt
accept p_continue prompt 'Continue? (Y/N): '
prompt
declare
   l_cnt pls_integer;
   l_qty number(10);
   l_oweight number(20,8);
   l_nweight number(20,8);
begin

   dbms_output.enable(1000000);

	if upper('&&p_continue') != 'Y' then
   	dbms_output.put_line('Update cancelled...');
      return;
	end if;

   for itm in (select custid, item,
                      zci.item_tareweight(custid, item, baseuom) as tare
               from custitemview) loop

      l_cnt := 0;
      l_qty := 0;
      l_oweight := 0;
      l_nweight := 0;
      for lp in (select rowid, quantity, weight
                  from plate
                  where custid = itm.custid
                    and item = itm.item
                    and type = 'PA') loop

         l_cnt := l_cnt + 1;
         l_qty := l_qty + lp.quantity;
         l_oweight := l_oweight + lp.weight;
         l_nweight := l_nweight + lp.weight + (itm.tare * lp.quantity);

         update plate
            set weight = weight + (itm.tare * lp.quantity)
            where rowid = lp.rowid;
      end loop;
      dbms_output.put_line('custid: ' || itm.custid
            || ' item: ' || itm.item
            || ' count: ' || l_cnt
            || ' quantity: ' || l_qty
            || ' old weight: ' || l_oweight
            || ' new weight: ' || l_nweight);
   end loop;

   update plate P
      set P.weight = (select sum(weight) from plate
                        where parentlpid = P.lpid)
      where P.type in ('MP','TO');

end;
/

prompt
accept p_commit prompt 'OK to commit? (Y/N): '
prompt
declare
begin

   dbms_output.enable(1000000);

	if upper('&&p_commit') = 'Y' then
      commit;
   	dbms_output.put_line('Changes committed');
   else
      rollback;
   	dbms_output.put_line('Changes rolled back');
	end if;
end;
/

exit;
