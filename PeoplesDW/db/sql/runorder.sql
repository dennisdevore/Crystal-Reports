--
-- $Id$
--
declare

cursor curUnshipped is
  select orderid,shipid,orderstatus,dt(lastupdate) as lastdate,
         fromfacility
    from orderhdr o
   where orderid = &order_id
     and orderstatus < '9'
     and exists
      (select * from multishipdtl m
        where o.orderid = m.orderid
          and o.shipid = m.shipid
          and m.status = 'READY')
   order by lastupdate;

cursor curStation(in_facility varchar2) is
  select termid
    from multishipterminal
   where facility = in_facility
   order by termid;
sta curStation%rowtype;

out_msg varchar2(255);
out_errorno integer;
cntTot integer;
update_yn char(1);


begin

out_msg := '';
out_errorno := 0;
cntTot := 0;
update_yn := upper('&Flag');


for xx in curUnshipped
loop

  zut.prt('Order ' || xx.orderid || '-' || xx.shipid || ' Status ' || xx.orderstatus ||
    ' Last Update ' || xx.lastdate);
  cntTot := cntTot + 1;

  if update_yn = 'Y' then
    sta := null;
    open curStation(xx.fromfacility);
    fetch curStation into sta;
    close curStation;
    if sta.termid is null then
      zut.prt('Unable to locate terminal id for facility ' || xx.fromfacility);
    else
      insert into worldshipdtl
        select orderid,shipid,cartonid,estweight,estweight,'(manual)',
        'SHIPPED','pending','Ground',null,0.0,sta.termid,'N',null,length,width,height
           from multishipdtl
          where orderid = xx.orderid
            and shipid = xx.shipid
            and status = 'READY';
      commit;
    end if;
  end if;

end loop;

zut.prt('Order count: ' || cntTot);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/

