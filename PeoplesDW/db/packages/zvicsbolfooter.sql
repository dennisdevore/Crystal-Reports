drop table bolrequest_footer;

create table bolrequest_footer
(vicsessionid       number(7)
,vicsequence        number(7)
,declaredvalue   varchar2(255)
,shiptype        varchar2(1)
,countedby       varchar2(1)
,loadedby        varchar2(1)
,shipdate        varchar2(8)
,lastupdate      date
,shippersignature varchar2(255)
);

create index bolrequest_foot_sessionid_idx
 on bolrequest_footer(vicsessionid,vicsequence);

create index bolrequest_foot_lastupdate_idx
 on bolrequest_footer(lastupdate);

create or replace package bolfooterpkg
as type bolrequest_footer_type is ref cursor return bolrequest_footer%rowtype;
end bolfooterpkg;
/
create or replace procedure bolfooterproc
(bolrequest_footer_cursor IN OUT bolfooterpkg.bolrequest_footer_type
,in_vicsessionid number
,in_vicsequence number
,in_loadno number
,in_debug_yn IN varchar2)
as
--
-- $Id$
--

cursor curLoads is
  select loadno,
         shiptype,
         countedby,
         loadedby,
         statusupdate,
         facility
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;

cursor curFacility(in_facility varchar2) is
  select shippersignature
    from facility
   where facility = in_facility;

cursor curOrdersByLoad is
  select orderid,shipid,shipterms,shiptype
    from orderhdr
   where loadno = in_loadno
   order by orderid,shipid;
oi curOrdersByLoad%rowtype;

cntRows integer;
wrk bolrequest_footer%rowtype;

begin

delete from bolrequest_footer
where vicsessionid = in_vicsessionid
  and vicsequence = in_vicsequence;
commit;

delete from bolrequest_footer
where lastupdate < trunc(sysdate);
commit;

wrk := null;
wrk.vicsessionid := in_vicsessionid;
wrk.vicsequence := in_vicsequence;

ld := null;
open curLoads;
fetch curLoads into ld;
close curLoads;
if ld.loadno is null then
  goto return_vics_rows;
end if;

if ld.shiptype is null then
  open curOrdersByLoad;
  fetch curOrdersByLoad into oi;
  close curOrdersByLoad;
  ld.shiptype := oi.shiptype;
end if;

open curFacility(ld.facility);
fetch curFacility into wrk.shippersignature;
close curFacility;

wrk.declaredvalue := trim(zci.default_value('VICSDECLAREDVALUE'));

insert into bolrequest_footer
values
(wrk.vicsessionid,wrk.vicsequence,wrk.declaredvalue,ld.shiptype,
ld.countedby,ld.loadedby,to_char(ld.statusupdate,'MM/DD/YY'),
sysdate,wrk.shippersignature);

<<return_vics_rows>>

commit;

open bolrequest_footer_cursor for
 select *
   from bolrequest_footer
  where vicsessionid = in_vicsessionid
    and vicsequence = in_vicsequence;

end bolfooterproc;
/
show errors package bolfooterpkg;
show errors procedure bolfooterproc;
--exit;
