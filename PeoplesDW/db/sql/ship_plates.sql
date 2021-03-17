--
-- $Id: ship_plates.sql 6351 2011-03-28 15:02:17Z eric $
--

set serveroutput on
set verify off
accept p_orderid prompt 'Enter Order ID: '
accept p_shipid prompt 'Enter Ship ID: '

DECLARE 
  cursor c_sp is
  select *
  from shippingplate
  where orderid=to_number('&&p_orderid')
  and shipid=nvl(to_number('&&p_shipid'),1)
  and status<>'SH'
  and type in('F','P');
  sp c_sp%rowtype;
  
  cursor c_pl(in_lpid varchar2) is
  select *
  from plate
  where lpid=in_lpid;
  pl c_pl%rowtype;
  
  cursor c_oh is
  select *
  from orderhdr
  where orderid=to_number('&&p_orderid')
  and shipid=nvl(to_number('&&p_shipid'),1);
  oh c_oh%rowtype;
  
  OUT_ERRMSG VARCHAR2(200);

BEGIN 
  for sp in c_sp loop

    update orderdtl
       set qtyship=qtypick,
           weightship=weightpick,
           cubeship=cubepick,
           amtship=amtpick,
           lastuser='ZETHCON',
           lastupdate=sysdate
     where orderid=sp.ORDERID 
       and shipid=sp.SHIPID
       and item=sp.orderITEM
	     and nvl(lotnumber,'(none)')=nvl(sp.orderlot,'(none)')
	     and nvl(qtyship,0)!=nvl(qtypick,0);

    update shippingplate
       set status='SH',
           lastuser='ZETHCON',
           lastupdate=sysdate
     where lpid=sp.lpid
       and status!='SH';

    update shippingplate
       set status='SH',
           lastuser='ZETHCON',
           lastupdate=sysdate
     where lpid=sp.parentlpid
       and status!='SH'
       and not exists(
       select 1
         from shippingplate
        where lpid!=sp.lpid
          and parentlpid=sp.parentlpid
          and status!='SH');

   open c_oh;
   fetch c_oh into oh;
   close c_oh;

    OUT_ERRMSG := NULL;
    ALPS.ZBILLING.ADD_ASOF_INVENTORY ( sp.FACILITY, sp.CUSTID, sp.ITEM, sp.LOTNUMBER, sp.unitofmeasure,
       nvl(trunc(oh.dateshipped),trunc(sp.lastupdate)), sp.quantity * -1, sp.weight * -1, 'Shipped', 'SH',
       sp.INVENTORYCLASS, sp.INVSTATUS, sp.ORDERID, sp.SHIPID, sp.fromLPID, 'ZETHCON', OUT_ERRMSG );

    zut.prt('Shipped ' || sp.lpid || ': ' || OUT_ERRMSG);

    if (sp.type = 'F') then
      open c_pl(sp.FROMLPID);
      fetch c_pl into pl;
      close c_pl;
      
      if (nvl(pl.quantity,0) = sp.quantity) and (nvl(pl.status,'x') = 'P') then
        OUT_ERRMSG := NULL;
        ALPS.ZPLATE.PLATE_TO_DELETEDPLATE ( sp.FROMLPID, 'ZETHCON', null, OUT_ERRMSG );

        zut.prt('Deleted plate ' || sp.fromlpid || ': ' || OUT_ERRMSG);
      end if;
    end if;
  end loop;
END; 
