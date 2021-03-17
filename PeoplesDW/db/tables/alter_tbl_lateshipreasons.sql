--
-- $Id$
--
create table lateshipreasons
(
  code        varchar2(12) not null,
  descr       varchar2(32) not null,
  abbrev      varchar2(12) not null,
  dtlupdate   varchar2(1),
  lastuser    varchar2(12),
  lastupdate  date
);
insert into tabledefs
   values('LateShipReasons', 'N', 'Y', '>Aa;0;_', 'SUP', sysdate);
insert into lateshipreasons(code, descr, abbrev, dtlupdate,
    lastuser, lastupdate)
values ('CL','Carrier Late','CarrierLate','Y','SUP',sysdate);
insert into lateshipreasons(code, descr, abbrev, dtlupdate,
    lastuser, lastupdate)
values ('FM','Facility Maintenance','FacilityMnt','Y','SUP',sysdate);
insert into lateshipreasons(code, descr, abbrev, dtlupdate,
    lastuser, lastupdate)
values ('MP','Mechanical Problems','Mechanical','Y','SUP',sysdate);
insert into lateshipreasons(code, descr, abbrev, dtlupdate,
    lastuser, lastupdate)
values ('OC','Order Changes','OrderChg','Y','SUP',sysdate);
insert into lateshipreasons(code, descr, abbrev, dtlupdate,
    lastuser, lastupdate)
values ('SD','System Down','SysDown','Y','SUP',sysdate);
insert into lateshipreasons(code, descr, abbrev, dtlupdate,
    lastuser, lastupdate)
values ('SY','System Error','SysError','Y','SUP',sysdate);
insert into lateshipreasons(code, descr, abbrev, dtlupdate,
    lastuser, lastupdate)
values ('WR','Weather Releated','Weather','Y','SUP',sysdate);
exit;
