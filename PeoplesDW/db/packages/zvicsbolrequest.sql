drop table bolrequest;

create table bolrequest
(vicsessionid       number(7)
,vicsequence        number(7)
,loadno          number(7)
,stopno          number(7)
,shipno          number(7)
,orderid         number(9)
,shipid          number(2)
,bolreqtype      varchar2(4)
,order_addl_yn   varchar2(1)
,carrier_addl_yn varchar2(1)
,instr_addl_yn   varchar2(1)
,copymsg         varchar2(36)
,rpttitle        varchar2(36)
,boltitle        varchar2(36)
,rptformat       varchar2(255)
,printerid       varchar2(255)
,lastuser        varchar2(255)
,cvbrowid        varchar2(18)
,lastupdate      date
);

create index bolrequest_vicsessionid_idx
 on bolrequest(vicsessionid);

create index bolrequest_lastupdate_idx
 on bolrequest(lastupdate);

create or replace package bolrequestpkg
as type bolrequest_type is ref cursor return bolrequest%rowtype;
end bolrequestpkg;
/
create or replace procedure bolrequestproc
(in_userid varchar2
,in_loadno number
,in_debug_yn IN varchar2
,out_vicsessionid IN OUT number)
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
         shiptype,
         billoflading
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;

cursor curPrinter is
  select vicsbolprinter
    from userheader
   where nameid = in_userid;
prt curPrinter%rowtype;

cursor curCustVicsBol(in_custid varchar2, in_shipto varchar2, in_ordertype varchar2) is
  select rowid,custid,shipto,ordertype,reportname
    from custvicsbol
   where custid = in_custid
     and nvl(shipto,'x') = nvl(in_shipto,'x')
     and ( (ordertype = in_ordertype) or
           (ordertype = 'A') );
cvb curCustVicsBol%rowtype;

ordcur bolorderpkg.bolrequest_order_type;
ordset bolrequest_order%rowtype;
carcur bolcarrierpkg.bolrequest_carrier_type;
carset bolrequest_carrier%rowtype;
comcur bolcommentpkg.bolrequest_comment_type;
comset bolrequest_comment%rowtype;
numvicsessionid number;
numStops number;
cntRows integer;
wrk bolrequest%rowtype;
cvbc custvicsbolcopies%rowtype;
ord orderhdr%rowtype;

function get_rpt_title(in_bolreqtype varchar2) return varchar2
is
out_rpt_title vics_bol_types.descr%type;
begin

out_rpt_title := in_bolreqtype || ' Bill of Lading';

select descr
  into out_rpt_title
  from vics_bol_types
 where code = in_bolreqtype;

return out_rpt_title;
exception when others then
  return out_rpt_title;
end;

begin

select sys_context('USERENV','SESSIONID')
 into numvicsessionid
 from dual;

out_vicsessionid := numvicsessionid;

delete from bolrequest
where vicsessionid = numvicsessionid;
commit;

delete from bolrequest
where lastupdate < trunc(sysdate);
commit;

ld := null;
open curLoads;
fetch curLoads into ld;
close curLoads;
if ld.loadno is null then
  return;
end if;

prt := null;
open curPrinter;
fetch curPrinter into prt;
close curPrinter;
if trim(prt.vicsbolprinter) is null then
  prt.vicsbolprinter := 'DEFAULT';
end if;

if in_debug_yn = 'Y' then
  zut.prt('count stops');
end if;

begin
  select count(1)
    into numStops
    from loadstop
   where loadno = in_loadno;
exception when others then
  numStops := 1;
end;

<<master_bill>>

wrk := null;
wrk.vicsessionid := numvicsessionid;
wrk.vicsequence := 0;
wrk.loadno := in_loadno;
wrk.stopno := 0;
wrk.shipno := 0;
wrk.orderid := 0;
wrk.shipid := 0;
wrk.bolreqtype := 'MAST';
wrk.rpttitle := get_rpt_title(wrk.bolreqtype);
wrk.printerid := prt.vicsbolprinter;

--no master bills for LTL's

if in_debug_yn = 'Y' then
  zut.prt('check vics config');
end if;

cvb := null;
for oh in (select distinct custid,shipto,ordertype,
                  loadno,stopno,shipno,orderid,shipid,
                  shiptype
             from orderhdr
            where loadno = in_loadno
            order by loadno,stopno,shipno,orderid,shipid)
loop
  if in_debug_yn = 'Y' then
    zut.prt('cust ' || oh.custid || ' shipto ' || oh.shipto ||
            ' ordertype ' || oh.ordertype);
  end if;
  cvb := null;
  open curCustVicsBol(oh.custid,oh.shipto,oh.ordertype);
  fetch curCustVicsBol into cvb;
  close curCustVicsBol;
  if cvb.reportname is not null then
    wrk.rptformat := cvb.reportname;
    wrk.cvbrowid := cvb.rowid;
    ord.shiptype := oh.shiptype;
    exit;
  end if;
  open curCustVicsBol(oh.custid,null,oh.ordertype);
  fetch curCustVicsBol into cvb;
  close curCustVicsBol;
  if cvb.reportname is not null then
    wrk.rptformat := cvb.reportname;
    wrk.cvbrowid := cvb.rowid;
    ord.shiptype := oh.shiptype;
    exit;
  end if;
end loop;

if nvl(ld.shiptype,ord.shiptype) = 'L' then
  goto stop_bill;
end if;

if in_debug_yn = 'Y' then
  zut.prt('get title');
end if;

wrk.boltitle := 'Bill ';
if trim(ld.billoflading) is null then
  wrk.boltitle := wrk.boltitle || trim(to_char(in_loadno));
else
  wrk.boltitle := wrk.boltitle || trim(ld.billoflading);
end if;

if in_debug_yn = 'Y' then
  zut.prt('check vics copies');
end if;

for cvbc in
  (select copymsg
     from custvicsbolcopies
    where custid = cvb.custid
      and nvl(shipto,'x') = nvl(cvb.shipto,'x')
      and ordertype = cvb.ordertype
      and reportname = cvb.reportname
      and boltype = wrk.bolreqtype)
loop
  wrk.vicsequence := wrk.vicsequence + 1;
  wrk.copymsg := cvbc.copymsg;
  wrk.order_addl_yn := 'N';
  wrk.carrier_addl_yn := 'N';
  wrk.instr_addl_yn := 'N';
  if in_debug_yn = 'Y' then
    zut.prt('before order proc');
  end if;
  bolorderproc(ordcur,wrk.vicsessionid,wrk.vicsequence,wrk.bolreqtype,'C',
    wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
    in_debug_yn);
  if ordcur%isopen then
    fetch ordcur into ordset;
    if ordset.numstops > 6 then
      wrk.order_addl_yn := 'Y';
    end if;
    close ordcur;
  end if;
  if in_debug_yn = 'Y' then
    zut.prt('before carrier proc');
  end if;
  bolcarrierproc(carcur,wrk.vicsessionid,wrk.vicsequence,wrk.bolreqtype,'C',
    wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
    in_debug_yn);
  if carcur%isopen then
    fetch carcur into carset;
    zut.prt('carrier numstop test');
    if carset.numstops > 6 then
      wrk.carrier_addl_yn := 'Y';
    end if;
    close carcur;
  end if;
  if in_debug_yn = 'Y' then
    zut.prt('before comment proc');
  end if;
  bolcommentproc(comcur,wrk.vicsessionid,wrk.vicsequence,wrk.bolreqtype,'C',
    wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
    in_debug_yn);
  if comcur%isopen then
    fetch comcur into comset;
    if comset.numstops > 6 then
      wrk.instr_addl_yn := 'Y';
    end if;
    close comcur;
  end if;
  insert into bolrequest
    values
  (wrk.vicsessionid,wrk.vicsequence,wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
   wrk.bolreqtype,wrk.order_addl_yn,wrk.carrier_addl_yn,wrk.instr_addl_yn,wrk.copymsg,
   wrk.rpttitle,wrk.boltitle,wrk.rptformat,wrk.printerid,in_userid,wrk.cvbrowid,sysdate);
  commit;
end loop;

<<stop_bill>>

if (nvl(ld.shiptype,ord.shiptype) = 'L') or
   (numstops = 1) then
  goto shipment_bill;
end if;

wrk.bolreqtype := 'STOP';
wrk.rpttitle := get_rpt_title(wrk.bolreqtype);


for cvbc in
  (select copymsg
     from custvicsbolcopies
    where custid = cvb.custid
      and nvl(shipto,'x') = nvl(cvb.shipto,'x')
      and ordertype = cvb.ordertype
      and reportname = cvb.reportname
      and boltype = wrk.bolreqtype)
loop
  for sh in
    (select stopno
       from loadstop
      where loadno = in_loadno
      order by stopno)
  loop
    wrk.boltitle := 'Bill ';
    wrk.stopno := sh.stopno;
    if trim(ld.billoflading) is null then
      wrk.boltitle := wrk.boltitle || trim(to_char(in_loadno))
        || '-' || trim(to_char(wrk.stopno));
    else
      wrk.boltitle := wrk.boltitle || trim(ld.billoflading)
        || '-' || trim(to_char(wrk.stopno));
    end if;
    wrk.vicsequence := wrk.vicsequence + 1;
    wrk.copymsg := cvbc.copymsg;
    wrk.order_addl_yn := 'N';
    wrk.carrier_addl_yn := 'N';
    wrk.instr_addl_yn := 'N';
    if in_debug_yn = 'Y' then
      zut.prt('before order proc for stop');
    end if;
    bolorderproc(ordcur,wrk.vicsessionid,wrk.vicsequence,wrk.bolreqtype,'C',
      wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
      in_debug_yn);
    if ordcur%isopen then
      fetch ordcur into ordset;
      if ordset.numstops > 6 then
        wrk.order_addl_yn := 'Y';
      end if;
      close ordcur;
    end if;
    if in_debug_yn = 'Y' then
      zut.prt('before carrier proc for stop');
    end if;
    bolcarrierproc(carcur,wrk.vicsessionid,wrk.vicsequence,wrk.bolreqtype,'C',
      wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
      in_debug_yn);
    if carcur%isopen then
      fetch carcur into carset;
      zut.prt('carrier numstop test');
      if carset.numstops > 6 then
        wrk.carrier_addl_yn := 'Y';
      end if;
      close carcur;
    end if;
    if in_debug_yn = 'Y' then
      zut.prt('before comment proc for stop');
    end if;
    bolcommentproc(comcur,wrk.vicsessionid,wrk.vicsequence,wrk.bolreqtype,'C',
      wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
      in_debug_yn);
    if comcur%isopen then
      fetch comcur into comset;
      if comset.numstops > 6 then
        wrk.instr_addl_yn := 'Y';
      end if;
      close comcur;
    end if;
    insert into bolrequest
      values
    (wrk.vicsessionid,wrk.vicsequence,wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
     wrk.bolreqtype,wrk.order_addl_yn,wrk.carrier_addl_yn,wrk.instr_addl_yn,wrk.copymsg,
     wrk.rpttitle,wrk.boltitle,wrk.rptformat,wrk.printerid,in_userid,wrk.cvbrowid,sysdate);
    commit;
  end loop;
end loop;

<<shipment_bill>>

wrk.bolreqtype := 'SHIP';
wrk.rpttitle := get_rpt_title(wrk.bolreqtype);

for cvbc in
  (select copymsg
     from custvicsbolcopies
    where custid = cvb.custid
      and nvl(shipto,'x') = nvl(cvb.shipto,'x')
      and ordertype = cvb.ordertype
      and reportname = cvb.reportname
      and boltype = wrk.bolreqtype)
loop
  for sh in
    (select stopno,shipno
       from loadstopship
      where loadno = in_loadno
      order by stopno,shipno)
  loop
    wrk.boltitle := 'Bill ';
    wrk.stopno := sh.stopno;
    wrk.shipno := sh.shipno;
    if trim(ld.billoflading) is null then
      wrk.boltitle := wrk.boltitle || trim(to_char(in_loadno))
        || '-' || trim(to_char(wrk.shipno));
    else
      wrk.boltitle := wrk.boltitle || trim(ld.billoflading)
        || '-' || trim(to_char(wrk.shipno));
    end if;
    wrk.vicsequence := wrk.vicsequence + 1;
    wrk.copymsg := cvbc.copymsg;
    wrk.order_addl_yn := 'N';
    wrk.carrier_addl_yn := 'N';
    wrk.instr_addl_yn := 'N';
    if in_debug_yn = 'Y' then
      zut.prt('before order proc for shipment');
    end if;
    bolorderproc(ordcur,wrk.vicsessionid,wrk.vicsequence,wrk.bolreqtype,'C',
      wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
      in_debug_yn);
    if ordcur%isopen then
      fetch ordcur into ordset;
      if ordset.numstops > 6 then
        wrk.order_addl_yn := 'Y';
      end if;
      close ordcur;
    end if;
    if in_debug_yn = 'Y' then
      zut.prt('before carrier proc for shipment');
    end if;
    bolcarrierproc(carcur,wrk.vicsessionid,wrk.vicsequence,wrk.bolreqtype,'C',
      wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
      in_debug_yn);
    if carcur%isopen then
      fetch carcur into carset;
      zut.prt('carrier numstop test');
      if carset.numstops > 6 then
        wrk.carrier_addl_yn := 'Y';
      end if;
      close carcur;
    end if;
    if in_debug_yn = 'Y' then
      zut.prt('before comment proc for shipment');
    end if;
    bolcommentproc(comcur,wrk.vicsessionid,wrk.vicsequence,wrk.bolreqtype,'C',
      wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
      in_debug_yn);
    if comcur%isopen then
      fetch comcur into comset;
      if comset.numstops > 6 then
        wrk.instr_addl_yn := 'Y';
      end if;
      close comcur;
    end if;
    insert into bolrequest
      values
    (wrk.vicsessionid,wrk.vicsequence,wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
     wrk.bolreqtype,wrk.order_addl_yn,wrk.carrier_addl_yn,wrk.instr_addl_yn,wrk.copymsg,
     wrk.rpttitle,wrk.boltitle,wrk.rptformat,wrk.printerid,in_userid,wrk.cvbrowid,sysdate);
    commit;
  end loop;
end loop;

<<pomemo_bill>>

wrk.bolreqtype := 'POME';
wrk.rpttitle := get_rpt_title(wrk.bolreqtype);

for cvbc in
  (select copymsg
     from custvicsbolcopies
    where custid = cvb.custid
      and nvl(shipto,'x') = nvl(cvb.shipto,'x')
      and ordertype = cvb.ordertype
      and reportname = cvb.reportname
      and boltype = wrk.bolreqtype)
loop
 for pome in
   (select stopno,shipno,count(1) as count
      from orderhdr
     where loadno = in_loadno
     group by stopno,shipno
     having count(1) > 1)
 loop
  for sh in
    (select stopno,shipno,orderid,shipid
       from orderhdr
      where loadno = in_loadno
        and stopno = pome.stopno
        and shipno = pome.shipno
      order by stopno,shipno,orderid,shipid)
  loop
    wrk.boltitle := 'Bill ';
    wrk.stopno := sh.stopno;
    wrk.shipno := sh.shipno;
    wrk.orderid := sh.orderid;
    wrk.shipid := sh.shipid;
    if trim(ld.billoflading) is null then
      wrk.boltitle := wrk.boltitle || trim(to_char(in_loadno))
        || '-' || trim(to_char(wrk.shipno));
    else
      wrk.boltitle := wrk.boltitle || trim(ld.billoflading)
        || '-' || trim(to_char(wrk.shipno));
    end if;
    wrk.vicsequence := wrk.vicsequence + 1;
    wrk.copymsg := cvbc.copymsg;
    wrk.order_addl_yn := 'N';
    wrk.carrier_addl_yn := 'N';
    wrk.instr_addl_yn := 'N';
    if in_debug_yn = 'Y' then
      zut.prt('before order proc for shipment');
    end if;
    bolorderproc(ordcur,wrk.vicsessionid,wrk.vicsequence,wrk.bolreqtype,'C',
      wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
      in_debug_yn);
    if ordcur%isopen then
      fetch ordcur into ordset;
      if ordset.numstops > 6 then
        wrk.order_addl_yn := 'Y';
      end if;
      close ordcur;
    end if;
    if in_debug_yn = 'Y' then
      zut.prt('before carrier proc for shipment');
    end if;
    bolcarrierproc(carcur,wrk.vicsessionid,wrk.vicsequence,wrk.bolreqtype,'C',
      wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
      in_debug_yn);
    if carcur%isopen then
      fetch carcur into carset;
      zut.prt('carrier numstop test');
      if carset.numstops > 6 then
        wrk.carrier_addl_yn := 'Y';
      end if;
      close carcur;
    end if;
    if in_debug_yn = 'Y' then
      zut.prt('before comment proc for shipment');
    end if;
    bolcommentproc(comcur,wrk.vicsessionid,wrk.vicsequence,wrk.bolreqtype,'C',
      wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
      in_debug_yn);
    if comcur%isopen then
      fetch comcur into comset;
      if comset.numstops > 6 then
        wrk.instr_addl_yn := 'Y';
      end if;
      close comcur;
    end if;
    if in_debug_yn = 'Y' then
      zut.prt('after comment proc for shipment');
    end if;
    insert into bolrequest
      values
    (wrk.vicsessionid,wrk.vicsequence,wrk.loadno,wrk.stopno,wrk.shipno,wrk.orderid,wrk.shipid,
     wrk.bolreqtype,wrk.order_addl_yn,wrk.carrier_addl_yn,wrk.instr_addl_yn,wrk.copymsg,
     wrk.rpttitle,wrk.boltitle,wrk.rptformat,wrk.printerid,in_userid,wrk.cvbrowid,sysdate);
    commit;
  end loop;
 end loop;
end loop;

commit;

end bolrequestproc;
/
show errors package bolrequestpkg;
show errors procedure bolrequestproc;
--exit;
