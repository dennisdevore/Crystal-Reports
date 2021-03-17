drop table pklrequest;

create table pklrequest
(pklsessionid       number(7)
,orderid         number(9)
,shipid          number(2)
,rptformat       varchar2(255)
,printerid       varchar2(255)
,lastuser        varchar2(255)
,lastupdate      date
);

create index pklrequest_pklsessionid_idx
 on pklrequest(pklsessionid);

create index pklrequest_lastupdate_idx
 on pklrequest(lastupdate);

create or replace package pklrequestpkg
as type pklrequest_type is ref cursor return pklrequest%rowtype;
end pklrequestpkg;
/
create or replace procedure pklrequestproc
(in_userid varchar2
,in_orderid number
,in_shipid number
,in_printerid varchar2
,in_debug_yn IN varchar2
,out_pklsessionid IN OUT number)
as
--
-- $Id$
--

cursor curOrderHdr is
  select orderid,
         shipid,
         custid
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curPrinter is
  select defaultprinter
    from userheader
   where nameid = in_userid;
prt curPrinter%rowtype;

numpklsessionid number;
cntRows integer;
wrk pklrequest%rowtype;
cu customer%rowtype;

begin

select sys_context('USERENV','SESSIONID')
 into numpklsessionid
 from dual;

out_pklsessionid := numpklsessionid;

delete from pklrequest
where pklsessionid = numpklsessionid;
commit;

delete from pklrequest
where lastupdate < trunc(sysdate);
commit;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.orderid is null then
  return;
end if;

if ( trim(in_printerid) is null or
     in_printerid = 'NONE'  ) then
  prt := null;
  open curPrinter;
  fetch curPrinter into prt;
  close curPrinter;
  if trim(prt.defaultprinter) is null then
    prt.defaultprinter := 'DEFAULT';
  end if;
else
  prt.defaultprinter := in_printerid;
end if;

wrk := null;
wrk.pklsessionid := numpklsessionid;
wrk.orderid := oh.orderid;
wrk.shipid := oh.shipid;
zcu.pack_list_format(oh.orderid,oh.shipid,cu.packlist,cu.packlistrptfile);
wrk.rptformat := cu.packlistrptfile;
wrk.printerid := prt.defaultprinter;
insert into pklrequest
values
(wrk.pklsessionid,wrk.orderid,wrk.shipid,wrk.rptformat,wrk.printerid,
 in_userid,sysdate);

commit;

end pklrequestproc;
/
show errors package pklrequestpkg;
show errors procedure pklrequestproc;
--exit;
