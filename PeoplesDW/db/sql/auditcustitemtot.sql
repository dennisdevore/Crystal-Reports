--
-- $Id$
--
set serveroutput on;

declare
notfound boolean;
totcount integer;
qtycount integer;
dtlcount integer;
ntfcount integer;
okycount integer;
wgtcount integer;
updflag varchar2(1);
out_msg varchar2(255);

cursor curCustitemtotAll is
  select facility,
         custid,
         item,
         inventoryclass,
         invstatus,
         status,
         nvl(lotnumber,'(none)') as lotnumber,
         uom,
         nvl(lipcount,0) as count,
         nvl(qty,0) as qty,
         nvl(weight,0) as weight
    from custitemtot
   order by facility, custid, item,
            inventoryclass, invstatus, status,
            lotnumber, uom;

cursor curPlateSumOne
  (in_facility varchar2
  ,in_custid varchar2
  ,in_item varchar2
  ,in_inventoryclass varchar2
  ,in_invstatus varchar2
  ,in_status varchar2
  ,in_lotnumber varchar2
  ,in_uom varchar2) is
  select nvl(count(1),0) as count,
         nvl(sum(nvl(quantity,0)),0) as qty,
         nvl(sum(nvl(weight,0)),0)as weight
    from plate
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and inventoryclass = in_inventoryclass
     and invstatus = in_invstatus
     and nvl(lotnumber,'(none)') = in_lotnumber
     and nvl(unitofmeasure,'x') = in_uom
     and status = in_status
     and type = 'PA';
p1 curPlateSumOne%rowtype;
s1 curPlateSumOne%rowtype;

cursor curShippingPlateSumPicked
  (in_facility varchar2
  ,in_custid varchar2
  ,in_item varchar2
  ,in_inventoryclass varchar2
  ,in_invstatus varchar2
  ,in_status varchar2
  ,in_lotnumber varchar2
  ,in_uom varchar2) is
  select nvl(count(1),0) as count,
         nvl(sum(nvl(quantity,0)),0) as qty,
         nvl(sum(nvl(weight,0)),0) as weight
    from shippingplate
   where status in ('P','FA')
     and facility = in_facility
     and custid = in_custid
     and item = in_item
     and inventoryclass = in_inventoryclass
     and invstatus = in_invstatus
     and nvl(lotnumber,'(none)') = in_lotnumber
     and nvl(unitofmeasure,'x') = in_uom
     and type in ('F','P');

cursor curShippingPlateSumStaged
  (in_facility varchar2
  ,in_custid varchar2
  ,in_item varchar2
  ,in_inventoryclass varchar2
  ,in_invstatus varchar2
  ,in_status varchar2
  ,in_lotnumber varchar2
  ,in_uom varchar2) is
  select nvl(count(1),0) as count,
         nvl(sum(nvl(quantity,0)),0) as qty,
         nvl(sum(nvl(weight,0)),0) as weight
    from shippingplate
   where status = 'S'
     and facility = in_facility
     and custid = in_custid
     and item = in_item
     and inventoryclass = in_inventoryclass
     and invstatus = in_invstatus
     and nvl(lotnumber,'(none)') = in_lotnumber
     and nvl(unitofmeasure,'x') = in_uom
     and type in ('F','P');


cursor curShippingPlateSumLoaded
  (in_facility varchar2
  ,in_custid varchar2
  ,in_item varchar2
  ,in_inventoryclass varchar2
  ,in_invstatus varchar2
  ,in_status varchar2
  ,in_lotnumber varchar2
  ,in_uom varchar2) is
  select nvl(count(1),0) as count,
         nvl(sum(nvl(quantity,0)),0) as qty,
         nvl(sum(nvl(weight,0)),0) as weight
    from shippingplate
   where status = 'L'
     and facility = in_facility
     and custid = in_custid
     and item = in_item
     and inventoryclass = in_inventoryclass
     and invstatus = in_invstatus
     and nvl(lotnumber,'(none)') = in_lotnumber
     and nvl(unitofmeasure,'x') = in_uom
     and type in ('F','P');


cursor curCommitmentsSumOne
  (in_facility varchar2
  ,in_custid varchar2
  ,in_item varchar2
  ,in_inventoryclass varchar2
  ,in_invstatus varchar2
  ,in_status varchar2
  ,in_lotnumber varchar2
  ,in_uom varchar2) is
  select nvl(count(1),0) as count,
         nvl(sum(nvl(qty,0)),0) as qty,
         nvl(sum(nvl(zci.item_weight(custid,item,uom) * nvl(qty,0),0)),0) as weight
    from commitments
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and inventoryclass = in_inventoryclass
     and invstatus = in_invstatus
     and nvl(lotnumber,'(none)') = in_lotnumber
     and uom = in_uom
     and status = in_status;

begin

updflag := upper('&&1');
totcount := 0;
okycount := 0;
ntfcount := 0;
qtycount := 0;
dtlcount := 0;
wgtcount := 0;

zut.prt('Comparing custitemtot to detail records...');

for c in curCustItemTotAll
loop
  totcount := totcount + 1;
  notfound := False;
  if c.status = 'CM' then
    p1 := null;
    open curCommitmentsSumOne(c.facility,c.custid,c.item,
                        c.inventoryclass, c.invstatus,c.status,
                        c.lotnumber,c.uom);
    fetch curCommitmentsSumOne into p1;
    if curCommitmentsSumOne%notfound then
      notfound := True;
    end if;
  elsif c.status = 'PN' then
    p1 := null;
    open curShippingPlateSumPicked(c.facility,c.custid,c.item,
                        c.inventoryclass, c.invstatus,c.status,
                        c.lotnumber,c.uom);
    fetch curShippingPlateSumPicked into s1;
    if curShippingPlateSumPicked%found then
      p1.count := nvl(p1.count,0) + nvl(s1.count,0);
      p1.qty := nvl(p1.qty,0) + nvl(s1.qty,0);
      p1.weight := nvl(p1.weight,0) + nvl(s1.weight,0);
    end if;
    open curShippingPlateSumStaged(c.facility,c.custid,c.item,
                        c.inventoryclass, c.invstatus,c.status,
                        c.lotnumber,c.uom);
    fetch curShippingPlateSumStaged into s1;
    if curShippingPlateSumStaged%found then
      p1.count := nvl(p1.count,0) + nvl(s1.count,0);
      p1.qty := nvl(p1.qty,0) + nvl(s1.qty,0);
      p1.weight := nvl(p1.weight,0) + nvl(s1.weight,0);
    end if;
    open curShippingPlateSumLoaded(c.facility,c.custid,c.item,
                        c.inventoryclass, c.invstatus,c.status,
                        c.lotnumber,c.uom);
    fetch curShippingPlateSumLoaded into s1;
    if curShippingPlateSumLoaded%found then
      p1.count := nvl(p1.count,0) + nvl(s1.count,0);
      p1.qty := nvl(p1.qty,0) + nvl(s1.qty,0);
      p1.weight := nvl(p1.weight,0) + nvl(s1.weight,0);
    end if;
    if p1.count is null then
      notfound := True;
    end if;
  else
    p1 := null;
    open curPlateSumOne(c.facility,c.custid,c.item,
                        c.inventoryclass, c.invstatus,c.status,
                        c.lotnumber,c.uom);
    fetch curPlateSumOne into p1;
    if curPlateSumOne%notfound then
      notfound := True;
    end if;
  end if;
  if notfound = True then
    zut.prt('Detail not found: ');
    zut.prt(c.facility || ' ' ||
      c.custid || ' ' ||
      c.item || ' ' ||
      c.inventoryclass || ' ' ||
      c.invstatus || ' ' ||
      c.status || ' ' ||
      c.lotnumber || ' '||
      c.uom || ' ' ||
      c.count || ' ' ||
      c.qty);
    ntfcount := ntfcount + 1;
    if updflag = 'Y' then
      delete
        from custitemtot
       where facility = c.facility
         and custid = c.custid
         and item = c.item
         and inventoryclass = c.inventoryclass
         and invstatus = c.invstatus
         and status = c.status
         and lotnumber = c.lotnumber
         and uom = c.uom;
      commit;
    end if;
  else
    if (c.qty = p1.qty) and
       (c.count = p1.count) and
       (c.weight = p1.weight) then
      okycount := okycount + 1;
    else
      zut.prt('check qty ' || c.status || ' ' || c.qty || ' ' || p1.qty);
      if (c.qty != p1.qty) then
        zut.prt('Qty mismatch: ');
        zut.prt(c.facility || ' ' ||
          c.custid || ' ' ||
          c.item || ' ' ||
          c.inventoryclass || ' ' ||
          c.invstatus || ' ' ||
          c.status || ' ' ||
          c.lotnumber || ' ' ||
          c.uom || ' ' ||
          ' custitemtot: ' || c.qty ||
          ' plate: ' || p1.qty);
        qtycount := qtycount + 1;
        if updflag = 'Y' then
          update custitemtot
            set qty = p1.qty,
                lastuser = 'Audit',
                lastupdate = sysdate
          where facility = c.facility
            and custid = c.custid
            and item = c.item
            and inventoryclass = c.inventoryclass
            and invstatus = c.invstatus
            and status = c.status
            and lotnumber = c.lotnumber
            and uom = c.uom;
          commit;
        end if;
      end if;
      zut.prt('check weight ' || c.status || ' ' || c.weight || ' ' || p1.weight);
      if (c.weight != p1.weight) then
        zut.prt('Wgt mismatch: ');
        zut.prt(c.facility || ' ' ||
          c.custid || ' ' ||
          c.item || ' ' ||
          c.inventoryclass || ' ' ||
          c.invstatus || ' ' ||
          c.status || ' ' ||
          c.lotnumber || ' ' ||
          c.uom || ' ' ||
          ' custitemtot: ' || c.weight ||
          ' plate: ' || p1.weight);
        wgtcount := wgtcount + 1;
        if updflag = 'Y' then
          update custitemtot
            set weight = p1.weight,
                lastuser = 'Audit',
                lastupdate = sysdate
          where facility = c.facility
            and custid = c.custid
            and item = c.item
            and inventoryclass = c.inventoryclass
            and invstatus = c.invstatus
            and status = c.status
            and lotnumber = c.lotnumber
            and uom = c.uom;
          commit;
        end if;
      end if;
      zut.prt('check count ' || c.status || ' ' || c.count || ' ' || p1.count);
      if (c.count != p1.count) then
        zut.prt('Count mismatch: ');
        zut.prt(c.facility || ' ' ||
          c.custid || ' ' ||
          c.item || ' ' ||
          c.inventoryclass || ' ' ||
          c.invstatus || ' ' ||
          c.status || ' ' ||
          c.lotnumber || ' ' ||
          c.uom || ' ' ||
          ' custitemtot: ' ||
          c.count || ' plate: ' ||
          p1.count);
        dtlcount := dtlcount + 1;
        if updflag = 'Y' then
          update custitemtot
            set lipcount = p1.count,
                lastuser = 'Audit',
                lastupdate = sysdate
          where facility = c.facility
            and custid = c.custid
            and item = c.item
            and inventoryclass = c.inventoryclass
            and invstatus = c.invstatus
            and status = c.status
            and lotnumber = c.lotnumber
            and uom = c.uom;
          commit;
        end if;
      end if;
    end if;
  end if;
  if c.status = 'CM' then
    close curCommitmentsSumOne;
  elsif c.status = 'PN' then
    close curShippingPlateSumPicked;
    close curShippingPlateSumStaged;
    close curShippingPlateSumLoaded;
  else
    close curPlateSumOne;
  end if;

end loop;

zut.prt('totcount: ' || totcount);
zut.prt('okycount: ' || okycount);
zut.prt('ntfcount: ' || ntfcount);
zut.prt('qtycount: ' || qtycount);
zut.prt('dtlcount: ' || dtlcount);
zut.prt('dtlcount: ' || dtlcount);
zut.prt('wgtcount: ' || wgtcount);

zut.prt('end of custitemtot/plate audit');

exception when others then
  zut.prt(sqlerrm);
end;
/
exit;
