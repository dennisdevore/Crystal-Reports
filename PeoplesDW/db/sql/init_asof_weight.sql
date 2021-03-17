--
-- $Id$
--
declare
   cursor c_asof is
      select A.facility, A.custid, A.item, A.lotnumber, A.uom, A.invstatus,
             A.inventoryclass, A.rowid
         from asofinventory A
         where A.effdate =
               (select max(effdate) from asofinventory
                  where facility = A.facility
                    and custid = A.custid
                    and item = A.item
                    and nvl(lotnumber,'(none)') = nvl(A.lotnumber, '(none)')
                    and nvl(invstatus,'(none)') = nvl(A.invstatus, '(none)')
                    and nvl(inventoryclass,'(none)') = nvl(A.inventoryclass, '(none)'));

   cursor c_lp(p_facility varchar2, p_custid varchar2, p_item varchar2,
         p_lotnumber varchar2, p_uom varchar2, p_invstatus varchar2,
         p_inventoryclass varchar2) is
      select nvl(sum(weight), 0) as weight
         from plate
         where status not in ('P','D','I')
           and type = 'PA'
           and custid = p_custid
           and facility = p_facility
           and item = p_item
           and nvl(lotnumber,'(none)') = nvl(p_lotnumber,'(none)')
           and nvl(invstatus,'(none)') = nvl(p_invstatus,'(none)')
           and nvl(inventoryclass,'(none)') = nvl(p_inventoryclass,'(none)')
           and unitofmeasure = p_uom;
   lp c_lp%rowtype;

   cursor c_sp(p_facility varchar2, p_custid varchar2, p_item varchar2,
         p_lotnumber varchar2, p_uom varchar2, p_invstatus varchar2,
         p_inventoryclass varchar2) is
      select nvl(sum(weight), 0) as weight
         from shippingplate
         where status in ('L','P', 'S', 'FA')
           and type in ('F', 'P')
           and custid = p_custid
           and facility = p_facility
           and item = p_item
           and nvl(lotnumber,'(none)') = nvl(p_lotnumber,'(none)')
           and nvl(invstatus,'(none)') = nvl(p_invstatus,'(none)')
           and nvl(inventoryclass,'(none)') = nvl(p_inventoryclass,'(none)')
           and unitofmeasure = p_uom;
   sp c_sp%rowtype;
begin

   for a in c_asof loop
      open c_lp(a.facility, a.custid, a.item, a.lotnumber, a.uom,
            a.invstatus, a.inventoryclass);
      fetch c_lp into lp;
      close c_lp;

      open c_sp(a.facility, a.custid, a.item, a.lotnumber, a.uom,
            a.invstatus, a.inventoryclass);
      fetch c_sp into sp;
      close c_sp;

      update asofinventory
         set previousweight = 0,
             currentweight = lp.weight + sp.weight,
             lastuser = 'SYNAPSE',
             lastupdate = sysdate
         where rowid = a.rowid;
   end loop;
end;
/
exit;
