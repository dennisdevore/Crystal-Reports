--
-- $Id: update_orderdtl_lineorder.sql 777 2006-07-26 00:00:00Z eric $
--
set serveroutput on
set verify off

declare
  CURSOR C_ORDERDTL
  IS
    select od.orderid, od.shipid, od.item, od.lotnumber, nvl(odl.linenumber, 999999999) linenumber, nvl(od.dtlpassthrunum10, 999999999) dtlpass, od.lastupdate
      from orderdtl od, orderdtlline odl
     where od.orderid = odl.orderid (+)
       and od.shipid = odl.shipid (+)
       and od.item = odl.item (+)
       and nvl(od.lotnumber, 'xxx') = nvl(odl.lotnumber (+), 'xxx')
       and (od.lineorder = 0 or od.lineorder is null)
     order by od.orderid, od.shipid, nvl(odl.linenumber, 999999999), nvl(od.dtlpassthrunum10, 999999999), od.lastupdate asc;

   cur_orderid integer;
   cur_shipid integer;
   cur_lineorder integer;
   line_count integer;
   update_count integer;
begin

   cur_orderid := -1;
   cur_shipid := -1;
   cur_lineorder := 0;
   line_count := 0;
   update_count := 0;

   for cord in C_ORDERDTL loop
   	  if(cord.orderid <> cur_orderid or
   	     cord.shipid <> cur_shipid) then
   	       cur_orderid := cord.orderid;
   	       cur_shipid := cord.shipid;
   	       cur_lineorder := 1;
   	  end if;

   	  select count(1)
   	    into line_count
   	    from orderdtl
   	   where orderid = cord.orderid
   	     and shipid = cord.shipid
   	     and lineorder = cur_lineorder;

   	  while (line_count > 0) loop
    	  	cur_lineorder := cur_lineorder + 1;
      	  select count(1)
      	    into line_count
      	    from orderdtl
      	   where orderid = cord.orderid
      	     and shipid = cord.shipid
      	    and lineorder = cur_lineorder;
   	  end loop;	

   	  update orderdtl
   	     set lineorder = cur_lineorder
   	   where orderid = cord.orderid
   	     and shipid = cord.shipid
   	     and item = cord.item
   	     and nvl(lotnumber,'xxx') = nvl(cord.lotnumber, 'xxx');

      update_count := update_count + 1;
      
      if(mod(update_count, 10000) = 0) then
      	 zut.prt('commit: '||to_char(update_count));
         commit;
      end if;
            
   	  cur_lineorder := cur_lineorder + 1;
   end loop;
   
	 zut.prt('commit: '||to_char(update_count));
   commit;
end;
/
