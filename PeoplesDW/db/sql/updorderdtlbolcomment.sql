--
-- $Id$
--
set serveroutput on;
--rename orderdtlbolcomments to oldorderdtlbolcomments;

declare
cursor curOrderdtlbolcomments is
select orderid, shipid, item, bolcomment, lastuser, lastupdate
  from oldorderdtlbolcomments;
cntRows integer;
updflag varchar2(1);

cursor curOrderdtl(in_orderid number, in_shipid number, in_item varchar2) is
  select lotnumber
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item;

begin

cntRows := 0;
updflag := upper('&&1');

for x in curOrderdtlbolcomments
loop
  zut.prt('OrderId-ShipId/Item: ' ||
          x.orderid || '-' ||
          x.shipid || '/' ||
          x.item);
  for y in curOrderdtl(x.orderid,x.shipid,x.item)
  loop
    if updflag = 'Y' then
      insert into orderdtlbolcomments
        (orderid,shipid,item,lotnumber,bolcomment,lastuser,lastupdate)
        values
        (x.orderid,x.shipid,x.item,y.lotnumber,x.bolcomment,x.lastuser,x.lastupdate);
    end if;
    cntRows := cntRows + 1;
  end loop;
end loop;

zut.prt('Total rows: ' || cntRows);

exception when others then
  zut.prt('when others' || sqlerrm);
end;
/
exit;
