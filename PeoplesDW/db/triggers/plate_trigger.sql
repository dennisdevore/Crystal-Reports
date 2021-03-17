create or replace trigger plate_au_all
after update
on plate
declare
l_adj1 varchar2(20);
l_adj2 varchar2(20);
l_controlnumber varchar2(10);
errno number;
errmsg varchar2(255);

begin
    for crec in (select * from plateinvstatuschange)
    loop
        --zut.prt('Have change for lpid:'||crec.lpid
        --    ||'/'||crec.newstatus
        --    ||'/'||crec.adjreason
        --    ||'/'||crec.tasktype
        --    ||'/'||crec.lastuser);

        zia.change_invstatus
            (crec.lpid,crec.newstatus, crec.adjreason,crec.tasktype,
             crec.lastuser,
             l_adj1, l_adj2, l_controlnumber, errno, errmsg,'Y');

        if nvl(errno,0) != 0 then
            null;
        --    zut.prt('Err:'||errno||'/'||errmsg);
        end if;

    end loop;

    for crec in (select * from locinvstatuschange)
    loop
--        zut.prt('Have loc invstatus change for lpid:'||crec.lpid
--            ||'/'||crec.invstatus
--            ||'/'||crec.adjreason
--            ||'/'||crec.tasktype
--            ||'/'||crec.lastuser);

        zia.loc_invstatus_change
            (crec.lpid,crec.custid,crec.item,crec.baseuom,crec.qty,
             crec.weight,crec.facility,crec.invstatus,
             crec.adjreason,crec.tasktype,crec.businessevent,crec.lastuser);

    end loop;

    for crec in (select distinct * from dynamicpf_temp)
    loop
      zdpf.process_lp_remove(crec.facility, crec.custid, crec.item, crec.locid);
    end loop;

end;
/


create or replace trigger plate_ad_all
after delete
on plate
declare
begin
    for crec in (select distinct * from dynamicpf_temp)
    loop
      zdpf.process_lp_remove(crec.facility, crec.custid, crec.item, crec.locid);
    end loop;

end;
/


create or replace trigger plate_bu
--
-- $Id$
--
before update
on plate
for each row
declare
  CURSOR C_LD(in_loadno number)
  IS
    SELECT rcvddate
      FROM loads
     WHERE loadno = in_loadno;
LD C_LD%rowtype;

begin
   if ((updating('facility') or updating('location'))
   and (:new.facility = :new.destfacility)
   and (:new.location = :new.destlocation)) then
      :new.destfacility := null;
      :new.destlocation := null;
      update location
         set dropcount = nvl(dropcount, 0) + 1
         where facility = :new.facility
           and locid = :new.location;
   end if;
   if :new.type = 'PA' and :new.anvdate is null then
        if nvl(:new.loadno,0) = 0 then
            :new.anvdate := trunc(:new.creationdate);
        else
            LD := null;
            OPEN C_LD(:new.loadno);
            FETCH C_LD into LD;
            CLOSE C_LD;
            :new.anvdate := trunc(nvl(LD.rcvddate,:NEW.creationdate));
        end if; 
   end if;
end;
/


create or replace trigger plate_bi
--
-- $Id$
--
before insert
on plate
for each row
declare
  CURSOR C_LD(in_loadno number)
  IS
    SELECT rcvddate
      FROM loads
     WHERE loadno = in_loadno;
LD C_LD%rowtype;

begin
   if :new.type = 'PA' and :new.anvdate is null then
        if nvl(:new.loadno,0) = 0 then
            :new.anvdate := trunc(:new.creationdate);
        else
            LD := null;
            OPEN C_LD(:new.loadno);
            FETCH C_LD into LD;
            CLOSE C_LD;
            :new.anvdate := trunc(nvl(LD.rcvddate,:NEW.creationdate));
        end if; 
   end if;
end;
/


create or replace trigger plate_aiud
--
-- $Id$
--
after insert or update or delete
on plate
for each row
declare
userid varchar2(12);
lipcount number(15);
cntPickFront integer;
iskit char(1);
numJob number(16);
chgdate date;
cntRows integer;
l_locstatuschg_loctype customer_aux.locstatuschg_loctype%type;
l_locstatuschg_entry_invstatus customer_aux.locstatuschg_entry_invstatus%type;
l_locstatuschg_entry_adjreason customer_aux.locstatuschg_entry_adjreason%type;
l_locstatuschg_exit_invstatus customer_aux.locstatuschg_exit_invstatus%type;
l_locstatuschg_exit_adjreason customer_aux.locstatuschg_exit_adjreason%type;
l_locstatuschg_exclude_tsktyps customer_aux.locstatuschg_exclude_tasktypes%type;
l_loctype location.loctype%type;

CURSOR C_CISC(in_custid varchar2, in_status varchar2, in_location varchar2, in_facility varchar2)
IS
  SELECT C.*
    FROM location L, custinvstatuschange C
   WHERE C.custid = in_custid
     AND C.fromstatus = in_status
     AND L.locid = in_location
     AND L.facility = in_facility
     AND C.loctype = L.loctype;
begin
   if (inserting) then
      if (:new.type = 'PA') then
         if ((:new.facility is not null) and (:new.location is not null)) then
            update location
               set lpcount = nvl(lpcount, 0) + 1,
                   stackheight = decode(nvl(lpcount, 0), 0,
                     zci.item_stackheight(:new.custid,:new.item), stackheight),
                   used_uos = null
               where facility = :new.facility
                 and locid = :new.location;
         end if;

         if ((:new.destfacility is not null) and (:new.destlocation is not null)) then
            update location
               set lpcount = nvl(lpcount, 0) + 1,
                   stackheight = decode(nvl(lpcount, 0), 0,
                     zci.item_stackheight(:new.custid,:new.item), stackheight),
                   used_uos = null
               where facility = :new.destfacility
                 and locid = :new.destlocation;
         end if;
      end if;


   end if;

   if ( (deleting) or
      ( (updating) and
        ((nvl(:old.quantity,0) != nvl(:new.quantity,0)) or
         (nvl(:old.weight,0) != nvl(:new.weight,0)) or
         (nvl(:old.facility,'x') != nvl(:new.facility,'x')) or
         (nvl(:old.custid,'x') != nvl(:new.custid,'x')) or
         (nvl(:old.item,'x') != nvl(:new.item,'x')) or
         (nvl(:old.inventoryclass,'RG') != nvl(:new.inventoryclass,'RG')) or
         (nvl(:old.invstatus,'x') != nvl(:new.invstatus,'x')) or
         (nvl(:old.status,'x') != nvl(:new.status,'x')) or
         (nvl(:old.lotnumber,'(none)') != nvl(:new.lotnumber,'(none)')) or
         (nvl(:old.unitofmeasure,'x') != nvl(:new.unitofmeasure,'x'))) ) ) and
      (:old.type = 'PA') then
      if (deleting) then
        userid := :old.lastuser;
      else
        userid := :new.lastuser;
      end if;
      begin
        select lipcount
          into lipcount
          from custitemtot
         where facility = nvl(:old.facility,'x')
           and custid = nvl(:old.custid,'x')
           and item = nvl(:old.item,'x')
           and inventoryclass = nvl(:old.inventoryclass,'RG')
           and invstatus = nvl(:old.invstatus,'x')
           and status = nvl(:old.status,'x')
           and lotnumber = nvl(:old.lotnumber,'(none)')
           and uom = nvl(:old.unitofmeasure,'x');
      exception when no_data_found then
        lipcount := -1;
      end;
      if lipcount = 1 then
        delete
          from custitemtot
         where facility = nvl(:old.facility,'x')
           and custid = nvl(:old.custid,'x')
           and item = nvl(:old.item,'x')
           and inventoryclass = nvl(:old.inventoryclass,'RG')
           and invstatus = nvl(:old.invstatus,'x')
           and status = nvl(:old.status,'x')
           and lotnumber = nvl(:old.lotnumber,'(none)')
           and uom = nvl(:old.unitofmeasure,'x');
      elsif lipcount <> -1 then
        update custitemtot
           set lipcount = lipcount - 1,
               qty = qty - nvl(:old.quantity,0),
               weight = nvl(weight,0) - nvl(:old.weight,0),
               lastuser = userid,
               lastupdate = sysdate
         where facility = nvl(:old.facility,'x')
           and custid = nvl(:old.custid,'x')
           and item = nvl(:old.item,'x')
           and inventoryclass = nvl(:old.inventoryclass,'RG')
           and invstatus = nvl(:old.invstatus,'x')
           and status = nvl(:old.status,'x')
           and lotnumber = nvl(:old.lotnumber,'(none)')
           and uom = nvl(:old.unitofmeasure,'x');
      end if;
   end if;

   if ( (inserting) or
      ( (updating) and
        ((nvl(:old.quantity,0) != nvl(:new.quantity,0)) or
         (nvl(:old.weight,0) != nvl(:new.weight,0)) or		
         (nvl(:old.facility,'x') != nvl(:new.facility,'x')) or
         (nvl(:old.custid,'x') != nvl(:new.custid,'x')) or
         (nvl(:old.item,'x') != nvl(:new.item,'x')) or
         (nvl(:old.inventoryclass,'RG') != nvl(:new.inventoryclass,'RG')) or
         (nvl(:old.invstatus,'x') != nvl(:new.invstatus,'x')) or
         (nvl(:old.status,'x') != nvl(:new.status,'x')) or
         (nvl(:old.lotnumber,'(none)') != nvl(:new.lotnumber,'(none)')) or
         (nvl(:old.unitofmeasure,'x') != nvl(:new.unitofmeasure,'x'))) ) ) and
      (:new.type = 'PA') then
      update custitemtot
         set lipcount = lipcount + 1,
             qty = qty + nvl(:new.quantity,0),
             weight = nvl(weight,0) + nvl(:new.weight,0),
             lastuser = :new.lastuser,
             lastupdate = sysdate
       where facility = nvl(:new.facility,'x')
         and custid = nvl(:new.custid,'x')
         and item = nvl(:new.item,'x')
         and inventoryclass = nvl(:new.inventoryclass,'RG')
         and invstatus = nvl(:new.invstatus,'x')
         and status = nvl(:new.status,'x')
         and lotnumber = nvl(:new.lotnumber,'(none)')
         and uom = nvl(:new.unitofmeasure,'x');
      if sql%rowcount = 0 then
        insert into custitemtot
             (facility, custid, item,
              lotnumber, inventoryclass,
              uom, invstatus, status,
              lipcount, qty,
              lastuser, lastupdate, weight)
        values
             (nvl(:new.facility,'x'), nvl(:new.custid,'x'), nvl(:new.item,'x'),
              nvl(:new.lotnumber,'(none)'), nvl(:new.inventoryclass,'RG'),
              nvl(:new.unitofmeasure,'x'), nvl(:new.invstatus,'x'), nvl(:new.status,'x'),
              1, nvl(:new.quantity,0),
              :new.lastuser, sysdate, nvl(:new.weight,0));
      end if;
   end if;

   if (deleting and :old.type = 'PA') then
      if ((:old.facility is not null) and (:old.location is not null)) then
         update location
            set lpcount = nvl(lpcount, 0) - 1,
                stackheight = decode(nvl(lpcount, 0), 1, 0, stackheight),
                used_uos = null
            where facility = :old.facility
              and locid = :old.location
              and lpcount > 0;
      end if;

      if ((:old.destfacility is not null) and (:old.destlocation is not null)) then
         update location
            set lpcount = nvl(lpcount, 0) - 1,
                stackheight = decode(nvl(lpcount, 0), 1, 0, stackheight),
                used_uos = null
            where facility = :old.destfacility
              and locid = :old.destlocation
              and lpcount > 0;
      end if;
   end if;

   chgdate := sysdate;
   if (updating
   and ((nvl(:old.lpid, 'x') != nvl(:new.lpid, 'x'))
    or  (nvl(:old.item, 'x') != nvl(:new.item, 'x'))
    or  (nvl(:old.custid, 'x') != nvl(:new.custid, 'x'))
    or  (nvl(:old.facility, 'x') != nvl(:new.facility, 'x'))
    or  (nvl(:old.location, 'x') != nvl(:new.location, 'x'))
    or  (nvl(:old.status, 'x') != nvl(:new.status, 'x'))
    or  (nvl(:old.holdreason, 'x') != nvl(:new.holdreason, 'x'))
    or  (nvl(:old.unitofmeasure, 'x') != nvl(:new.unitofmeasure, 'x'))
    or  (nvl(:old.quantity, 0) != nvl(:new.quantity, 0))
    or  (nvl(:old.type, 'x') != nvl(:new.type, 'x'))
    or  (nvl(:old.serialnumber, 'x') != nvl(:new.serialnumber, 'x'))
    or  (nvl(:old.lotnumber, '(none)') != nvl(:new.lotnumber, '(none)'))
    or  (nvl(:old.manufacturedate, chgdate) != nvl(:new.manufacturedate, chgdate))
    or  (nvl(:old.expirationdate, chgdate) != nvl(:new.expirationdate, chgdate))
    or  (nvl(:old.expiryaction, 'x') != nvl(:new.expiryaction, 'x'))
    or  (nvl(:old.po, 'x') != nvl(:new.po, 'x'))
    or  (nvl(:old.recmethod, 'x') != nvl(:new.recmethod, 'x'))
    or  (nvl(:old.condition, 'x') != nvl(:new.condition, 'x'))
    or  (nvl(:old.lastoperator, 'x') != nvl(:new.lastoperator, 'x'))
    or  (nvl(:old.lasttask, 'x') != nvl(:new.lasttask, 'x'))
    or  (nvl(:old.countryof, 'x') != nvl(:new.countryof, 'x'))
    or  (nvl(:old.parentlpid, 'x') != nvl(:new.parentlpid, 'x'))
    or  (nvl(:old.useritem1, 'x') != nvl(:new.useritem1, 'x'))
    or  (nvl(:old.useritem2, 'x') != nvl(:new.useritem2, 'x'))
    or  (nvl(:old.useritem3, 'x') != nvl(:new.useritem3, 'x'))
    or  (nvl(:old.disposition, 'x') != nvl(:new.disposition, 'x'))
    or  (nvl(:old.lastuser, 'x') != nvl(:new.lastuser, 'x'))
    or  (nvl(:old.invstatus, 'x') != nvl(:new.invstatus, 'x'))
    or  (nvl(:old.qtyentered, 0) != nvl(:new.qtyentered, 0))
    or  (nvl(:old.itementered, 'x') != nvl(:new.itementered, 'x'))
    or  (nvl(:old.uomentered, 'x') != nvl(:new.uomentered, 'x'))
    or  (nvl(:old.inventoryclass, 'x') != nvl(:new.inventoryclass, 'x'))
    or  (nvl(:old.weight, 0) != nvl(:new.weight, 0))
    or  (nvl(:old.length, 0) != nvl(:new.length, 0))
    or  (nvl(:old.width, 0) != nvl(:new.width, 0))
    or  (nvl(:old.height, 0) != nvl(:new.height, 0))
    or  (nvl(:old.pallet_weight, 0) != nvl(:new.pallet_weight, 0))
    or  (nvl(:old.adjreason, 'x') != nvl(:new.adjreason, 'x'))
    or  (nvl(:old.anvdate, chgdate) != nvl(:new.anvdate, chgdate))
    or  (nvl(:old.qtytasked, 0) != nvl(:new.qtytasked, 0))))
   then
      insert into platehistory
         (lpid, item, custid, facility,
          location, status, holdreason, unitofmeasure,
          quantity, type, serialnumber, lotnumber,
          manufacturedate, expirationdate, expiryaction, po,
          recmethod, condition, lastoperator, lasttask,
          countryof, parentlpid, useritem1, useritem2,
          useritem3, disposition, lastuser, lastupdate,
          whenoccurred, invstatus, qtyentered, itementered,
          uomentered, inventoryclass, adjreason, weight, anvdate,
          qtytasked, length, width, height, pallet_weight)
      values
         (:old.lpid, :old.item, :old.custid, :old.facility,
          :old.location, :old.status, :old.holdreason, :old.unitofmeasure,
          :old.quantity, :old.type, :old.serialnumber, :old.lotnumber,
          :old.manufacturedate, :old.expirationdate, :old.expiryaction, :old.po,
          :old.recmethod, :old.condition, :old.lastoperator, :old.lasttask,
          :old.countryof, :old.parentlpid, :old.useritem1, :old.useritem2,
          :old.useritem3, :old.disposition, :old.lastuser, :old.lastupdate,
          sysdate, :old.invstatus, :old.qtyentered, :old.itementered,
          :old.uomentered, :old.inventoryclass, :old.adjreason, :old.weight,
          :old.anvdate, :old.qtytasked, :old.length, :old.width, :old.height, :old.pallet_weight);
   end if;

   if (updating('facility') or updating('location')
   or  updating('qtyentered') or updating('uomentered')) then
      if ((nvl(:old.qtyentered, 0) != 0) and (:old.uomentered is not null)
      and (:old.facility is not null) and (:old.location is not null)
      and (:old.type = 'PA')) then
         update location
            set lpcount = nvl(lpcount, 0) - 1,
                stackheight = decode(nvl(lpcount, 0), 1, 0, stackheight),
                used_uos = null
            where facility = :old.facility
              and locid = :old.location
              and lpcount > 0;
      end if;

      if ((nvl(:new.qtyentered, 0) != 0) and (:new.uomentered is not null)
      and (:new.facility is not null) and (:new.location is not null)
      and (:new.type = 'PA')) then
         update location
            set lpcount = nvl(lpcount, 0) + 1,
                stackheight = decode(nvl(lpcount, 0), 0,
                  zci.item_stackheight(:new.custid,:new.item), stackheight),
                used_uos = null
            where facility = :new.facility
              and locid = :new.location;
      end if;
   end if;

   if (updating('destfacility') or updating('destlocation')
   or  updating('facility') or updating('location')) then
      if ((:old.destfacility is not null) and (:old.destlocation is not null)
      and (:old.type ='PA')) then
         update location
            set lpcount = nvl(lpcount, 0) - 1,
                stackheight = decode(nvl(lpcount, 0), 1, 0, stackheight),
                used_uos = null
            where facility = :old.destfacility
              and locid = :old.destlocation
              and lpcount > 0;
      end if;

      if ((:new.destfacility is not null) and (:new.destlocation is not null)
      and (:new.type = 'PA')) then
         update location
            set lpcount = nvl(lpcount, 0) + 1,
                stackheight = decode(nvl(lpcount, 0), 0,
                  zci.item_stackheight(:new.custid,:new.item), stackheight)
            where facility = :new.destfacility
              and locid = :new.destlocation;
      end if;
   end if;

   if (updating) and
      (:old.type = 'PA') and
      ( ((:new.quantity < :old.quantity) and
         (:old.status = 'A' and :new.status = 'A')) or
        (:old.status = 'A' and :new.status = 'P') or
        ((:old.location != :new.location) and
         (:old.status = 'A' and :new.status = 'A')) ) then
     begin
       cntPickFront := 0;
       select count(1)
         into cntPickFront
         from (
         select 1
           from itempickfronts
          where facility = :old.facility
            and custid = :old.custid
            and item = :old.item
            and pickfront = :old.location
            and nvl(dynamic, 'N') = 'N'
         union all
         select 1
           from location
          where facility = :old.facility
            and locid = :old.location
            and nvl(flex_pick_front_wave,0) != 0
            and flex_pick_front_item = :old.item);
     exception when others then
       null;
     end;
     if cntPickFront != 0 then
      begin
        dbms_job.submit(numJob,'zrpl.submit_replenish_request(''REPLPP'',''' ||
          :old.facility || ''',''' || :old.custid || ''',''' || :old.item ||
          ''',''' || :old.location || ''',''' || :new.lastuser ||
          ''', ''N'');',
          sysdate + .00005887, null, null);
      exception when others then
        null;
      end;
     else
       begin
         select iskit
           into iskit
           from custitemview
          where custid = :old.custid
            and item = :old.item;
       exception when others then
         null;
       end;
       if iskit = 'K' then -- made-to-stock kit
         begin
           select count(1)
             into cntRows
             from custitemminmax
            where custid = :old.custid
              and item = :old.item
              and facility = :old.facility;
           if cntRows <> 0 then
             dbms_job.submit(numJob,'zrpl.submit_replenish_request(''REPLPP'',''' ||
               :old.facility || ''',''' || :old.custid || ''',''' || :old.item ||
               ''',''' || :old.location || ''',''' || :new.lastuser ||
               ''', ''N'');',
               sysdate + .00005887, null, null);
           end if;
         exception when others then
           null;
         end;
       end if;
     end if;
   end if;

  
  if (updating) and (:old.type = 'PA') and
     (nvl(:old.location,'xx') != nvl(:new.location,'xx') or
      nvl(:old.facility,'xx') != nvl(:new.facility,'xx')) then
    for CISC in C_CISC(:new.custid, :new.invstatus, :new.location, :new.facility) loop
        if CISC.tasktypes is null or
           nvl(instr(CISC.tasktypes,:new.lasttask),0) > 0 then
           insert into plateinvstatuschange values(:new.lpid, CISC.tostatus,
                    CISC.adjreason, :new.lasttask, :new.lastuser);
        end if;

    end loop;
    begin
      select locstatuschg_loctype,
             locstatuschg_exit_invstatus, locstatuschg_exit_adjreason,
             locstatuschg_exclude_tasktypes
        into l_locstatuschg_loctype,
             l_locstatuschg_exit_invstatus, l_locstatuschg_exit_adjreason,
             l_locstatuschg_exclude_tsktyps
        from custitemview
       where custid = :old.custid
         and item = :old.item;
    exception when others then
      l_locstatuschg_loctype := null;
    end;
    if (l_locstatuschg_loctype is not null) and
       (nvl(instr(l_locstatuschg_exclude_tsktyps,:new.lasttask),0) = 0) then
      begin
        select loctype
          into l_loctype
          from location
         where facility = :old.facility
           and locid = :old.location;
      exception when others then
        l_loctype := null;
      end;
      if (l_loctype = l_locstatuschg_loctype) and
         (l_locstatuschg_exit_invstatus != :new.invstatus) and
         (l_locstatuschg_exit_adjreason is not null) then
        insert into locinvstatuschange
          values
           (:old.lpid,:old.custid,:old.item,:old.lotnumber,:old.unitofmeasure,          
           :old.quantity,:old.weight,:old.facility,l_locstatuschg_exit_invstatus,
           l_locstatuschg_exit_adjreason,:new.lasttask,'EXIT',:new.lastuser);
   end if;
    end if;
    begin
      select locstatuschg_loctype,
             locstatuschg_entry_invstatus, locstatuschg_entry_adjreason,
             locstatuschg_exclude_tasktypes
        into l_locstatuschg_loctype,
             l_locstatuschg_entry_invstatus, l_locstatuschg_entry_adjreason,
             l_locstatuschg_exclude_tsktyps
        from custitemview
       where custid = :new.custid
         and item = :new.item;
    exception when others then
      l_locstatuschg_loctype := null;
    end;
    if (l_locstatuschg_loctype is not null) and
       (nvl(instr(l_locstatuschg_exclude_tsktyps,:new.lasttask),0) = 0) then
      begin
        select loctype
          into l_loctype
          from location
         where facility = :new.facility
           and locid = :new.location;
      exception when others then
        l_loctype := null;
      end;
      if (l_loctype = l_locstatuschg_loctype) and
         (l_locstatuschg_entry_invstatus != :new.invstatus) and
         (l_locstatuschg_entry_adjreason is not null) then
        insert into locinvstatuschange
          values
          (:new.lpid,:new.custid,:new.item,:new.lotnumber,:new.unitofmeasure,
           :new.quantity,:new.weight,:new.facility,l_locstatuschg_entry_invstatus,
           l_locstatuschg_entry_adjreason,:new.lasttask,'ENTR',:new.lastuser);
      end if;
    end if;
  end if;

   if (deleting
   or  (updating
      and ((nvl(:old.facility,'xx') != nvl(:new.facility,'xx'))
        or (nvl(:old.custid,'xx') != nvl(:new.custid,'xx'))
        or (nvl(:old.item,'xx') != nvl(:new.item,'xx'))
        or (nvl(:old.location,'xx') != nvl(:new.location,'xx'))
        or (nvl(:old.quantity,0) != nvl(:new.quantity,0)))))
   and (nvl(:old.type,'xx') = 'PA') then

      cntPickFront := 0;
      select count(1) into cntPickFront
         from itempickfronts
         where facility = :old.facility
           and custid = :old.custid
           and item = :old.item
           and pickfront = :old.location
           and nvl(dynamic, 'N') = 'Y';
      if cntPickFront != 0 then
         insert into dynamicpf_temp
            (facility, custid, item, locid)
         values
            (:old.facility, :old.custid, :old.item, :old.location);
      end if;
   end if;

   if (updating
   and ((nvl(:old.item, 'x') != nvl(:new.item, 'x'))
    or  (nvl(:old.custid, 'x') != nvl(:new.custid, 'x'))
    or  (nvl(:old.facility, 'x') != nvl(:new.facility, 'x'))
    or  (nvl(:old.status, 'x') != nvl(:new.status, 'x'))
    or  (nvl(:old.unitofmeasure, 'x') != nvl(:new.unitofmeasure, 'x')))) then
     update location
        set used_uos = null
      where facility = :old.facility
        and locid = :old.location
        and used_uos is not null;
     if nvl(:old.facility,'x') != nvl(:new.facility,'x') or
        nvl(:old.location,'x') != nvl(:new.location,'x') then
       update location
          set used_uos = null
        where facility = :new.facility
          and locid = :new.location
          and used_uos is not null;
     end if;
   end if;
end;
/
show error trigger plate_au_all;
show error trigger plate_ad_all;
show error trigger plate_bu;
show error trigger plate_bi;
show error trigger plate_aiud;

exit;
