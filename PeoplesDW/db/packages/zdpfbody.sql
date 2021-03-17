create or replace package body alps.dynamicpickfront as
--
-- zdpfbody.sql
--


-- Public functions


function is_dynamicpf
   (in_facility in varchar2,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_locid    in varchar2)
return varchar2
is
   cursor c_pf(p_facility varchar2, p_locid varchar2, p_custid varchar2, p_item varchar2) is
      select dynamic
         from itempickfronts
         where facility = p_facility
           and pickfront = p_locid
           and custid = p_custid
           and item = p_item;
   pf c_pf%rowtype := null;
begin
   open c_pf(in_facility, in_locid, in_custid, in_item);
   fetch c_pf into pf;
   close c_pf;

   return nvl(pf.dynamic,'N');

exception
   when OTHERS then
      return 'N';
end is_dynamicpf;


function count_dynamicpfs
   (in_facility in varchar2,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_uom      in varchar2)
return number
is
   l_cnt pls_integer := 0;
begin
   select count(1) into l_cnt
      from itempickfronts
      where facility = in_facility
        and custid = in_custid
        and item = in_item
        and pickuom = in_uom
        and nvl(dynamic,'N') = 'Y';

   return l_cnt;

exception
   when OTHERS then
      return 0;
end count_dynamicpfs;


-- Public procedures


procedure process_lp_remove
   (in_facility in varchar2,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_locid    in varchar2)
is
   cursor c_pf(p_facility varchar2, p_locid varchar2, p_custid varchar2, p_item varchar2) is
      select pickuom, rowid
         from itempickfronts
         where facility = p_facility
           and pickfront = p_locid
           and custid = p_custid
           and item = p_item
           and nvl(dynamic,'N') = 'Y';
   pf c_pf%rowtype := null;
   l_cnt pls_integer;
   l_msg varchar2(255);
   l_qty number(9);
begin

   open c_pf(in_facility, in_locid, in_custid, in_item);
   fetch c_pf into pf;
   close c_pf;

   if pf.rowid is null then                  -- not a dynamic pickfront for item
      return;
   end if;

   select nvl(sum(nvl(quantity,0)),0) into l_qty
      from plate
      where facility = in_facility
        and location = in_locid
        and item = in_item
        and custid = in_custid;

   -- insure at least 1 pickuom remains at location
   if l_qty >= zlbl.uom_qty_conv(in_custid, in_item, 1, pf.pickuom,
         zci.baseuom(in_custid, in_item)) then
      return;
   end if;

   select count(1) into l_cnt
      from itempickfronts
      where facility = in_facility
        and custid = in_custid
        and item = in_item
        and pickuom = pf.pickuom;

   if l_cnt = 1 then                         -- only 1, update with a null location
      update itempickfronts
         set pickfront = null,
             lastuser = 'DynamicPF',
             lastupdate = sysdate
         where rowid = pf.rowid;
   else
      delete itempickfronts
         where rowid = pf.rowid;
   end if;

exception
   when OTHERS then
      zms.log_autonomous_msg('ProcLPRemove', null, null, sqlerrm, 'E', null, l_msg);
end process_lp_remove;


procedure build_dynamicpf
   (in_facility       in varchar2,
    in_custid         in varchar2,
    in_item           in varchar2,
    in_ar_rowid       in rowid,
    in_invstatus      in varchar2,
    in_inventoryclass in varchar2,
    in_lotnumber      in varchar2,
    in_wave           in number,
    out_pickfront     out varchar2)
is
   type cv_typ is ref cursor;
   l_cv cv_typ;
   cursor c_pf(p_facility varchar2, p_custid varchar2, p_item varchar2, p_uom varchar2) is
      select pickfront, nvl(replenishqty,0) as replenishqty, rowid,
             nvl(use_existing_lps,'N') as useexistinglps
         from itempickfronts
         where facility = p_facility
           and custid = p_custid
           and item = p_item
           and pickuom = p_uom
           and nvl(dynamic,'N') = 'Y'
         order by pickfront desc;      -- so null (if any) comes first
   pf c_pf%rowtype := null;

   cursor c_ar is
     select uom,
            pickingzone,
            nvl(lifofifo,'F') as lifofifo,
            nvl(datetype,'M') as datetype,
            nvl(picktoclean,'N') as picktoclean,
            nvl(pickfrontfifo,'N') as pickfrontfifo
       from allocrulesdtl
      where rowid = in_ar_rowid;
   ar c_ar%rowtype := null;

   l_sql varchar2(2048);
   l_qty plate.quantity%type;
   l_mindate date;
   l_maxdate date;
   l_msg varchar2(255);

begin
   out_pickfront := null;

   ar := null;
   open c_ar;
   fetch c_ar into ar;
   close c_ar;

   if ar.pickfrontfifo is null then            -- allocation rule not found
      return;
   end if;

   pf := null;
   open c_pf(in_facility, in_custid, in_item, ar.uom);
   fetch c_pf into pf;
   close c_pf;

   if pf.rowid is null then            -- no dynamic pickfronts for item
      return;
   end if;

   l_sql := 'select * from (';

   l_sql := l_sql || 'select P.location, sum(P.quantity), min(';

   if ar.datetype = 'M' then
      l_sql := l_sql || 'manufacturedate';
   elsif ar.datetype = 'E' then
      l_sql := l_sql || 'expirationdate';
   else
      l_sql := l_sql || 'least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate)))';
   end if;

   l_sql := l_sql || '), max(';

   if ar.datetype = 'M' then
      l_sql := l_sql || 'manufacturedate';
   elsif ar.datetype = 'E' then
      l_sql := l_sql || 'expirationdate';
   else
      l_sql := l_sql || 'least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate)))';
   end if;

   l_sql := l_sql || ')' ||
               ' from plate P, location L' ||
               ' where P.facility = ''' || in_facility || '''' ||
                 ' and P.custid = ''' || in_custid || '''' ||
                 ' and P.item = ''' || in_item || '''';

   if in_invstatus is not null then
      l_sql := l_sql || ' and P.invstatus = ''' || in_invstatus || '''';
   end if;

   if in_inventoryclass is not null then
      l_sql := l_sql || ' and P.inventoryclass = ''' || in_inventoryclass || '''';
   end if;

   if nvl(in_lotnumber,'(none)') <> '(none)' then
      l_sql := l_sql || ' and P.lotnumber = ''' || in_lotnumber || '''';
   end if;

   l_sql := l_sql || ' and L.facility = P.facility' ||
                 ' and L.locid = P.location' ||
                 ' and L.loctype = ''STO''' ||
                 ' and L.status != ''O''' ||
                 ' and not exists (select 1 from itempickfronts' ||
                        ' where facility = P.facility' ||
                          ' and pickfront = P.location' ||
                          ' and custid = P.custid' ||
                          ' and item = P.item)' ||
                 ' and not exists (select 1 from plate' ||
                        ' where facility = P.facility' ||
                          ' and custid = P.custid' ||
                          ' and item = P.item' ||
                          ' and location = P.location' ||
                          ' and (invstatus != P.invstatus' ||
                            ' or inventoryclass != P.inventoryclass))';

   if ar.pickingzone is not null then
      l_sql := l_sql || ' and L.pickingzone = ''' || ar.pickingzone || '''';
   end if;

   l_qty := zlbl.uom_qty_conv(in_custid, in_item, pf.replenishqty, ar.uom,
         zci.baseuom(in_custid, in_item));
   l_sql := l_sql || ' group by P.location,P.facility,P.custid,P.item';
   if nvl(in_lotnumber,'(none)') <> '(none)' then
      l_sql := l_sql || ',P.lotnumber';
   end if;

   l_sql := l_sql || ' having sum(P.quantity) >= ' || l_qty ||
                     ' ) PL ' ||
                        ' where zwave.total_at_loc(''' || in_facility || ''', PL.location, ''' || in_custid || ''', ''' || in_item || ''', ''' || in_lotnumber || ''', ''' || in_invstatus || ''', ''' || in_inventoryclass || ''')' ||
                        ' >= zwave.tasked_at_loc(''' || in_facility || ''', PL.location, ''' || in_custid || ''', ''' || in_item || ''', ' || in_wave || ', ''' || in_lotnumber || ''')';

   if ar.pickfrontfifo = 'N' then
     l_sql := l_sql || ' order by 3';
   else
     if ar.LifoFifo = 'L' then
       l_sql := l_sql || ' order by 4 desc';
     else
       l_sql := l_sql || ' order by 3';
     end if;
     
     l_sql := l_sql || ', zwv.total_at_loc(''' || in_facility || ''', PL.location, ''' || in_custid || ''', ''' || in_item || ''', ''' || in_lotnumber || ''', ''' || in_invstatus || ''', ''' || in_inventoryclass || ''')' ||
                       ' - zwv.tasked_at_loc(''' || in_facility || ''', PL.location, ''' || in_custid || ''', ''' || in_item || ''', ' || in_wave || ', ''' || in_lotnumber || ''')';

     if (ar.picktoclean <> 'Y') then
       l_sql := l_sql || ' desc';
     end if;
   end if;
   

   open l_cv for l_sql;
   fetch l_cv into out_pickfront, l_qty, l_mindate, l_maxdate;
   if l_cv%notfound then
      out_pickfront := null;
   end if;
   close l_cv;

   if out_pickfront is null then
      return;
   end if;

   if pf.pickfront is null then
      update itempickfronts
         set pickfront = out_pickfront,
             lastuser = 'DynamicPF',
             lastupdate = sysdate
         where rowid = pf.rowid;
   else
      insert into itempickfronts
         (custid, item, facility, pickfront, pickuom,
          replenishqty, lastuser, lastupdate, dynamic, use_existing_lps)
      values
         (in_custid, in_item, in_facility, out_pickfront, ar.uom,
          pf.replenishqty, 'DynamicPF', sysdate, 'Y', pf.useexistinglps);
   end if;

exception
   when OTHERS then
      zms.log_autonomous_msg('BldDynamicPF', null, null, sqlerrm, 'E', null, l_msg);
end build_dynamicpf;


procedure verify_pickfront
   (in_facility  in varchar2,
    in_pickfront in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_uom       in varchar2,
    in_dynamic   in varchar2,
    out_msg      out varchar2)
is
   l_cnt pls_integer;
begin
   out_msg := 'OKAY';

   if in_dynamic = 'Y' then

      if in_pickfront is not null then
         select count(1) into l_cnt
            from plate
            where facility = in_facility
              and location = in_pickfront
              and custid = in_custid
              and item = in_item;
         if l_cnt = 0 then
            out_msg := 'Pick Front must contain the item if is to be System Generated';
            return;
         end if;
      end if;

      if in_pickfront is not null then
         select count(1) into l_cnt
            from itempickfronts
            where facility = in_facility
              and custid = in_custid
              and item = in_item
              and pickuom = in_uom
              and nvl(dynamic,'N') = 'N'
              and pickfront != in_pickfront;
      else
         select count(1) into l_cnt
            from itempickfronts
            where facility = in_facility
              and custid = in_custid
              and item = in_item
              and pickuom = in_uom
              and nvl(dynamic,'N') = 'N';
      end if;
      if l_cnt != 0 then
         out_msg := 'Item has non-System Generated pick fronts for the same Pick UOM';
         return;
      end if;
   else
      select count(1) into l_cnt
         from itempickfronts
         where facility = in_facility
           and custid = in_custid
           and item = in_item
           and pickuom = in_uom
           and nvl(dynamic,'N') = 'Y'
           and pickfront != in_pickfront;
      if l_cnt != 0 then
         out_msg := 'Item has System Generated pick fronts for the same Pick UOM';
         return;
      end if;
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end verify_pickfront;


end dynamicpickfront;
/

show errors package body dynamicpickfront;
exit;
