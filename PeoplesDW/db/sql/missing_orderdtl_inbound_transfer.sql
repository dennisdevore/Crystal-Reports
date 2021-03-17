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
             where exists
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
                       and od.lotnumber is null))
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
             qtytotcommit = qtytotcommit + dtl.qtyrcvd,
             weighttotcommit = weighttotcommit +
               (zci.item_weight(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvd),
             cubetotcommit = cubetotcommit +
               (zci.item_cube(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvd),
             amttotcommit = amttotcommit + 
               (zci.item_amt(dtl.custid,orderid,shipid,dtl.orderitem,lotnumber)
               * dtl.qtyrcvd),
             qtypick = qtypick + dtl.qtyrcvd,
             weightpick = weightpick +
               (zci.item_weight(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvd),
             cubepick = cubepick +
               (zci.item_cube(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvd),
             amtpick = amtpick + 
               (zci.item_amt(dtl.custid,orderid,shipid,dtl.orderitem,lotnumber)
               * dtl.qtyrcvd),
             qtyship = qtyship + dtl.qtyrcvd,
             weightship = weightship +
               (zci.item_weight(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvd),
             cubeship = cubeship +
               (zci.item_cube(dtl.custid,dtl.orderitem,dtl.uom)
               * dtl.qtyrcvd),
             amtship = amtship + 
               (zci.item_amt(dtl.custid,orderid,shipid,dtl.orderitem,lotnumber)
               * dtl.qtyrcvd)
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
