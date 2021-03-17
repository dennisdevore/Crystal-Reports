set serveroutput on;

declare
l_cnt pls_integer := 0;
l_tot_cnt pls_integer := 0;
l_oky_cnt pls_integer := 0;
l_err_cnt pls_integer := 0;
l_orderid orderhdr.orderid%type;
l_upd_flag char(1) := 'N';

begin

for dtl in (select orderid,shipid,facility,custid,
                   orderitem,orderlot,uom,qtyrcvd,
                   lastupdate,qtyrcvdgood,qtyrcvddmgd
              from orderdtlrcpt sp
             where not exists
                   (select 1
                      from orderhdr oh
                     where sp.orderid = oh.orderid
                       and sp.shipid = oh.shipid
                       and ordertype = 'T')
               and not exists 
                   (select 1
                      from orderdtl od
                     where sp.orderid = od.orderid
                       and sp.shipid = od.shipid
                       and sp.item = od.item
                       and nvl(sp.orderlot,'x') = nvl(od.lotnumber,'x')))
loop

  l_tot_cnt := l_tot_cnt + 1;

  l_err_cnt := l_err_cnt + 1;
  
  if l_upd_flag = 'Y' then
    begin
      insert into orderdtl
      (orderid,shipid,item,lotnumber,
       custid,fromfacility,
       uom,linestatus,
       qtyentered,itementered,uomentered,
       qtyorder,weightorder,cubeorder,amtorder,
       qtyrcvd,weightrcvd,cubercvd,amtrcvd,
       qtyrcvdgood,weightrcvdgood,cubercvdgood,amtrcvdgood,
       qtyrcvddmgd,weightrcvddmgd,cubercvddmgd,amtrcvddmgd,
       comment1,
       statususer,statusupdate,
       lastuser,lastupdate,
       invstatusind,invclassind
      )
      values
      (dtl.orderid,dtl.shipid,dtl.orderitem,dtl.orderlot,
       dtl.custid,dtl.facility,
       dtl.uom,'A',
       dtl.qtyrcvd,dtl.orderitem,dtl.uom,
       dtl.qtyrcvd,
       zci.item_weight(dtl.custid,dtl.orderitem,dtl.uom)
       * dtl.qtyrcvd,
       zci.item_cube(dtl.custid,dtl.orderitem,dtl.uom)
       * dtl.qtyrcvd,
       zci.item_amt(dtl.custid,null,null,dtl.orderitem,null) * dtl.qtyrcvd,
       dtl.qtyrcvd,
       zci.item_weight(dtl.custid,dtl.orderitem,dtl.uom)
       * dtl.qtyrcvd,
       zci.item_cube(dtl.custid,dtl.orderitem,dtl.uom)
       * dtl.qtyrcvd,
       zci.item_amt(dtl.custid,null,null,dtl.orderitem,null) * dtl.qtyrcvd,
       dtl.qtyrcvdgood,
       zci.item_weight(dtl.custid,dtl.orderitem,dtl.uom)
       * dtl.qtyrcvdgood,
       zci.item_cube(dtl.custid,dtl.orderitem,dtl.uom)
       * dtl.qtyrcvdgood,
       zci.item_amt(dtl.custid,null,null,dtl.orderitem,null) * dtl.qtyrcvdgood,
       dtl.qtyrcvddmgd,
       zci.item_weight(dtl.custid,dtl.orderitem,dtl.uom)
       * dtl.qtyrcvddmgd,
       zci.item_cube(dtl.custid,dtl.orderitem,dtl.uom)
       * dtl.qtyrcvddmgd,
       zci.item_amt(dtl.custid,null,null,dtl.orderitem,null) * dtl.qtyrcvddmgd,
       'Recreated by system',
       'SYNAPSE', sysdate,
       'SYNAPSE', sysdate,
       'I', 'I'
      );
    exception when dup_val_on_index then
      update orderdtl
         set qtyentered = qtyentered + dtl.qtyrcvd,
             qtyorder = qtyorder + dtl.qtyrcvd,
             weightorder = weightorder +
               (zci.item_weight(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvd),
             cubeorder = cubeorder +
               (zci.item_cube(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvd),
             amtorder = amtorder + 
               (zci.item_amt(dtl.custid,orderid,shipid,dtl.orderitem,lotnumber)
               * dtl.qtyrcvd),
             qtyrcvd = qtyrcvd + dtl.qtyrcvd,
             weightrcvd = weightrcvd +
               (zci.item_weight(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvd),
             cubercvd = cubercvd +
               (zci.item_cube(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvd),
             amtrcvd = amtrcvd + 
               (zci.item_amt(dtl.custid,orderid,shipid,dtl.orderitem,lotnumber)
               * dtl.qtyrcvd),
             qtyrcvdgood = qtyrcvdgood + dtl.qtyrcvdgood,
             weightrcvdgood = weightrcvdgood +
               (zci.item_weight(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvdgood),
             cubercvdgood = cubercvdgood +
               (zci.item_cube(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvdgood),
             amtrcvdgood = amtrcvdgood + 
               (zci.item_amt(dtl.custid,orderid,shipid,dtl.orderitem,lotnumber)
               * dtl.qtyrcvdgood),
             qtyrcvddmgd = qtyrcvddmgd + dtl.qtyrcvddmgd,
             weightrcvddmgd = weightrcvddmgd +
               (zci.item_weight(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvddmgd),
             cubercvddmgd = cubercvddmgd +
               (zci.item_cube(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvddmgd),
             amtrcvddmgd = amtrcvddmgd + 
               (zci.item_amt(dtl.custid,orderid,shipid,dtl.orderitem,lotnumber)
               * dtl.qtyrcvddmgd)
       where orderid = dtl.orderid
         and shipid = dtl.shipid
         and item = dtl.orderitem
         and nvl(lotnumber,'x') = nvl(dtl.orderlot,'x');
    end;
    
  end if;

  if (l_err_cnt < 10000) then
    zut.prt(dtl.orderid || '-' || dtl.shipid || ' ' ||
            dtl.orderitem || ' ' || dtl.orderlot || ' ' ||
            dtl.uom || ' ' || dtl.qtyrcvd || ' ' ||
            dtl.custid || ' ' || dtl.facility || ' ' ||
            dtl.lastupdate);
  end if;

end loop;

zut.prt('tot ' || l_tot_cnt);
zut.prt('oky ' || l_oky_cnt);
zut.prt('err ' || l_err_cnt);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
