drop table bolrequest_shipments;
drop table bolrequest_header;

create table bolrequest_shipments
(vicsessionid number(7)
,vicsequence number(7)
,stopno number(7)
,shipno number(7)
,cntorders number(7)
,lastupdate date
);

create table bolrequest_header
(vicsessionid       number(7)
,vicsequence        number(7)
,billoflading    varchar2(80)
,carrier         varchar2(4)
,prono           varchar2(20)
,facility        varchar2(3)
,seal            varchar2(15)
,trailer         varchar2(12)
,carriername     varchar2(40)
,branchaddress1  varchar2(40)
,branchaddress2  varchar2(40)
,branchcsz       varchar2(100)
,companyname     varchar2(40)
,delpointaddr1   varchar2(40)
,delpointaddr2   varchar2(40)
,delpointname   varchar2(40)
,delpointcsz     varchar2(100)
,freightterms    varchar2(3)
,numstops        number(7)
,delpointtype    varchar2(1)
,freightline1    varchar2(40)
,freightline2    varchar2(40)
,freightline3    varchar2(40)
,freightline4    varchar2(40)
,numpomemo       number(7)
,lastupdate      date
);

create index bolrequest_hdr_sessionid_idx
 on bolrequest_header(vicsessionid,vicsequence);

create index bolrequest_hdr_lastupdate_idx
 on bolrequest_header(lastupdate);

create or replace package bolheaderpkg
as type bolrequest_header_type is ref cursor return bolrequest_header%rowtype;
end bolheaderpkg;
/
create or replace procedure bolheaderproc
(bolrequest_header_cursor IN OUT bolheaderpkg.bolrequest_header_type
,in_vicsessionid number
,in_vicsequence number
,in_bolreqtype varchar2
,in_loadno number
,in_stopno number
,in_shipno number
,in_orderid number
,in_shipid number
,in_cvb_rowid varchar2
,in_debug_yn IN varchar2)
as
--
-- $Id$
--

cursor curLoads is
  select loadno,
         carrier,
         prono,
         facility,
         seal,
         trailer,
         shipterms,
         shiptype,
         billoflading
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;

cursor curOrdersByLoad is
  select orderid,shipid,shipterms,shiptype
    from orderhdr
   where loadno = in_loadno
   order by orderid,shipid;

cursor curOrdersByLoadStop is
  select orderid,shipid,shipterms,shiptype
    from orderhdr
   where loadno = in_loadno
     and stopno = in_stopno
   order by orderid,shipid;

cursor curOrdersByLoadStopShip is
  select orderid,shipid,shipterms,shiptype
    from orderhdr
   where loadno = in_loadno
     and stopno = in_stopno
     and shipno = in_shipno
   order by orderid,shipid;

cursor curOrdersByOrder is
  select orderid,shipid,shipterms,shiptype
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oi curOrdersByOrder%rowtype;

cursor curCustVicsBol is
  select *
    from custvicsbol
   where rowid = in_cvb_rowid;
cvb curCustVicsBol%rowtype;

cntRows integer;
maxstopno integer;
stopshipto loadstop.shipto%type;
wrk bolrequest_header%rowtype;

procedure get_stop_shipto_info(in_loadno number, in_stopno number)
is
begin
  wrk.delpointaddr1 := null;
  wrk.delpointaddr2 := null;
  wrk.delpointname := null;
  wrk.delpointcsz := null;
  select shipto
    into stopshipto
    from loadstop
   where loadno = in_loadno
     and stopno = in_stopno;
  select name,addr1,addr2,
         rtrim(city) || ' ' || rtrim(state) || ', ' || rtrim(postalcode)
    into wrk.delpointname,wrk.delpointaddr1,wrk.delpointaddr2,
         wrk.delpointcsz
    from consignee
   where consignee = stopshipto;
exception when others then
  null;
end get_stop_shipto_info;

procedure get_stop_facility_info(in_loadno number, in_stopno number)
is
begin

  wrk.branchaddress1 := null;
  wrk.branchaddress2 := null;
  wrk.branchcsz := null;

  select shipto
    into stopshipto
    from loadstop
   where loadno = in_loadno
     and stopno = in_stopno;
  select addr1,addr2,
         rtrim(city) || ' ' || rtrim(state) || ', ' || rtrim(postalcode)
    into wrk.branchaddress1,wrk.branchaddress2,
         wrk.branchcsz
    from consignee
   where consignee = stopshipto;

  wrk.facility := '';
  wrk.carriername := wrk.companyname;
  begin
    select nvl(carrier,wrk.carrier)
      into wrk.carrier
      from loadstopship
     where loadno = in_loadno
       and stopno = in_stopno
       and shipno = in_shipno;
  exception when others then
    null;
  end;

exception when others then
  null;
end get_stop_facility_info;

procedure get_order_delpoint_info(in_loadno number, in_stopno number, in_shipno number,
  in_get_prono_yn varchar2)
is

cursor curOrderInfo is
  select shipto,shiptoname,shiptoaddr1,shiptoaddr2,
         rtrim(shiptocity) || ' ' || rtrim(shiptostate) || ', ' || rtrim(shiptopostalcode) ||
             decode(shiptocountrycode,'USA',null,' ' || shiptocountrycode) as shiptocsz,
         prono
    from orderhdr
   where loadno = in_loadno
     and stopno = in_stopno
     and shipno = in_shipno
   order by orderid,shipid;

oi curOrderInfo%rowtype;
ordershipto orderhdr.shipto%type;

begin

  wrk.delpointaddr1 := null;
  wrk.delpointaddr2 := null;
  wrk.delpointname := null;
  wrk.delpointcsz := null;

  oi := null;
  open curOrderInfo;
  fetch curOrderInfo into oi;
  close curOrderInfo;
  if trim(oi.shipto) is not null then
    begin
      select name,addr1,addr2,
             rtrim(city) || ' ' || rtrim(state) || ', ' || rtrim(postalcode) ||
             decode(countrycode,'USA',null,' ' || countrycode)
        into wrk.delpointname,wrk.delpointaddr1,wrk.delpointaddr2,
             wrk.delpointcsz
        from consignee
       where consignee = oi.shipto;
    exception when others then
      null;
    end;
  else
    wrk.delpointname := oi.shiptoname;
    wrk.delpointaddr1 := oi.shiptoaddr1;
    wrk.delpointaddr2 := oi.shiptoaddr2;
    wrk.delpointcsz := oi.shiptocsz;
  end if;

  if in_get_prono_yn = 'Y' then
    if rtrim(oi.prono) is not null then
      wrk.prono := oi.prono;
    end if;
  end if;

exception when others then
  null;
end get_order_delpoint_info;

begin

delete from bolrequest_header
where vicsessionid = in_vicsessionid
  and vicsequence = in_vicsequence;
commit;

delete from bolrequest_shipments
where vicsessionid = in_vicsessionid
  and vicsequence = in_vicsequence;
commit;

delete from bolrequest_header
where lastupdate < trunc(sysdate);
commit;

delete from bolrequest_shipments
where lastupdate < trunc(sysdate);
commit;

ld := null;
open curLoads;
fetch curLoads into ld;
close curLoads;
if ld.loadno is null then
  goto return_vics_rows;
end if;

if ld.shiptype is null then
  if in_bolreqtype = 'MAST' then
    open curOrdersByLoad;
    fetch curOrdersByLoad into oi;
    close curOrdersByLoad;
  elsif in_bolreqtype = 'STOP' then
    open curOrdersByLoadStop;
    fetch curOrdersByLoadStop into oi;
    close curOrdersByLoadStop;
  elsif in_bolreqtype = 'SHIP' then
    open curOrdersByLoadStopShip;
    fetch curOrdersByLoadStopShip into oi;
    close curOrdersByLoadStopShip;
  else
    open curOrdersByOrder;
    fetch curOrdersByOrder into oi;
    close curOrdersByOrder;
  end if;
  ld.shiptype := oi.shiptype;
end if;

if ld.shipterms is null then
  if in_bolreqtype = 'MAST' then
    open curOrdersByLoad;
    fetch curOrdersByLoad into oi;
    close curOrdersByLoad;
  elsif in_bolreqtype = 'STOP' then
    open curOrdersByLoadStop;
    fetch curOrdersByLoadStop into oi;
    close curOrdersByLoadStop;
  elsif in_bolreqtype = 'SHIP' then
    open curOrdersByLoadStopShip;
    fetch curOrdersByLoadStopShip into oi;
    close curOrdersByLoadStopShip;
  else
    open curOrdersByOrder;
    fetch curOrdersByOrder into oi;
    close curOrdersByOrder;
  end if;
  ld.shipterms := oi.shipterms;
end if;

wrk := null;
wrk.vicsessionid := in_vicsessionid;
wrk.vicsequence := in_vicsequence;
wrk.facility := ld.facility;
wrk.carrier := ld.carrier;
wrk.seal := ld.seal;
wrk.trailer := ld.trailer;
wrk.prono := ld.prono;
wrk.freightterms := ld.shipterms;

begin
  select count(1)
    into wrk.numStops
    from loadstop
   where loadno = in_loadno;
exception when others then
  wrk.numStops := 1;
end;

wrk.delpointtype := '?';

if in_bolreqtype != 'MAST' then
  begin
    select delpointtype
      into wrk.delpointtype
      from loadstop
     where loadno = in_loadno
       and stopno = in_stopno;
  exception when others then
    wrk.delpointtype := 'C';
  end;
end if;

if rtrim(ld.billoflading) is null then
  wrk.billoflading := trim(to_char(in_loadno));
else
  wrk.billoflading := ld.billoflading;
end if;

if (in_bolreqtype = 'SHIP') or
   ( in_bolreqtype = 'POME' and
     (ld.shiptype = 'L' or wrk.delpointtype = 'D') ) then
  wrk.billoflading := wrk.billoflading || '-' || trim(to_char(in_shipno));
end if;

wrk.carrier := ld.carrier;

begin
  select name
    into wrk.carriername
    from carrier
   where carrier = wrk.carrier;
exception when others then
  wrk.carriername := 'Carrier ' || wrk.carrier;
end;

if in_bolreqtype in ('MAST','STOP','SHIP') then
  begin
    select name,
           addr1,addr2,
           rtrim(city) || ' ' || rtrim(state) || ', ' || rtrim(postalcode)
      into wrk.companyname,
           wrk.branchaddress1,wrk.branchaddress2,
           wrk.branchcsz
      from facility
     where facility = ld.facility;
  exception when others then
    null;
  end;
end if;

if in_bolreqtype = 'MAST' then
  begin
    select max(stopno)
      into maxstopno
      from loadstop
     where loadno = in_loadno;
  exception when others then
    maxstopno := 1;
  end;
  get_stop_shipto_info(in_loadno,maxstopno);
elsif in_bolreqtype = 'STOP' then
  get_stop_shipto_info(in_loadno,in_stopno);
elsif in_bolreqtype = 'SHIP' then
  if ld.shiptype != 'L' then
    get_stop_facility_info(in_loadno,in_stopno);
  end if;
  get_order_delpoint_info(in_loadno,in_stopno,in_shipno,'Y');
else
  if ld.shiptype != 'L' then
    get_stop_facility_info(in_loadno,in_stopno);
  end if;
  get_order_delpoint_info(in_loadno,in_stopno,in_shipno,'N');
end if;

if rtrim(wrk.delpointaddr2) is null then
  wrk.delpointaddr2 := wrk.delpointcsz;
  wrk.delpointcsz := null;
end if;

if rtrim(wrk.branchaddress2) is null then
  wrk.branchaddress2 := wrk.branchcsz;
  wrk.branchcsz := null;
end if;

commit;


wrk.carrier := trim(wrk.carrier);
while length(wrk.carrier) < 4
loop
  wrk.carrier := nvl(wrk.carrier,'-') || '-';
end loop;

wrk.numPoMemo := 0;
if in_bolreqtype = 'POME' then
  cvb := null;
  open curCustVicsBol;
  fetch curCustVicsBol into cvb;
  close curCustVicsBol;
  begin
    wrk.lastupdate := sysdate;
    insert into bolrequest_shipments
      select in_vicsessionid,in_vicsequence,stopno,shipno,count(1),wrk.lastupdate
        from orderhdr oh
       where loadno = in_loadno
         and stopno = in_stopno
         and shipno = in_shipno
         and exists
             (select *
                from custvicsbolcopies cvbc
               where cvbc.custid = oh.custid
                 and cvbc.custid = cvb.custid
                 and nvl(cvbc.shipto,'x') = nvl(cvb.shipto,'x')
                 and cvbc.ordertype = cvb.ordertype
                 and cvbc.reportname = cvb.reportname
                 and cvbc.boltype = 'POME')
       group by in_vicsessionid,in_vicsequence,stopno,shipno,wrk.lastupdate
             having count(1) > 1;
    commit;
    select count(1)
      into wrk.numPoMemo
      from bolrequest_shipments
     where vicsessionid = in_vicsessionid
       and vicsequence = in_vicsequence;
  exception when others then
    null;
  end;
end if;

insert into bolrequest_header
values
(wrk.vicsessionid,wrk.vicsequence,wrk.billoflading,wrk.carrier,
wrk.prono,wrk.facility,wrk.seal,wrk.trailer,wrk.carriername,
wrk.branchaddress1,wrk.branchaddress2,wrk.branchcsz,
wrk.companyname,wrk.delpointaddr1,wrk.delpointaddr2,
wrk.delpointname,wrk.delpointcsz,wrk.freightterms,
wrk.numstops,wrk.delpointtype,wrk.freightline1,
wrk.freightline2,wrk.freightline3,wrk.freightline4,
wrk.numpomemo,sysdate);

<<return_vics_rows>>

commit;

open bolrequest_header_cursor for
 select *
   from bolrequest_header
  where vicsessionid = in_vicsessionid
    and vicsequence = in_vicsequence;

end bolheaderproc;
/
show errors package bolheaderpkg;
show errors procedure bolheaderproc;
exit;
