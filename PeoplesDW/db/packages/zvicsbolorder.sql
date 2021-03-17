drop table bolrequest_order;
drop table bolrequest_tmporder;

create table bolrequest_tmporder
(vicsessionid       number(7)
,vicsequence        number(7)
,stopno          number(7)
,shipno          number(7)
,orderid         number(9)
,shipid          number(7)
,casesshipped    number(7)
,weightshipped   number(17,8)
,latearrive      date
,delwindowbeg    varchar2(8)
,delwindowend    varchar2(8)
,custpo          varchar2(40)
,custfacility    varchar2(3)
,dept            varchar2(3)
,custpotype      varchar2(3)
,shipperinfo     char(80)
,lastupdate      date
,reference       varchar2(20)
,baseuom         varchar2(4)
,baseuomabbrev   varchar2(12)
,uom1            varchar2(4)
,uom1abbrev      varchar2(12)
,uom1shipped     number(7)
);

create table bolrequest_order
(vicsessionid    number(7)
,vicsequence     number(7)
,vicsubsequence  number(7)
,orderid         number(9)
,casesshipped    number(7)
,weightshipped   number(17,8)
,delwindowbeg    varchar2(8)
,delwindowend    varchar2(8)
,custpo          varchar2(40)
,shipperinfo     char(80)
,numstops        number(7)
,lastupdate      date
,reference       varchar2(20)
,baseuom         varchar2(4)
,baseuomabbrev   varchar2(12)
,uom1            varchar2(4)
,uom1abbrev      varchar2(12)
,uom1shipped     number(7)
);

create index bolrequest_ord_sessionid_idx
 on bolrequest_order(vicsessionid,vicsequence);

create index bolrequest_ord_lastupdate_idx
 on bolrequest_order(lastupdate);

create index bolrequest_tord_sessionid_idx
 on bolrequest_tmporder(vicsessionid,vicsequence);

create index bolrequest_tord_lastupdate_idx
 on bolrequest_tmporder(lastupdate);

create or replace package bolorderpkg
as type bolrequest_order_type is ref cursor return bolrequest_order%rowtype;
end bolorderpkg;
/
create or replace procedure bolorderproc
(bolrequest_order_cursor IN OUT bolorderpkg.bolrequest_order_type
,in_vicsessionid number
,in_vicsequence number
,in_bolreqtype varchar2
,in_ordsuppmsg_yn varchar2
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
         facility
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;

cntRows integer;
cntOrder integer;
bolstopno integer;
bolmaxstopno integer;
stopshipto orderhdr.shipto%type;
shipcarrier carrier.carrier%type;
shipcarrierphone carrier.phone%type;
stopfound boolean;
wrkh bolrequest_header%rowtype;
wrk bolrequest_order%rowtype;

procedure get_stop_shipto_info(in_loadno number, in_stopno number)
is
begin
  wrkh.delpointcsz := null;
  select shipto
    into stopshipto
    from loadstop
   where loadno = in_loadno
     and stopno = in_stopno;
  select rtrim(city) || ' ' || rtrim(state) || ', ' || rtrim(postalcode)
    into wrkh.delpointcsz
    from consignee
   where consignee = stopshipto;
exception when others then
  null;
end get_stop_shipto_info;

begin

delete from bolrequest_order
where vicsessionid = in_vicsessionid
  and vicsequence = in_vicsequence;
commit;

delete from bolrequest_order
where lastupdate < trunc(sysdate);
commit;

delete from bolrequest_tmporder
where vicsessionid = in_vicsessionid
  and vicsequence = in_vicsequence;
commit;

delete from bolrequest_tmporder
where lastupdate < trunc(sysdate);
commit;

wrk := null;
wrk.vicsessionid := in_vicsessionid;
wrk.vicsequence := in_vicsequence;

if in_debug_yn = 'Y' then
  zut.prt('get load info');
end if;

ld := null;
open curLoads;
fetch curLoads into ld;
close curLoads;
if ld.loadno is null then
  goto return_vics_rows;
end if;


if in_debug_yn = 'Y' then
  zut.prt('get numstops');
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
  zut.prt('check for count request '  || in_bolreqtype || ' ' ||
    wrk.numStops || ' ' || in_ordsuppmsg_yn);
end if;

if ( (in_bolreqtype = 'MAST' and wrk.numStops > 1) and
     (in_ordsuppmsg_yn = 'C') ) then
  if in_debug_yn = 'Y' then
    zut.prt('insert copies for return');
  end if;
  insert into bolrequest_order
  (vicsessionid,vicsequence,vicsubsequence,
   numstops,lastupdate)
  values
  (wrk.vicsessionid,wrk.vicsequence,1,
   wrk.numstops,sysdate);
   goto return_vics_rows;
end if;

wrk.delwindowbeg := '01/01/90';
wrk.delwindowend := '01/01/90';

if in_bolreqtype = 'STOP' then
  if in_debug_yn = 'Y' then
    zut.prt('check for distributor stop');
  end if;
  begin
    select delpointtype
      into wrkh.delpointtype
      from loadstop
     where loadno = in_loadno
       and stopno = in_stopno;
  exception when others then
    wrkh.delpointtype := '?';
  end;
  if wrkh.delpointtype = 'D' then
    wrkh.lastupdate := sysdate;
    wrk.casesshipped := 0;
    wrk.weightshipped := 0;
    for sp in
      (select type,status,quantity,
              zci.item_weight(custid,item,unitofmeasure)*quantity as weight
         from shippingplate
        where loadno = in_loadno
          and stopno = in_stopno)
    loop
      if sp.type in ('P','F') and
         sp.status in ('P','S','L','SH','FA') then
        wrk.casesshipped := wrk.casesshipped + sp.quantity;
        wrk.weightshipped := wrk.weightshipped + sp.weight;
      end if;
    end loop;
    insert into bolrequest_tmporder
    (vicsessionid,vicsequence,casesshipped,weightshipped,delwindowbeg,delwindowend,
     lastupdate)
    values
    (wrk.vicsessionid,wrk.vicsequence,wrk.casesshipped,wrk.weightshipped,
     wrk.delwindowbeg,wrk.delwindowend,sysdate);
    cntOrder := 1;
    goto pad_rows;
  end if;
end if;

if in_debug_yn = 'Y' then
  zut.prt('insert orders');
end if;

if in_bolreqtype = 'MAST' then
  insert into bolrequest_tmporder
  select wrk.vicsessionid,wrk.vicsequence,
         stopno,shipno,orderid,shipid,qtyship,weightship,arrivaldate,
         wrk.delwindowbeg,wrk.delwindowend,null,null,null,null,
         wrk.shipperinfo,sysdate,reference,null,null,null,null,null
    from orderhdr
   where loadno = in_loadno;
--   order by orderid,shipid;
elsif in_bolreqtype = 'STOP' then
  insert into bolrequest_tmporder
  select wrk.vicsessionid,wrk.vicsequence,
         stopno,shipno,orderid,shipid,qtyship,weightship,arrivaldate,
         wrk.delwindowbeg,wrk.delwindowend,null,null,null,null,
         wrk.shipperinfo,sysdate,reference,null,null,null,null,null
    from orderhdr
   where loadno = in_loadno
     and stopno = in_stopno;
--   order by orderid,shipid;
elsif in_bolreqtype = 'SHIP' then
  insert into bolrequest_tmporder
  select wrk.vicsessionid,wrk.vicsequence,
         stopno,shipno,orderid,shipid,qtyship,weightship,arrivaldate,
         wrk.delwindowbeg,wrk.delwindowend,po,null,null,null,
         wrk.shipperinfo,sysdate,reference,null,null,null,null,null
    from orderhdr
   where loadno = in_loadno
     and stopno = in_stopno
     and shipno = in_shipno;
--   order by orderid,shipid;
else
  insert into bolrequest_tmporder
  select wrk.vicsessionid,wrk.vicsequence,
         stopno,shipno,orderid,shipid,qtyship,weightship,arrivaldate,
         wrk.delwindowbeg,wrk.delwindowend,po,null,null,null,
         wrk.shipperinfo,sysdate,reference,null,null,null,null,null
    from orderhdr
   where loadno = in_loadno
     and stopno = in_stopno
     and shipno = in_shipno
     and orderid = in_orderid
     and shipid = in_shipid;
--   order by orderid,shipid;
end if;

commit;

if in_debug_yn = 'Y' then
  zut.prt('count orders');
end if;

select count(1)
  into cntOrder
  from bolrequest_tmporder
 where vicsessionid = wrk.vicsessionid
   and vicsequence = wrk.vicsequence;

<<pad_rows>>

if in_debug_yn = 'Y' then
  zut.prt('check for count request');
end if;

if ( (in_bolreqtype = 'MAST' and wrk.numstops = 1) or
     (in_bolreqtype != 'MAST') ) and
     (in_ordsuppmsg_yn = 'C') then
  select count(1)
    into wrk.numstops
    from bolrequest_tmporder
   where vicsessionid = wrk.vicsessionid
     and vicsequence = wrk.vicsequence;
  insert into bolrequest_order
  (vicsessionid,vicsequence,vicsubsequence,
   numstops,lastupdate)
  values
  (wrk.vicsessionid,wrk.vicsequence,1,
   wrk.numstops,sysdate);
  goto return_vics_rows;
end if;

if in_debug_yn = 'Y' then
  zut.prt('from tmp to order with shippingplate');
end if;

for ord in
  (select *
     from bolrequest_tmporder
    where vicsessionid = wrk.vicsessionid
      and vicsequence = wrk.vicsequence)
loop

  wrk.weightshipped := 0;
  wrk.baseuom := null;
  wrk.baseuomabbrev := null;
  wrk.uom1 := null;
  wrk.uom1abbrev := null;
  wrk.uom1shipped := 0;

  for sp in
    (select custid,item,type,status,quantity,unitofmeasure,
            zci.item_weight(custid,item,unitofmeasure)*quantity as weight
       from shippingplate
      where orderid = ord.orderid
        and shipid = ord.shipid)
  loop
    if sp.type in ('P','F') and
       sp.status in ('P','S','L','SH','FA') then
      wrk.weightshipped := wrk.weightshipped + sp.weight;
      if wrk.baseuom is null then
        wrk.baseuom := sp.unitofmeasure;
        wrk.baseuomabbrev := substr(zit.uom_abbrev(wrk.baseuom),1,12);
        wrk.uom1 := substr(zcu.next_uom(sp.custid,sp.item,wrk.baseuom,1),1,4);
        wrk.uom1abbrev := substr(zit.uom_abbrev(wrk.uom1),1,12);
      end if;
      if (wrk.baseuom is not null) and
         (wrk.uom1 is not null) then
        wrk.uom1shipped := wrk.uom1shipped +
          zcu.equiv_uom_qty(sp.custid,sp.item,wrk.baseuom,
               sp.quantity,wrk.uom1);
      end if;
    end if;
  end loop;

  update bolrequest_tmporder
     set weightshipped = wrk.weightshipped,
         baseuom = wrk.baseuom,
         baseuomabbrev = wrk.baseuomabbrev,
         uom1 = wrk.uom1,
         uom1abbrev = wrk.uom1abbrev,
         uom1shipped = wrk.uom1shipped
   where vicsessionid = wrk.vicsessionid
     and vicsequence = wrk.vicsequence
     and orderid = ord.orderid
     and shipid = ord.shipid;
  commit;

end loop;

if in_debug_yn = 'Y' then
  zut.prt('pad rows');
end if;

while cntOrder < 6
loop
  insert into bolrequest_tmporder
  (vicsessionid,vicsequence,delwindowbeg,delwindowend,lastupdate)
  values
  (wrk.vicsessionid,wrk.vicsequence,wrk.delwindowbeg,wrk.delwindowend,sysdate);
  cntOrder := cntOrder + 1;
end loop;

if ( (in_bolreqtype = 'MAST' and wrk.numstops = 1) or
     (in_bolreqtype != 'MAST') ) and
     (in_ordsuppmsg_yn = 'N') then

  if in_debug_yn = 'Y' then
    zut.prt('data from tmp to order');
  end if;

  wrk.vicsubsequence := 0;
  for ord in
    (select *
       from bolrequest_tmporder
      where vicsessionid = wrk.vicsessionid
        and vicsequence = wrk.vicsequence
      order by custpo,orderid)
  loop
    wrk.vicsubsequence := wrk.vicsubsequence + 1;
    insert into bolrequest_order
    values
    (wrk.vicsessionid,wrk.vicsequence,wrk.vicsubsequence,
     ord.orderid,ord.casesshipped,ord.weightshipped,
     ord.delwindowbeg,ord.delwindowend,
     ord.custpo,ord.shipperinfo,wrk.numstops,sysdate,ord.reference,
     ord.baseuom,ord.baseuomabbrev,ord.uom1,ord.uom1abbrev,ord.uom1shipped);
  end loop;
  commit;
  goto return_vics_rows;
end if;

if in_debug_yn = 'Y' then
  zut.prt('get max stop');
end if;

if in_bolreqtype = 'MAST' and
   wrk.numstops > 1 then
  select max(nvl(stopno,0))
    into bolmaxstopno
    from bolrequest_tmporder
   where vicsessionid = wrk.vicsessionid
     and vicsequence = wrk.vicsequence;
end if;

if in_debug_yn = 'Y' then
  zut.prt('process stops');
end if;

bolstopno := 0;
cntOrder := 0;
while (cntOrder < 6)
loop
  wrk.shipperinfo := null;
  wrk.custpo := null;
  wrk.orderid := null;
  if in_bolreqtype = 'MAST' and
     wrk.numstops > 1 and
     in_ordsuppmsg_yn = 'Y' then
    stopfound := false;
    for ls in
      (select stopno
         from loadstop
        where loadno = in_loadno
          and stopno > bolstopno
        order by stopno)
    loop
      bolstopno := ls.stopno;
      stopfound := true;
      exit;
    end loop;
    if stopfound = false then
      bolstopno := 9999999;
    else
      get_stop_shipto_info(in_loadno,bolstopno);
      wrk.custpo := substr(wrkh.delpointcsz,1,40);
      wrk.orderid := bolstopno;
      shipcarrier := null;
      shipcarrierphone := null;
      for lss in
        (select carrier
           from loadstopship
          where loadno = in_loadno
            and stopno = bolstopno
          order by shipno)
      loop
        shipcarrier := lss.carrier;
        exit;
      end loop;
      begin
        select phone
          into shipcarrierphone
          from carrier
         where carrier = shipcarrier;
      exception when others then
        null;
      end;
      if trim(shipcarrierphone) is not null then
        wrk.shipperinfo := '-Call for Appointment ' || shipcarrierphone;
      end if;
    end if;
  else
    bolstopno := 9999999;
    if (in_bolreqtype = 'STOP') and
       (wrkh.delpointtype = 'D') then
      wrk.custpo := null;
    elsif cntOrder = 1 then
      wrk.custpo := '$SEE ATTACHED$';
    elsif cntOrder = 2 then
      wrk.custpo := '$SUPPLEMENT$';
    else
      wrk.custpo := null;
    end if;
  end if;

  if bolstopno != 9999999 then
    for ord in
      (select sum(casesshipped) as casesshipped,
              sum(weightshipped) as weightshipped
         from bolrequest_tmporder
        where vicsessionid = wrk.vicsessionid
          and vicsequence = wrk.vicsequence
          and stopno = bolstopno)
    loop
      cntOrder := cntOrder + 1;
      insert into bolrequest_order
      (vicsessionid,vicsequence,vicsubsequence,
       orderid,casesshipped,weightshipped,
       custpo,shipperinfo,lastupdate,numstops)
      values
      (wrk.vicsessionid,wrk.vicsequence,cntOrder,
       wrk.orderid,ord.casesshipped,ord.weightshipped,
       wrk.custpo,wrk.shipperinfo,sysdate,wrk.numstops);
    end loop;
    commit;
  elsif cntOrder = 0 then
    for ord in
      (select sum(casesshipped) as casesshipped,
              sum(weightshipped) as weightshipped
         from bolrequest_tmporder
        where vicsessionid = wrk.vicsessionid
          and vicsequence = wrk.vicsequence)
    loop
      cntOrder := cntOrder + 1;
      insert into bolrequest_order
      (vicsessionid,vicsequence,vicsubsequence,
       orderid,casesshipped,weightshipped,
       custpo,shipperinfo,lastupdate,numstops)
      values
      (wrk.vicsessionid,wrk.vicsequence,cntOrder,
       wrk.orderid,ord.casesshipped,ord.weightshipped,
       wrk.custpo,wrk.shipperinfo,sysdate,wrk.numstops);
    end loop;
    commit;
  else
    cntOrder := cntOrder + 1;
    insert into bolrequest_order
    (vicsessionid,vicsequence,vicsubsequence,
     orderid,
     custpo,shipperinfo,lastupdate,numstops)
    values
    (wrk.vicsessionid,wrk.vicsequence,cntOrder,
     wrk.orderid,
     wrk.custpo,wrk.shipperinfo,sysdate,wrk.numstops);
  end if;
end loop;

<<return_vics_rows>>

commit;

open bolrequest_order_cursor for
 select *
   from bolrequest_order
  where vicsessionid = in_vicsessionid
    and vicsequence = in_vicsequence
  order by vicsubsequence;

end bolorderproc;
/
show errors package bolorderpkg;
show errors procedure bolorderproc;
exit;
