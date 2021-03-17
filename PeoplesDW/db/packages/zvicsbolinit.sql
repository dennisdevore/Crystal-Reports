drop table bolrequest_init;

create table bolrequest_init
(vicsessionid       number(7)
,loadno          number(7)
,lastupdate      date
);

create index bolinit_vicsessionid_idx
 on bolrequest_init(vicsessionid);

create index bolinit_lastupdate_idx
 on bolrequest_init(lastupdate);

create or replace package bolinitpkg
as type bolrequest_init_type is ref cursor return bolrequest_init%rowtype;
end bolinitpkg;
/
create or replace procedure bolinitproc
(bolrequest_init_cursor IN OUT bolinitpkg.bolrequest_init_type
,in_vicsessionid number
,in_loadno number
,in_debug_yn IN varchar2)
as
--
-- $Id$
--

begin

delete from bolrequest_init
where vicsessionid = in_vicsessionid;
commit;

delete from bolrequest_init
where lastupdate < trunc(sysdate);
commit;

insert into bolrequest_init
 values
(in_vicsessionid,in_loadno,sysdate);

commit;

open bolrequest_init_cursor for
 select *
   from bolrequest_init
  where vicsessionid = in_vicsessionid;

end bolinitproc;
/
show errors package bolinitpkg;
show errors procedure bolinitproc;
--exit;
