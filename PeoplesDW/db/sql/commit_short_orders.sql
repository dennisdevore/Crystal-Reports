set serveroutput on;

declare
l_count pls_integer;
l_errno pls_integer;
l_errmsg varchar2(255);
l_userid userheader.nameid%type;

begin

for oh in (select orderid,shipid,fromfacility,wave,custid,priority
             from orderhdr
            where ordertype = 'O'
              and orderstatus > '1'
              and orderstatus < '9'
              and qtypick + qtycommit < qtyorder
            order by orderid, shipid)
loop

  zut.prt('Processing ' || oh.orderid || '-' || oh.shipid);
  
  l_userid := 'SYNAPSE';
  for od in (
   select item, uom, lotnumber,
         invstatusind, invstatus,
         invclassind, inventoryclass,
         nvl(zwt.order_by_weight_qty(oh.orderid, oh.shipid, item, lotnumber),0) - nvl(qtycommit,0) - nvl(qtypick,0) as qty,
         xdockorderid,
         xdockshipid,
         nvl(backorder,'N') as backorder,
         nvl(min_days_to_expiration,0) as min_days_to_expiration
    from orderdtl
   where orderid = oh.orderid
     and shipid = oh.shipid
     and linestatus != 'X'
   order by item, lotnumber)
 loop
    zcm.commit_line
        (oh.fromfacility
        ,oh.custid
        ,oh.orderid
        ,oh.shipid
        ,od.item
        ,od.uom
        ,od.lotnumber
        ,od.invstatusind
        ,od.invstatus
        ,od.invclassind
        ,od.inventoryclass
        ,od.qty
        ,oh.priority
        ,'1'
        ,l_userid
        ,l_errmsg
        );
    if substr(l_errmsg,1,4) != 'OKAY' then
      zut.prt(l_errmsg || od.item);
      rollback;
    else
      commit;
    end if;
  end loop;
  
end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
