  create or replace view cntnrs_summary_rpt_view
  (report_type,
   facility,
   trailer,
   custid,
   carrier)
  as 
  select distinct
         1,
         ld.facility,
         ld.trailer,
         nvl(oh.custid,'(none)'),
         null
    from loads ld,
         orderhdr oh
   where ld.loadno = oh.loadno(+)
     and ld.loadstatus in ('1','2')
     and ld.arrivedinyard is not null
   union
  select distinct
         2,
         ld.facility,
         ld.trailer,
         nvl(oh.custid,'(none)'),
         null
    from loads ld,
         orderhdr oh
   where ld.loadno = oh.loadno(+)
     and ld.loadstatus in ('A','E')
   union
  select distinct
         3,
         ld.facility,
         ld.trailer,
         null,
         nvl(ld.carrier,'(none)')
    from loads ld
   where ld.loadstatus = 'R'
     and ld.returnedtoport is null;

  create or replace view cntnrs_web_summary_rpt_view
  (report_type,
   facility,
   trailer,
   custid,
   carrier)
  as 
  select distinct
         1,
         ld.facility,
         ld.trailer,
         nvl(oh.custid,'(none)'),
         null
    from loads ld,
         orderhdr oh
   where ld.loadno = oh.loadno(+)
     and ld.loadstatus in ('1','2')
     and ld.arrivedinyard is not null
   union
  select distinct
         2,
         ld.facility,
         ld.trailer,
         nvl(oh.custid,'(none)'),
         null
    from loads ld,
         orderhdr oh
   where ld.loadno = oh.loadno(+)
     and ld.loadstatus in ('A','E')
   union
  select distinct
         3,
         ld.facility,
         ld.trailer,
         nvl(oh.custid,'(none)'),
         nvl(ld.carrier,'(none)')
    from loads ld,
         orderhdr oh
   where ld.loadstatus = 'R'
     and ld.returnedtoport is null
     and ld.loadno = oh.loadno(+);

  create or replace view cntnrs_in_yard_rpt_view
  (facility,
   custid,
   custname,
   trailer,
   carrier,
   carriername,
   arrivedinyard)
  as 
  select distinct
         ld.facility,
         nvl(oh.custid,'(none)'),
         nvl(cu.name,'(none)'),
         ld.trailer,
         ld.carrier,
         nvl(ca.name,'(none)'),
         ld.arrivedinyard
    from loads ld,
         orderhdr oh,
         customer cu,
         carrier ca
   where ld.loadno = oh.loadno(+)
     and oh.custid = cu.custid(+)
     and ld.carrier = ca.carrier(+)
     and ld.loadstatus in ('1','2')
     and ld.arrivedinyard is not null;

  create or replace view cntnrs_at_dock_rpt_view
  (facility,
   custid,
   custname,
   trailer,
   carrier,
   carriername,
   door,
   loadstatus,
   loadstatusabbrev)
  as 
  select distinct
         ld.facility,
         nvl(oh.custid,'(none)'),
         nvl(cu.name,'(none)'),
         ld.trailer,
         ld.carrier,
         nvl(ca.name,'(none)'),
         ld.doorloc,
         ld.loadstatus,
         ls.abbrev
    from loads ld,
         orderhdr oh,
         customer cu,
         carrier ca,
         loadstatus ls
   where ld.loadno = oh.loadno(+)
     and oh.custid = cu.custid(+)
     and ld.carrier = ca.carrier(+)
     and ld.loadstatus in ('A','E')
     and ld.loadstatus = ls.code;

  create or replace view cntnrs_empty_rpt_view
  (facility,
   custid,
   custname,
   trailer,
   carrier,
   carriername,
   carriercontactdate)
  as 
  select distinct
         ld.facility,
         nvl(oh.custid,'(none)'),
         nvl(cu.name,'(none)'),
         ld.trailer,
         ld.carrier,
         nvl(ca.name,'(none)'),
         ld.carriercontactdate
    from loads ld,
         orderhdr oh,
         customer cu,
         carrier ca
   where ld.loadno = oh.loadno(+)
     and oh.custid = cu.custid(+)
     and ld.carrier = ca.carrier(+)
     and ld.loadstatus = 'R'
     and ld.returnedtoport is null;

 comment on table cntnrs_in_yard_rpt_view is '$Id: container_rpt_views.sql 1 2006-12-21 00:00:00Z eric $';

 exit;
