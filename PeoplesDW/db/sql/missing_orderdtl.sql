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
                   orderitem,orderlot,unitofmeasure,quantity,
                   lastupdate, status
              from shippingplate sp
             where type in ('P','F')
               and not exists 
                   (select 1
                      from orderdtl od
                     where sp.orderid = od.orderid
                       and sp.shipid = od.shipid
                       and sp.orderitem = od.item
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
       qtytotcommit,weighttotcommit,cubetotcommit,amttotcommit,
       qtypick,weightpick,cubepick,amtpick,
       qtyship,weightship,cubeship,amtship,
       comment1,
       statususer,statusupdate,
       lastuser,lastupdate,
       invstatusind,invclassind
      )
      values
      (dtl.orderid,dtl.shipid,dtl.orderitem,dtl.orderlot,
       dtl.custid,dtl.facility,
       dtl.unitofmeasure,'A',
       dtl.quantity,dtl.orderitem,dtl.unitofmeasure,
       dtl.quantity,
       zci.item_weight(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
       * dtl.quantity,
       zci.item_cube(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
       * dtl.quantity,
       zci.item_amt(dtl.custid,null,null,dtl.orderitem,null) * dtl.quantity,
       dtl.quantity,
       zci.item_weight(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
       * dtl.quantity,
       zci.item_cube(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
       * dtl.quantity,
       zci.item_amt(dtl.custid,null,null,dtl.orderitem,null) * dtl.quantity,
       dtl.quantity,
       zci.item_weight(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
       * dtl.quantity,
       zci.item_cube(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
       * dtl.quantity,
       zci.item_amt(dtl.custid,null,null,dtl.orderitem,null) * dtl.quantity,
       dtl.quantity,
       zci.item_weight(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
       * dtl.quantity,
       zci.item_cube(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
       * dtl.quantity,
       zci.item_amt(dtl.custid,null,null,dtl.orderitem,null) * dtl.quantity,
       'Recreated by system',
       'SYNAPSE', sysdate,
       'SYNAPSE', sysdate,
       'I', 'I'
      );
    exception when dup_val_on_index then
      update orderdtl
         set qtyentered = qtyentered + dtl.quantity,
             qtyorder = qtyorder + dtl.quantity,
             weightorder = weightorder +
               (zci.item_weight(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
               * dtl.quantity),
             cubeorder = cubeorder +
               (zci.item_cube(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
               * dtl.quantity),
             amtorder = amtorder + 
               (zci.item_amt(dtl.custid,orderid,shipid,dtl.orderitem,lotnumber)
               * dtl.quantity),
             qtytotcommit = qtytotcommit + dtl.quantity,
             weighttotcommit = weighttotcommit +
               (zci.item_weight(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
               * dtl.quantity),
             cubetotcommit = cubetotcommit +
               (zci.item_cube(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
               * dtl.quantity),
             amttotcommit = amttotcommit + 
               (zci.item_amt(dtl.custid,orderid,shipid,dtl.orderitem,lotnumber)
               * dtl.quantity),
             qtypick = qtypick + dtl.quantity,
             weightpick = weightpick +
               (zci.item_weight(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
               * dtl.quantity),
             cubepick = cubepick +
               (zci.item_cube(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
               * dtl.quantity),
             amtpick = amtpick + 
               (zci.item_amt(dtl.custid,orderid,shipid,dtl.orderitem,lotnumber)
               * dtl.quantity),
             qtyship = qtyship + dtl.quantity,
             weightship = weightship +
               (zci.item_weight(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
               * dtl.quantity),
             cubeship = cubeship +
               (zci.item_cube(dtl.custid,dtl.orderitem,dtl.unitofmeasure)
               * dtl.quantity),
             amtship = amtship + 
               (zci.item_amt(dtl.custid,orderid,shipid,dtl.orderitem,lotnumber)
               * dtl.quantity)
       where orderid = dtl.orderid
         and shipid = dtl.shipid
         and item = dtl.orderitem
         and nvl(lotnumber,'x') = nvl(dtl.orderlot,'x');
    end;
    
  end if;

  if (l_err_cnt < 10000) then
    zut.prt(dtl.orderid || '-' || dtl.shipid || ' ' ||
            dtl.orderitem || ' ' || dtl.orderlot || ' ' ||
            dtl.unitofmeasure || ' ' || dtl.quantity || ' ' ||
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
