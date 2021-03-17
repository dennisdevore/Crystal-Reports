drop table bolrequest_carrier;
drop table bolrequest_tmpcarrier;
drop table bolrequest_carrier_items;
drop table bolrequest_carrier_masters;

create table bolrequest_carrier_items
(vicsessionid    number(7)
,vicsequence     number(7)
,custid          varchar2(10)
,item            varchar2(50)
,qty             number(7)
,itemweight      number(17,8)
,hazardyn        varchar2(1)
,lastupdate      date
,baseuom         varchar2(4)
,uom1            varchar2(4)
);

create table bolrequest_carrier_masters
(vicsessionid       number(7)
,vicsequence        number(7)
,lpid            varchar2(15)
,lastupdate      date
);

create table bolrequest_tmpcarrier
(vicsessionid    number(7)
,vicsequence     number(7)
,freightclass    char(12)
,hazardyn        varchar2(1)
,qty             number(7)
,itemweight      number(17,8)
,cntPallets      number(7)
,boldesc         varchar2(80)
,nmfc_code       varchar2(12)
,nmfc_class      number(4,1)
,numstops        number(7)
,lastupdate      date
,baseuom         varchar2(4)
,baseuomabbrev   varchar2(12)
,uom1            varchar2(4)
,uom1abbrev      varchar2(12)
,uom1qty         number(7)
);

create table bolrequest_carrier
(vicsessionid    number(7)
,vicsequence     number(7)
,vicsubsequence  number(7)
,freightclass    char(12)
,hazardyn        varchar2(1)
,qty             number(7)
,itemweight      number(18,8)
,cntPallets      number(7)
,boldesc         varchar2(80)
,nmfc_code       varchar2(12)
,nmfc_class      number(4,1)
,numstops        number(7)
,lastupdate      date
,baseuom         varchar2(4)
,baseuomabbrev   varchar2(12)
,uom1            varchar2(4)
,uom1abbrev      varchar2(12)
,uom1qty         number(7)
);

create index bolrequest_car_sessionid_idx
 on bolrequest_carrier(vicsessionid,vicsequence);

create index bolrequest_car_lastupdate_idx
 on bolrequest_carrier(lastupdate);

create index bolrequest_tcar_sessionid_idx
 on bolrequest_tmpcarrier(vicsessionid,vicsequence);

create index bolrequest_tcar_lastupdate_idx
 on bolrequest_tmpcarrier(lastupdate);

create index bolrequest_itm_sessionid_idx
 on bolrequest_carrier_items(vicsessionid,vicsequence);

create index bolrequest_itm_lastupdate_idx
 on bolrequest_carrier_items(lastupdate);

create index bolrequest_mst_sessionid_idx
 on bolrequest_carrier_masters(vicsessionid,vicsequence);

create index bolrequest_mst_lastupdate_idx
 on bolrequest_carrier_masters(lastupdate);

create or replace package bolcarrierpkg
as type bolrequest_carrier_type is ref cursor return bolrequest_carrier%rowtype;
end bolcarrierpkg;
/
create or replace procedure bolcarrierproc
(bolrequest_carrier_cursor IN OUT bolcarrierpkg.bolrequest_carrier_type
,in_vicsessionid number
,in_vicsequence number
,in_bolreqtype varchar2
,in_carsuppmsg_yn varchar2
,in_loadno number
,in_stopno number
,in_shipno number
,in_orderid number
,in_shipid number
,in_debug_yn IN varchar2)
as
--
-- $Id$
--

cursor curLoads is
  select loadno,
         shiptype
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;

cursor curSumFreight is
  select freightclass,baseuom,uom1,
         max(hazardyn) as hazardyn,
         sum(qty) as qty,
         sum(itemweight) as itemweight,
         sum(cntPallets) as cntPallets,
         max(boldesc) as boldesc,
         max(nmfc_code) as nmfc_code,
         max(nmfc_class) as nmfc_class,
         max(numstops) as numstops,
         max(baseuomabbrev) as baseuomabbrev,
         max(uom1abbrev) as uom1abbrev,
         sum(uom1qty) as uom1qty
    from bolrequest_tmpcarrier
   where vicsessionid = in_vicsessionid
     and vicsequence = in_vicsequence
   group by freightclass,baseuom,uom1
   order by freightclass,baseuom,uom1;

cntRows integer;
cntCarrier integer;
cntHazard integer;
cntPallets integer;
bolstopno integer;
bolmaxstopno integer;
stopshipto orderhdr.shipto%type;
shipcarrier carrier.carrier%type;
shipcarrierphone carrier.phone%type;
stopfound boolean;
wrkh bolrequest_header%rowtype;
wrk bolrequest_carrier%rowtype;

begin

delete from bolrequest_carrier
where vicsessionid = in_vicsessionid
  and vicsequence = in_vicsequence;
commit;

delete from bolrequest_carrier
where lastupdate < trunc(sysdate);
commit;

delete from bolrequest_tmpcarrier
where vicsessionid = in_vicsessionid
  and vicsequence = in_vicsequence;
commit;

delete from bolrequest_tmpcarrier
where lastupdate < trunc(sysdate);
commit;

delete from bolrequest_carrier_items
where vicsessionid = in_vicsessionid
  and vicsequence = in_vicsequence;
commit;

delete from bolrequest_carrier_items
where lastupdate < trunc(sysdate);
commit;

delete from bolrequest_carrier_masters
where vicsessionid = in_vicsessionid
  and vicsequence = in_vicsequence;
commit;

delete from bolrequest_carrier_masters
where lastupdate < trunc(sysdate);
commit;

wrk := null;
wrk.vicsessionid := in_vicsessionid;
wrk.vicsequence := in_vicsequence;

if in_debug_yn = 'Y' then
  zut.prt('get load info for reqtype ' || in_bolreqtype);
end if;

ld := null;
open curLoads;
fetch curLoads into ld;
close curLoads;
if ld.loadno is null then
  goto return_vics_rows;
end if;

if in_debug_yn = 'Y' then
  zut.prt('get num stops');
end if;

begin
  select count(1)
    into wrk.numStops
    from loadstop
   where loadno = in_loadno;
exception when others then
  wrk.numStops := 1;
end;

if in_debug_yn = 'Y' then
  zut.prt('get del point');
end if;

wrkh.delpointtype := '?';
if in_bolreqtype != 'MAST' then
  begin
    select delpointtype
      into wrkh.delpointtype
      from loadstop
     where loadno = in_loadno
       and stopno = in_stopno;
  exception when others then
    null;
  end;
end if;

if in_debug_yn = 'Y' then
  zut.prt('shippingplate selects');
end if;

wrkh.lastupdate := sysdate;
if in_bolreqtype = 'MAST' then
  for sp in
    (select type,status,custid,item,unitofmeasure,sum(quantity) as quantity
       from shippingplate
      where loadno = in_loadno
      group by type,status,custid,item,unitofmeasure)
  loop
    if sp.type in ('P','F') and
       sp.status in ('P','S','L','SH','FA') then
      insert into bolrequest_carrier_items
        values
        (wrk.vicsessionid,wrk.vicsequence,
         sp.custid,sp.item,sp.quantity,
         zci.item_weight(sp.custid,sp.item,sp.unitofmeasure) * sp.quantity,
         substr(zci.hazardous_item(sp.custid,sp.item),1,1),
         wrkh.lastupdate,sp.unitofmeasure,
         substr(zcu.next_uom(sp.custid,sp.item,sp.unitofmeasure,1),1,4)
        );
    end if;
  end loop;
elsif in_bolreqtype = 'STOP' then
  for sp in
    (select type,status,custid,item,unitofmeasure,sum(quantity) as quantity
       from shippingplate
      where loadno = in_loadno
        and stopno = in_stopno
      group by type,status,custid,item,unitofmeasure)
  loop
    if sp.type in ('P','F') and
       sp.status in ('P','S','L','SH','FA') then
      insert into bolrequest_carrier_items
        values
        (wrk.vicsessionid,wrk.vicsequence,sp.custid,sp.item,sp.quantity,
         zci.item_weight(sp.custid,sp.item,sp.unitofmeasure) * sp.quantity,
         substr(zci.hazardous_item(sp.custid,sp.item),1,1),
         wrkh.lastupdate,sp.unitofmeasure,
         substr(zcu.next_uom(sp.custid,sp.item,sp.unitofmeasure,1),1,4)
        );
    end if;
  end loop;
elsif in_bolreqtype = 'SHIP' then
  for sp in
    (select type,status,custid,item,unitofmeasure,sum(quantity) as quantity
       from shippingplate
      where loadno = in_loadno
        and stopno = in_stopno
        and shipno = in_shipno
      group by type,status,custid,item,unitofmeasure)
  loop
    if sp.type in ('P','F') and
       sp.status in ('P','S','L','SH','FA') then
      insert into bolrequest_carrier_items
        values
        (wrk.vicsessionid,wrk.vicsequence,sp.custid,sp.item,sp.quantity,
         zci.item_weight(sp.custid,sp.item,sp.unitofmeasure) * sp.quantity,
         substr(zci.hazardous_item(sp.custid,sp.item),1,1),
         wrkh.lastupdate,sp.unitofmeasure,
         substr(zcu.next_uom(sp.custid,sp.item,sp.unitofmeasure,1),1,4)
        );
    end if;
  end loop;
else
  for sp in
    (select type,status,custid,item,unitofmeasure,sum(quantity) as quantity
       from shippingplate
      where loadno = in_loadno
        and stopno = in_stopno
        and shipno = in_shipno
        and orderid = in_orderid
        and shipid = in_shipid
      group by type,status,custid,item,unitofmeasure)
  loop
    if sp.type in ('P','F') and
       sp.status in ('P','S','L','SH','FA') then
      insert into bolrequest_carrier_items
        values
        (wrk.vicsessionid,wrk.vicsequence,sp.custid,sp.item,sp.quantity,
         zci.item_weight(sp.custid,sp.item,sp.unitofmeasure) * sp.quantity,
         substr(zci.hazardous_item(sp.custid,sp.item),1,1),
         wrkh.lastupdate,sp.unitofmeasure,
         substr(zcu.next_uom(sp.custid,sp.item,sp.unitofmeasure,1),1,4)
        );
    end if;
  end loop;
end if;

commit;

cntHazard := 0;


if in_debug_yn = 'Y' then
  zut.prt('select items and count pallets');
end if;

for itm in
  (select *
     from bolrequest_carrier_items
    where vicsessionid = wrk.vicsessionid
      and vicsequence = wrk.vicsequence)
loop
  cntPallets := 0;
  begin
    select nvl(nmfc,'NONE')
      into wrk.nmfc_code
      from custitem
     where custid = itm.custid
       and item = itm.item;
  exception when others then
    wrk.nmfc_code := 'NONE';
  end;
  begin
    select class, substr(descr,1,80)
      into wrk.nmfc_class, wrk.boldesc
      from nmfclasscodes
     where nmfc = wrk.nmfc_code;
  exception when others then
    wrk.nmfc_class := 0;
    wrk.boldesc := 'Not Classified';
  end;
  if itm.hazardyn = 'Y' then
    cntHazard := cntHazard + 1;
  end if;
  if in_bolreqtype = 'MAST' then
    for sp in
      (select parentlpid,status
         from shippingplate
        where loadno = in_loadno
          and custid = itm.custid
          and item = itm.item
          and parentlpid is not null
          and not exists
            (select * from bolrequest_carrier_masters
               where vicsessionid = wrk.vicsessionid
                 and vicsequence = wrk.vicsequence
                 and shippingplate.parentlpid = bolrequest_carrier_masters.lpid))
    loop
      if sp.status in ('P','S','L','SH','FA') then
        select count(1)
          into cntRows
          from shippingplate
         where parentlpid = sp.parentlpid
           and custid = itm.custid
           and item = itm.item;
        if cntRows != 0 then
          cntPallets := cntPallets + 1;
          insert into bolrequest_carrier_masters
            values
            (wrk.vicsessionid,wrk.vicsequence,sp.parentlpid,sysdate);
        end if;
      end if;
    end loop;
  elsif in_bolreqtype = 'STOP' then
    for sp in
      (select parentlpid,status
         from shippingplate
        where loadno = in_loadno
          and stopno = in_stopno
          and custid = itm.custid
          and item = itm.item
          and parentlpid is not null
          and not exists
            (select * from bolrequest_carrier_masters
               where vicsessionid = wrk.vicsessionid
                 and vicsequence = wrk.vicsequence
                 and shippingplate.parentlpid = bolrequest_carrier_masters.lpid))
    loop
      if sp.status in ('P','S','L','SH','FA') then
        select count(1)
          into cntRows
          from shippingplate
         where parentlpid = sp.parentlpid
           and custid = itm.custid
           and item = itm.item;
        if cntRows != 0 then
          cntPallets := cntPallets + 1;
          insert into bolrequest_carrier_masters
            values
            (wrk.vicsessionid,wrk.vicsequence,sp.parentlpid,sysdate);
        end if;
      end if;
    end loop;
  elsif in_bolreqtype = 'SHIP' then
    for sp in
      (select parentlpid,status
         from shippingplate
        where loadno = in_loadno
          and stopno = in_stopno
          and shipno = in_shipno
          and custid = itm.custid
          and item = itm.item
          and parentlpid is not null
          and not exists
            (select * from bolrequest_carrier_masters
               where vicsessionid = wrk.vicsessionid
                 and vicsequence = wrk.vicsequence
                 and shippingplate.parentlpid = bolrequest_carrier_masters.lpid))
    loop
      if sp.status in ('P','S','L','SH','FA') then
        select count(1)
          into cntRows
          from shippingplate
         where parentlpid = sp.parentlpid
           and custid = itm.custid
           and item = itm.item;
        if cntRows != 0 then
          cntPallets := cntPallets + 1;
          insert into bolrequest_carrier_masters
            values
            (wrk.vicsessionid,wrk.vicsequence,sp.parentlpid,sysdate);
        end if;
      end if;
    end loop;
  else
    for sp in
      (select parentlpid,status
         from shippingplate
        where loadno = in_loadno
          and stopno = in_stopno
          and shipno = in_shipno
          and orderid = in_orderid
          and shipid = in_shipid
          and custid = itm.custid
          and item = itm.item
          and parentlpid is null
          and not exists
            (select * from bolrequest_carrier_masters
               where vicsessionid = wrk.vicsessionid
                 and vicsequence = wrk.vicsequence
                 and shippingplate.parentlpid = bolrequest_carrier_masters.lpid))
    loop
      if sp.status in ('P','S','L','SH','FA') then
        select count(1)
          into cntRows
          from shippingplate
         where parentlpid = sp.parentlpid
           and custid = itm.custid
           and item = itm.item;
        if cntRows != 0 then
          cntPallets := cntPallets + 1;
          insert into bolrequest_carrier_masters
            values
            (wrk.vicsessionid,wrk.vicsequence,sp.parentlpid,sysdate);
        end if;
      end if;
    end loop;
  end if;

  if in_debug_yn = 'Y' then
    zut.prt('insert tmpcarrier');
  end if;

  insert into bolrequest_tmpcarrier
    values
    (wrk.vicsessionid,wrk.vicsequence,
     wrk.nmfc_code,itm.hazardyn,
     itm.qty,itm.itemweight,cntPallets,wrk.boldesc,
     wrk.nmfc_code,wrk.nmfc_class,wrkh.numstops,
     sysdate,itm.baseuom,substr(zit.uom_abbrev(itm.baseuom),1,12),
     itm.uom1,substr(zit.uom_abbrev(itm.uom1),1,12),
     zcu.equiv_uom_qty(itm.custid,itm.item,itm.baseuom,itm.qty,itm.uom1)
    );
end loop;

if in_carsuppmsg_yn = 'Y' then
  goto do_supplement;
end if;

if in_debug_yn = 'Y' then
  zut.prt('summarize freightclass');
end if;

wrk.vicsubsequence := 0;
for fc in curSumFreight
loop
  if in_debug_yn = 'Y' then
    zut.prt('nmfc_code >' || fc.nmfc_code || '<');
    zut.prt('hazardyn >' || fc.hazardyn || '<');
    zut.prt('qty >' || fc.qty || '<');
    zut.prt('itemweight >' || fc.itemweight || '<');
    zut.prt('cntPallets >' || fc.cntPallets || '<');
    zut.prt('boldesc >' || fc.boldesc || '<');
    zut.prt('nmfc_class >' || fc.nmfc_class || '<');
    zut.prt('numstops >' || fc.numstops || '<');
  end if;
  wrk.vicsubsequence := wrk.vicsubsequence + 1;
  insert into bolrequest_carrier
    values
    (wrk.vicsessionid,wrk.vicsequence,wrk.vicsubsequence,
     fc.nmfc_code,fc.hazardyn,
     fc.qty,fc.itemweight,fc.cntPallets,fc.boldesc,
     fc.nmfc_code,fc.nmfc_class,fc.numstops,sysdate,
     fc.baseuom,fc.baseuomabbrev,fc.uom1,fc.uom1abbrev,
     fc.uom1qty);
end loop;

commit;

select count(1)
  into cntCarrier
  from bolrequest_carrier
 where vicsessionid = wrk.vicsessionid
   and vicsequence = wrk.vicsequence;

if in_carsuppmsg_yn = 'C' then

  if in_debug_yn = 'Y' then
    zut.prt('return count');
  end if;

  delete from bolrequest_carrier
     where vicsessionid = wrk.vicsessionid
       and vicsequence = wrk.vicsequence;
  commit;
  insert into bolrequest_carrier
  (vicsessionid,vicsequence,numstops,lastupdate)
  values
  (wrk.vicsessionid,wrk.vicsequence,cntCarrier,sysdate);
  commit;
  goto return_vics_rows;
end if;

if in_debug_yn = 'Y' then
  zut.prt('pad rows');
end if;

while cntCarrier < 6
loop
  insert into bolrequest_carrier
  (vicsessionid,vicsequence,lastupdate)
  values
  (wrk.vicsessionid,wrk.vicsequence,sysdate);
  cntCarrier := cntCarrier + 1;
end loop;

if in_bolreqtype != 'SHIP' then
  update bolrequest_carrier
     set nmfc_code = null,
         nmfc_class = null
   where vicsessionid = wrk.vicsessionid
     and vicsequence = wrk.vicsequence;
  commit;
end if;

goto return_vics_rows;

<< do_supplement >>

if in_debug_yn = 'Y' then
  zut.prt('do supplement');
end if;

cntCarrier := 0;
if cntHazard <> 0 then
  wrk.hazardyn := 'Y';
else
  wrk.hazardyn := 'N';
end if;

while cntCarrier < 6
loop
  if cntCarrier = 0 and cntHazard != 0 then
    wrk.boldesc := 'Hazardous Material';
  elsif cntCarrier = 1 then
    wrk.boldesc := '$SEE ATTACHED$';
  elsif cntCarrier = 2 then
    wrk.boldesc := '$SUPPLEMENT$';
  else
    wrk.boldesc := null;
  end if;
  cntCarrier := cntCarrier + 1;
  if cntCarrier = 1 then
    insert into bolrequest_carrier
    select vicsessionid,vicsequence,cntCarrier,
           null,wrk.hazardyn,sum(qty),
           sum(itemweight),sum(cntPallets),wrk.boldesc,
           null,null,null,sysdate,null,null,null,null,sum(uom1qty)
      from bolrequest_tmpcarrier
     where vicsessionid = wrk.vicsessionid
       and vicsequence = wrk.vicsequence
     group by vicsessionid,vicsequence;
  else
    insert into bolrequest_carrier
    (vicsessionid,vicsequence,boldesc,lastupdate)
    values
    (wrk.vicsessionid,wrk.vicsequence,wrk.boldesc,sysdate);
  end if;
end loop;

<<return_vics_rows>>

commit;

open bolrequest_carrier_cursor for
 select *
   from bolrequest_carrier
  where vicsessionid = in_vicsessionid
    and vicsequence = in_vicsequence
  order by vicsubsequence;

end bolcarrierproc;
/
show errors package bolcarrierpkg;
show errors procedure bolcarrierproc;
exit;
