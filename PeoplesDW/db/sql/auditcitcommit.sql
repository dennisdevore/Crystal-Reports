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
updflag varchar2(1);
out_msg varchar2(255);

cursor curCommitSumAll is
  select nvl(facility,'x') as facility,
         nvl(custid,'x') as custid,
         nvl(item,'x') as item,
         nvl(inventoryclass,'RG') as inventoryclass,
         nvl(invstatus,'x') as invstatus,
         nvl(status,'x') as status,
         nvl(lotnumber,'(none)') as lotnumber,
         nvl(uom,'x') as uom,
         count(1) as count,
         nvl(sum(qty),0) as qty
    from commitments
   group by facility, custid, item,
            inventoryclass, invstatus, status,
            lotnumber, uom
   order by facility, custid, item,
            inventoryclass, invstatus, status,
            lotnumber, uom;

cursor curCustitemtotOne
  (in_facility varchar2
  ,in_custid varchar2
  ,in_item varchar2
  ,in_inventoryclass varchar2
  ,in_invstatus varchar2
  ,in_status varchar2
  ,in_lotnumber varchar2
  ,in_uom varchar2) is
  select facility,
         custid,
         item,
         inventoryclass,
         invstatus,
         status,
         lotnumber,
         uom,
         nvl(lipcount,0) as count,
         nvl(qty,0) as qty
    from custitemtot
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and inventoryclass = in_inventoryclass
     and invstatus = in_invstatus
     and status = in_status
     and lotnumber = in_lotnumber
     and uom = in_uom;
c1 curCustitemtotOne%rowtype;


begin

updflag := upper('&&1');
totcount := 0;
okycount := 0;
ntfcount := 0;
qtycount := 0;
dtlcount := 0;

zut.prt('Comparing commitment summary to custitemtot...');
for p in curCommitSumAll
loop
  totcount := totcount + 1;
  open curCustitemtotOne(p.facility,p.custid,p.item,
                         p.inventoryclass,p.invstatus,p.status,
                         p.lotnumber,p.uom);
  fetch curCustitemtotOne into c1;
  if curCustitemtotOne%notfound then
    zut.prt('Custitemtot not found: ');
    zut.prt(p.facility || ' ' ||
      p.custid || ' ' ||
      p.item || ' ' ||
      p.inventoryclass || ' ' ||
      p.invstatus || ' ' ||
      p.lotnumber || ' ' ||
      p.status || ' ' ||
      p.uom || ' ' ||
      p.count || ' ' ||
      p.qty);
    ntfcount := ntfcount + 1;
    if updflag = 'Y' then
      insert into custitemtot
        (facility, custid, item,
         lotnumber, inventoryclass, uom,
         invstatus, status, lipcount, qty,
         lastuser, lastupdate)
      values
        (p.facility, p.custid, p.item,
         p.lotnumber, p.inventoryclass, p.uom,
         p.invstatus, p.status, p.count, p.qty,
         'Audit', sysdate);
      commit;
    end if;
  else
    if (p.qty = c1.qty) and
       (p.count = c1.count) then
      okycount := okycount + 1;
    else
      if (p.qty != c1.qty) then
        zut.prt('Qty mismatch: ');
        zut.prt(p.facility || ' ' ||
          p.custid || ' ' ||
          p.item || ' ' ||
          p.inventoryclass || ' ' ||
          p.invstatus || ' ' ||
          p.status || ' ' ||
          p.lotnumber || ' ' ||
          p.uom || ' ' ||
          ' plate: ' || p.qty ||
          ' custitemtot: ' || c1.qty);
        qtycount := qtycount + 1;
        if updflag = 'Y' then
          update custitemtot
             set qty = p.qty,
                 lastuser = 'Audit',
                 lastupdate = sysdate
           where facility = p.facility
             and custid = p.custid
             and item = p.item
             and inventoryclass = p.inventoryclass
             and invstatus = p.invstatus
             and status = p.status
             and lotnumber = p.lotnumber
             and uom = p.uom;
          commit;
        end if;
      end if;
      if (p.count != c1.count) then
        zut.prt('Count mismatch: ');
        zut.prt(p.facility || ' ' ||
          p.custid || ' ' ||
          p.item || ' ' ||
          p.inventoryclass || ' ' ||
          p.invstatus || ' ' ||
          p.status || ' ' ||
          p.lotnumber || ' ' ||
          p.uom || ' ' ||
          ' plate: ' || p.count ||
          ' custitemtot: ' || c1.count);
        dtlcount := dtlcount + 1;
        if updflag = 'Y' then
          update custitemtot
             set lipcount = p.count,
                 lastuser = 'Audit',
                 lastupdate = sysdate
           where facility = p.facility
             and custid = p.custid
             and item = p.item
             and inventoryclass = p.inventoryclass
             and invstatus = p.invstatus
             and status = p.status
             and lotnumber = p.lotnumber
             and uom = p.uom;
          commit;
        end if;
      end if;
    end if;
  end if;
  close curCustitemtotOne;

end loop;

zut.prt('totcount: ' || totcount);
zut.prt('okycount: ' || okycount);
zut.prt('ntfcount: ' || ntfcount);
zut.prt('qtycount: ' || qtycount);
zut.prt('dtlcount: ' || dtlcount);


zut.prt('end of custitemtot/plate audit');

exception when others then
  zut.prt(sqlerrm);
end;
/
exit;
