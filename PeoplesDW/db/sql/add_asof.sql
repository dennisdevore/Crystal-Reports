--
-- $Id$
--
set serveroutput on
set verify off
accept p_facility prompt 'Enter facility: '
accept p_custid prompt 'Enter custid: '
accept p_item prompt 'Enter item: '
accept p_lot prompt 'Enter lot: '
accept p_uom prompt 'Enter uom: '
accept p_effdate prompt 'Enter effdate (YYYYMMDD): '
accept p_qty prompt 'Enter qty: '
accept p_wieght prompt 'Enter weight: '
accept p_class prompt 'Enter class: '
accept p_status prompt 'Enter status: '
accept p_orderid prompt 'Enter orderid: '
accept p_shipid prompt 'Enter shipid: '
accept p_lpid prompt 'Enter lpid: '

declare
   sv_max_asof_backdate customer_aux.max_asof_backdate_days%type;
   errmsg varchar2(400);
begin
   dbms_output.enable(1000000);

-- to make sure the add_asof_inventory doesn't fail on an older effdate,
-- we turn off the customer_aux.max_asof_backdate_days, making it 0.
-- at end of script we restore its original value.
   BEGIN
	select nvl(max_asof_backdate_days,0)
	  into sv_max_asof_backdate
	  from customer_aux
	 where custid = upper('&&p_custid');
   EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		sv_max_asof_backdate := 0;
   END;
   update customer_aux set max_asof_backdate_days = 0 where custid = upper('&&p_custid');

   zbill.add_asof_inventory(
         upper('&&p_facility'),
         upper('&&p_custid'),
         upper('&&p_item'),
         upper('&&p_lot'),
         upper('&&p_uom'),
         to_date('&&p_effdate','YYYYMMDD'),
         &&p_qty,
         &&p_weight,
         'AdjustIC',
         'AD',
         upper('&&p_class'),
         upper('&&p_status'),
         &&p_orderid,
         &&p_shipid,
         upper('&&p_lpid'),
         'SYNAPSE',
         errmsg);
   if errmsg != 'OKAY' then
      zut.prt('Error adding asof: ' || errmsg);
   end if;

-- restore the customer_aux.max_asof_backdate_days to its original value
   if sv_max_asof_backdate > 0 then
	   update customer_aux set max_asof_backdate_days = sv_max_asof_backdate 
		where custid = upper('&&p_custid');
   end if;
end;
/
