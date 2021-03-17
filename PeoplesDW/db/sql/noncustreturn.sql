--
-- $Id$
--
set serveroutput on;

declare

cursor curOpReturns is
  select *
    from plate
   where custid = 'HP'
     and type = 'PA'
     and inventoryclass = 'OP';

cursor curOrderHdr(in_orderid number,in_shipid number) is
  select *
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curAdjFromRg(in_lpid varchar2) is
  select rowid,invadjactivity.*
    from invadjactivity
   where lpid = in_lpid
     and inventoryclass = 'RG'
     and adjqty < 0;

cursor curAdjToOp(in_lpid varchar2, in_adjdate date) is
  select *
    from invadjactivity
   where lpid = in_lpid
     and inventoryclass = 'OP'
     and adjqty > 0
     and abs(whenoccurred - in_adjdate) < .006944;

type itemsumrectype is record (
     item custitem.item%type,
     cntTot integer,
     qtyTot integer,
     cntRet integer,
     qtyRet integer,
     cntNon integer,
     qtyNon integer
);

type itemsumtbltype is table of itemsumrectype
     index by binary_integer;

itemsum itemsumtbltype;
ix integer;

cntTot integer;
qtyTot integer;
cntRet integer;
qtyRet integer;
cntNon integer;
qtyNon integer;
transferfound boolean;
itemfound boolean;
updflag char(1);

procedure add_item_totals(in_item varchar2, in_qtyRet integer, in_qtyNon integer) is
begin

  itemfound := False;
  for ix in 1 .. itemsum.count
  loop
    if itemsum(ix).item = in_item then
      itemfound := True;
      exit;
    end if;
  end loop;
  if itemfound = True then
    itemsum(ix).cntTot := itemsum(ix).cntTot + 1;
    itemsum(ix).qtyTot := itemsum(ix).qtyTot + in_qtyRet + in_qtyNon;
    if in_qtyRet != 0 then
      itemsum(ix).cntRet := itemsum(ix).cntRet + 1;
      itemsum(ix).qtyRet := itemsum(ix).qtyRet + in_qtyRet;
    end if;
    if in_qtyNon != 0 then
      itemsum(ix).cntNon := itemsum(ix).cntNon + 1;
      itemsum(ix).qtyNon := itemsum(ix).qtyNon + in_qtyNon;
    end if;
  else
    ix := itemsum.count + 1;
    itemsum(ix).item := in_item;
    itemsum(ix).cntTot := 1;
    itemsum(ix).qtyTot := in_qtyRet + in_qtyNon;
    itemsum(ix).cntRet := 0;
    itemsum(ix).qtyRet := 0;
    itemsum(ix).cntNon := 0;
    itemsum(ix).qtyNon := 0;
    if in_qtyRet != 0 then
      itemsum(ix).cntRet := itemsum(ix).cntRet + 1;
      itemsum(ix).qtyRet := itemsum(ix).qtyRet + in_qtyRet;
    end if;
    if in_qtyNon != 0 then
      itemsum(ix).cntNon := itemsum(ix).cntNon + 1;
      itemsum(ix).qtyNon := itemsum(ix).qtyNon + in_qtyNon;
    end if;
  end if;
end;

begin

cntTot := 0;
qtyTot := 0;
cntRet := 0;
qtyRet := 0;
cntNon := 0;
qtyNon := 0;
itemsum.delete;

updflag := upper('&1');

for op in curOpReturns
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + op.quantity;

  oh := null;
  open curOrderHdr(op.orderid,op.shipid);
  fetch curOrderHdr into oh;
  close curOrderHdr;

  if nvl(oh.ordertype,'x') != 'Q' then
    cntNon := cntNon + 1;
    qtyNon := qtyNon + op.quantity;
    add_item_totals(op.item, 0, op.quantity);
  else
    cntRet := cntRet + 1;
    qtyRet := qtyRet + op.quantity;
    add_item_totals(op.item, op.quantity, 0);
  end if;

end loop;

zut.prt('totals by examining order type');
zut.prt('Tot Count ' || cntTot || ' Quantity ' || qtyTot);
zut.prt('Non Count ' || cntNon || ' Quantity ' || qtyNon);
zut.prt('Ret Count ' || cntRet || ' Quantity ' || qtyRet);

zut.prt('Item Sub-Totals');
for ix in 1 .. itemsum.count
loop
  zut.prt('item ' || itemsum(ix).item);
  zut.prt('   Tot Count ' || itemsum(ix).cntTot || ' Quantity ' || itemsum(ix).qtyTot);
  zut.prt('   Non Count ' || itemsum(ix).cntNon || ' Quantity ' || itemsum(ix).qtyNon);
  zut.prt('   Ret Count ' || itemsum(ix).cntRet || ' Quantity ' || itemsum(ix).qtyRet);
end loop;

cntTot := 0;
qtyTot := 0;
cntRet := 0;
qtyRet := 0;
cntNon := 0;
qtyNon := 0;
itemsum.delete;

for op in curOpReturns
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + op.quantity;

  transferfound := False;

  for arg in curAdjFromRg(op.lpid)
  loop
    for aop in curAdjToOp(arg.lpid,arg.whenoccurred)
    loop
      transferfound := True;
    end loop;
    if transferfound then
      oh := null;
      open curOrderHdr(op.orderid,op.shipid);
      fetch curOrderHdr into oh;
      close curOrderHdr;
      if oh.ordertype = 'Q' then
        zut.prt(op.orderid || '-' || op.shipid || ' ' || op.lpid);
        transferfound := False;
      end if;
      if transferfound then
        if updflag = 'Y' then
          zut.prt('updated');
/*
          update invadjactivity
             set newcustid = custid,
                 newitem = item,
                 newlotnumber = lotnumber,
                 newinvstatus = invstatus,
                 newinventoryclass = 'OP'
           where rowid = arg.rowid;
*/
        end if;
        exit;
      end if;
    end if;
  end loop;

  if transferfound then
    cntNon := cntNon + 1;
    qtyNon := qtyNon + op.quantity;
    add_item_totals(op.item, 0, op.quantity);
  else
    cntRet := cntRet + 1;
    qtyRet := qtyRet + op.quantity;
    add_item_totals(op.item, op.quantity, 0);
  end if;

end loop;

zut.prt('totals by examining transfers');
zut.prt('Tot Count ' || cntTot || ' Quantity ' || qtyTot);
zut.prt('Non Count ' || cntNon || ' Quantity ' || qtyNon);
zut.prt('Ret Count ' || cntRet || ' Quantity ' || qtyRet);

zut.prt('Item Sub-Totals');
for ix in 1 .. itemsum.count
loop
  zut.prt('item ' || itemsum(ix).item);
  zut.prt('   Tot Count ' || itemsum(ix).cntTot || ' Quantity ' || itemsum(ix).qtyTot);
  zut.prt('   Non Count ' || itemsum(ix).cntNon || ' Quantity ' || itemsum(ix).qtyNon);
  zut.prt('   Ret Count ' || itemsum(ix).cntRet || ' Quantity ' || itemsum(ix).qtyRet);
end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
