drop table pklrequest_init;

create table pklrequest_init
(pklsessionid      number(7)
,orderid           number(9)
,shipid            number(7)
,po                varchar2(20)
,reference         varchar2(20)
,orderstatus       varchar2(1)
,orderstatusabbrev varchar2(12)
,lastupdate        date
);

create index pklinit_pklsessionid_idx
 on pklrequest_init(pklsessionid);

create index pklinit_lastupdate_idx
 on pklrequest_init(lastupdate);

create or replace package pklinitpkg
as type pklrequest_init_type is ref cursor return pklrequest_init%rowtype;
end pklinitpkg;
/
create or replace procedure pklinitproc
(pklrequest_init_cursor IN OUT pklinitpkg.pklrequest_init_type
,in_pklsessionid number
,in_orderid number
,in_shipid number
,in_debug_yn IN varchar2)
as
--
-- $Id$
--

cursor curOrderHdr is
  select po,reference,orderstatus
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

strAbbrev orderstatus.abbrev%type;

begin

delete from pklrequest_init
where pklsessionid = in_pklsessionid;
commit;

delete from pklrequest_init
where lastupdate < trunc(sysdate);
commit;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;

begin
  select abbrev
    into strabbrev
    from orderstatus
   where code = oh.orderstatus;
exception when others then
  strAbbrev := oh.orderstatus;
end;

insert into pklrequest_init
 values
(in_pklsessionid,in_orderid,in_shipid,oh.po,oh.reference,oh.orderstatus,
 strabbrev,sysdate);

commit;

open pklrequest_init_cursor for
 select *
   from pklrequest_init
  where pklsessionid = in_pklsessionid;

end pklinitproc;
/
show errors package pklinitpkg;
show errors procedure pklinitproc;
--exit;
