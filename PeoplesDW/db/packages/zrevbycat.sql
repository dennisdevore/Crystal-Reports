drop table revbycat;

-- trantype column values:
--    AA-column headers
--    DT-Detail

create table revbycat
(sessionid        number
,facility         varchar2(3)
,custid           varchar2(10)
,masterinvoice    varchar2(8)
,invoice          number(8)
,trantype         varchar2(2)
,colhead1        varchar2(12)
,colhead2        varchar2(12)
,colhead3        varchar2(12)
,colhead4        varchar2(12)
,colhead5        varchar2(12)
,colhead6        varchar2(12)
,colhead7        varchar2(12)
,colhead8        varchar2(12)
,colhead9        varchar2(12)
,custname         varchar2(40)
,amt1            number(16,2)
,amt2            number(16,2)
,amt3            number(16,2)
,amt4            number(16,2)
,amt5            number(16,2)
,amt6            number(16,2)
,amt7            number(16,2)
,amt8            number(16,2)
,amt9            number(16,2)
,reporttitle      varchar2(255)
,lastupdate       date
);

create index revbycat_sessionid_idx
 on revbycat(sessionid,facility,custid,trantype);

create index revbycat_lastupdate_idx
 on revbycat(lastupdate);

create or replace package revbycatpkg
as type rbc_type is ref cursor return revbycat%rowtype;
end revbycatpkg;
/


create or replace procedure revbycatdateselproc
(rbc_cursor IN OUT revbycatpkg.rbc_type
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_activity IN varchar2
,in_debug_yn IN varchar2
,in_datetype IN number)
as
--
-- $Id$
--

MAXREVCAT constant integer := 9;

type revcattype is record(
  revenuegroup  varchar2(4),
  revenuegroupabbrev varchar2(12)
);

type revcattbltype is table of revcattype
   index by binary_integer;

revcats revcattbltype;

cursor curCustomer(in_custid varchar2) is
  select name
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curRevenueGroups(in_facility IN varchar2, in_activity IN varchar2, in_begdate IN date, in_enddate IN date) is
  select nvl(ac.revenuegroup,'????') revenuegroup,
         count(1) groupcount
    from invoicehdr ih, invoicedtl id, activity ac
   where nvl(in_datetype,1) = 1
     and (instr(','||in_facility||',', ','||ih.facility||',', 1, 1) > 0
      or  in_facility='ALL')
     and ih.invoicedate >= in_begdate
     and ih.invoicedate <  in_enddate
     and ih.invstatus = '3'
     and id.invoice = ih.invoice
     and id.billstatus='3'
     and (instr(','||in_activity||',', ','||id.activity||',', 1, 1) > 0
      or  in_activity='ALL')
     and ac.code = id.activity
   group by ac.revenuegroup
   union
  select nvl(ac.revenuegroup,'????') revenuegroup,
         count(1) groupcount
    from invoicehdr ih, invoicedtl id, activity ac
   where nvl(in_datetype,1) = 2
     and (instr(','||in_facility||',', ','||ih.facility||',', 1, 1) > 0
      or  in_facility='ALL')
     and ih.postdate >= in_begdate
     and ih.postdate <  in_enddate
     and ih.invstatus = '3'
     and id.invoice = ih.invoice
     and id.billstatus='3'
     and (instr(','||in_activity||',', ','||id.activity||',', 1, 1) > 0
      or  in_activity='ALL')
     and ac.code = id.activity
   group by ac.revenuegroup
   order by 2 desc;
rev curRevenueGroups%rowtype;

cursor curInvoiceHdr(in_facility IN varchar2, in_activity IN varchar2, in_begdate IN date, in_enddate IN date) is
  select ih.facility,
         ih.custid,
         ih.masterinvoice,
         ih.invoice,
         ih.invtype,
         id.activity,
         nvl(id.billedamt,0) billedamt
    from invoicehdr ih, invoicedtl id
   where nvl(in_datetype,1) = 1
     and (instr(','||in_facility||',', ','||ih.facility||',', 1, 1) > 0
      or  in_facility='ALL')
     and ih.invoicedate >= in_begdate
     and ih.invoicedate <  in_enddate
     and ih.invstatus = '3'
     and id.invoice = ih.invoice
     and id.billstatus='3'
     and (instr(','||in_activity||',', ','||id.activity||',', 1, 1) > 0
      or  in_activity='ALL')
   union all
  select ih.facility,
         ih.custid,
         ih.masterinvoice,
         ih.invoice,
         ih.invtype,
         id.activity,
         nvl(id.billedamt,0) billedamt
    from invoicehdr ih, invoicedtl id
   where nvl(in_datetype,1) = 2
     and (instr(','||in_facility||',', ','||ih.facility||',', 1, 1) > 0
      or  in_facility='ALL')
     and ih.postdate >= in_begdate
     and ih.postdate <  in_enddate
     and ih.invstatus = '3'
     and id.invoice = ih.invoice
     and id.billstatus='3'
     and (instr(','||in_activity||',', ','||id.activity||',', 1, 1) > 0
      or  in_activity='ALL');
hdr curInvoiceHdr%rowtype;

numSessionId number;
wrk revbycat%rowtype;
strRevenueGroup activity.revenuegroup%type;
strRevenueGroupAbbrev revenuereportgroups.abbrev%type;
intRevenueNumber integer;
idxRevCat integer;
revcatfound boolean;
cntRows integer;
curSql integer;
strColName varchar2(30);
numLength integer;
amtMultiplier integer;

procedure debugmsg(in_msg varchar2)
is
begin
  if upper(in_debug_yn) = 'Y' then
    zut.prt(in_msg);
  end if;
exception when others then
  if upper(in_debug_yn) = 'Y' then
    zut.prt('debugmsg--' || sqlerrm);
  end if;
end;

function revenue_group(in_activity varchar2) return varchar2
is
out_revenuegroup activity.revenuegroup%type;

begin

debugmsg('begin revenue group ' || in_activity);
out_revenuegroup := '????';

select revenuegroup
  into out_revenuegroup
  from activity
 where code = in_activity;

debugmsg('end revenue group ' || nvl(out_revenuegroup,'????'));
return nvl(out_revenuegroup,'????');

exception when others then
  debugmsg(sqlerrm);
  return nvl(out_revenuegroup,'????');
end;

function revenuegroup_abbrev(in_revenuegroup varchar2) return varchar2
is
out_abbrev revenuereportgroups.abbrev%type;

begin

out_abbrev := 'Unknown';

select abbrev
  into out_abbrev
  from revenuereportgroups
 where code = in_revenuegroup;

return nvl(out_abbrev,'Unknown');

exception when others then
  return nvl(out_abbrev,'Unknown');
end;

function revenue_number(in_activity varchar2) return number
is

out_revenuenumber integer;

begin

debugmsg('begin revenue_number');
out_revenuenumber := MAXREVCAT;
revcatfound := False;

debugmsg('get revenue group ' || in_activity);
strRevenueGroup := revenue_group(in_activity);
for idxRevCat in 1 .. revcats.count
loop
  if revcats(idxRevCat).revenuegroup = strRevenueGroup then
    revcatfound := True;
    out_revenuenumber := idxRevCat;
    exit;
  end if;
end loop;

if revcatfound = False then
  debugmsg('revcat NOT found');
  if revcats.count < MAXREVCAT then
    idxRevCat := revcats.count + 1;
    revcats(idxRevCat).revenuegroup := strRevenueGroup;
    revcats(idxRevCat).revenuegroupabbrev := revenuegroup_abbrev(strRevenueGroup);
  else
    idxRevCat := MAXREVCAT;
    revcats(idxRevCat).revenuegroup := '';
    revcats(idxRevCat).revenuegroupabbrev := 'OTHER';
  end if;
  out_revenuenumber := idxRevCat;
end if;

debugmsg('out_revenuenumber ' || out_revenuenumber);

return out_revenuenumber;

exception when others then
  return out_revenuenumber;
end;

procedure update_rev_amt(in_facility varchar2, in_custid varchar2,
  in_revenuenumber number, in_billedamt number)
is
begin

debugmsg('begin update_rev_amt');
select count(1)
  into cntRows
  from revbycat
 where sessionid = numSessionId
   and facility = in_facility
   and custid = in_custid;

strColName := 'amt' || trim(to_char(in_revenuenumber));
if cntRows = 0 then
  cu := null;
  open curCustomer(in_custid);
  fetch curCustomer into cu;
  close curCustomer;
  debugmsg('insert activity>' || strColName || '<');
  execute immediate
   'insert into revbycat (sessionid,trantype,facility,custid,custname,' ||
   strColName || ',lastupdate) values ' ||
   '(:sessionid, ''DT'', :facility, :custid, :custname, :amt, :lastupdate)'
   using numSessionId, in_facility, in_custid, cu.name, in_billedamt, sysdate;
  debugmsg('inserted');
else
  debugmsg('update activity');
  execute immediate
    'update revbycat set ' ||
    strColName || ' = nvl(' || strColName || ',0) + :amt ' ||
    'where sessionid = :sessionid ' ||
    ' and facility = :facility' ||
    ' and custid = :custid'
    using in_billedamt, numSessionId, in_facility, in_custid;
  debugmsg('updated');
end if;
commit;

exception when others then
  debugmsg('update_rev_amt exception: ' || sqlerrm);
end;

begin

debugmsg('begin revbycatproc');
select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from revbycat
where sessionid = numSessionId;
commit;

delete from revbycat
where lastupdate < trunc(sysdate);
commit;

debugmsg('clear summary table');

revcats.delete;

wrk := null;
begin
 select reporttitle
   into wrk.reporttitle
   from reporttitleview;
exception when others then
 null;
end;

debugmsg('build rev table');
idxRevCat := 1;
for rev in curRevenueGroups(upper(in_facility),upper(in_activity),trunc(in_begdate),trunc(in_enddate)+1)
loop
  if (idxRevCat <= MAXREVCAT) then
    revcats(idxRevCat).revenuegroup := rev.revenuegroup;
    revcats(idxRevCat).revenuegroupabbrev := revenuegroup_abbrev(rev.revenuegroup);
    idxRevCat := revcats.count + 1;
  else
    revcats(MAXREVCAT).revenuegroup := '';
    revcats(MAXREVCAT).revenuegroupabbrev := 'OTHER';
  end if;
end loop;
debugmsg('rev table built');
debugmsg(to_char(revcats.count) || ' entries');

debugmsg('insert header row');
insert into revbycat
 (sessionid, trantype,
  reporttitle, lastupdate)
values
 (numSessionId, 'AA',
  wrk.reporttitle, sysdate);
debugmsg('inserted header row');
commit;

debugmsg('updating col headings');
for idxRevCat in 1..revcats.count
loop
  debugmsg('column ' || revcats(idxRevCat).revenuegroupabbrev);
  strColName := 'colhead' || trim(to_char(idxRevCat));
  execute immediate
    'update revbycat set ' ||
    strColName || ' = :abbrev ' ||
    'where sessionid = :sessionid ' ||
    ' and trantype = ''AA'''
    using revcats(idxRevCat).revenuegroupabbrev, numSessionId;
end loop;
debugmsg('updated col headings');


debugmsg('scan invoicehdr');

for hdr in curInvoiceHdr(upper(in_facility),upper(in_activity),trunc(in_begdate),trunc(in_enddate)+1)
loop
  debugmsg('scan invoicedtl ' || hdr.facility || ' ' || hdr.custid);
  
  if hdr.invtype = 'C' then
  	amtMultiplier := -1;
  else
  	amtMultiplier := 1;
  end if;
  
  intRevenueNumber := revenue_number(hdr.activity);
  debugmsg('intRevenueNumber ' || to_char(intRevenueNumber));
  update_rev_amt(hdr.facility,hdr.custid,intRevenueNumber,hdr.billedamt*amtMultiplier);
end loop;

commit;

debugmsg('opening cursor');
open rbc_cursor for
select *
  from revbycat
where sessionid = numSessionId
  order by trantype,facility,custid;

end revbycatdateselproc;
/

create or replace procedure revbycatproc
(rbc_cursor IN OUT revbycatpkg.rbc_type
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_activity IN varchar2
,in_debug_yn IN varchar2)
as
begin
  revbycatdateselproc(rbc_cursor,in_facility,in_begdate,in_enddate,in_activity,in_debug_yn,1);
end revbycatproc;
/

create or replace procedure revbycatpostdateproc
(rbc_cursor IN OUT revbycatpkg.rbc_type
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_activity IN varchar2
,in_debug_yn IN varchar2)
as
begin
  revbycatdateselproc(rbc_cursor,in_facility,in_begdate,in_enddate,in_activity,in_debug_yn,2);
end revbycatpostdateproc;
/

CREATE OR REPLACE procedure revbycatcustdateselproc
(rbc_cursor IN OUT revbycatpkg.rbc_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2
,in_datetype IN number)
as

MAXREVCAT constant integer := 9;

type revcattype is record(
  revenuegroup  varchar2(4),
  revenuegroupabbrev varchar2(12)
);

type revcattbltype is table of revcattype
   index by binary_integer;

revcats revcattbltype;

cursor curCustomer(in_custid varchar2) is
  select name
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curInvoiceHdr(in_facility IN varchar2, in_custid IN varchar2) is
  select facility,
         custid,
         invoice,
         invtype
    from invoicehdr
   where nvl(in_datetype,1) = 1
     and (instr(','||in_facility||',', ','||facility||',', 1, 1) > 0
      or  in_facility='ALL')
     and (instr(','||in_custid||',', ','||custid||',', 1, 1) > 0
      or  in_custid='ALL')
     and invoicedate >= trunc(in_begdate)
     and invoicedate <  trunc(in_enddate)+1
     and invstatus = '3'
   union all
  select facility,
         custid,
         invoice,
         invtype
    from invoicehdr
   where nvl(in_datetype,1) = 2
     and (instr(','||in_facility||',', ','||facility||',', 1, 1) > 0
      or  in_facility='ALL')
     and (instr(','||in_custid||',', ','||custid||',', 1, 1) > 0
      or  in_custid='ALL')
     and postdate >= trunc(in_begdate)
     and postdate <  trunc(in_enddate)+1
     and invstatus = '3';

cursor curInvoiceDtl(in_invoice number) is
  select facility,
         custid,
         billstatus,
         activity,
         nvl(billedamt,0) billedamt
    from invoicedtl
   where invoice = in_invoice
     and billstatus = '3';

cursor curRevenueGroup(in_facility IN varchar2, in_custid IN varchar2) is
  select nvl(rrg.code,'????') code,
         nvl(rrg.abbrev,'Unknown') abbrev,
         count(1) groupcount
    from invoicehdr ih, invoicedtl id, activity ac, revenuereportgroups rrg
   where nvl(in_datetype,1) = 1
     and (instr(','||in_facility||',', ','||ih.facility||',', 1, 1) > 0
      or  in_facility='ALL')
     and (instr(','||in_custid||',', ','||ih.custid||',', 1, 1) > 0
      or  in_custid='ALL')
     and ih.invoicedate >= trunc(in_begdate)
     and ih.invoicedate <  trunc(in_enddate)+1
     and ih.invstatus = '3'
     and id.invoice = ih.invoice
     and id.billstatus='3'
     and ac.code = id.activity
     and ac.revenuegroup = rrg.code (+)
   group by nvl(rrg.code,'????'),
         nvl(rrg.abbrev,'Unknown')
   union
  select nvl(rrg.code,'????') code,
         nvl(rrg.abbrev,'Unknown') abbrev,
         count(1) groupcount
    from invoicehdr ih, invoicedtl id, activity ac, revenuereportgroups rrg
   where nvl(in_datetype,1) = 2
     and (instr(','||in_facility||',', ','||ih.facility||',', 1, 1) > 0
      or  in_facility='ALL')
     and (instr(','||in_custid||',', ','||ih.custid||',', 1, 1) > 0
      or  in_custid='ALL')
     and ih.postdate >= trunc(in_begdate)
     and ih.postdate <  trunc(in_enddate)+1
     and ih.invstatus = '3'
     and id.invoice = ih.invoice
     and id.billstatus='3'
     and ac.code = id.activity
     and ac.revenuegroup = rrg.code (+)
   group by nvl(rrg.code,'????'),
         nvl(rrg.abbrev,'Unknown')
   order by 3 desc;

numSessionId number;
wrk revbycat%rowtype;
strRevenueGroup activity.revenuegroup%type;
strRevenueGroupAbbrev revenuereportgroups.abbrev%type;
intRevenueNumber integer;
idxRevCat integer;
idx integer;
revcatfound boolean;
cntRows integer;
curSql integer;
strColName varchar2(30);
numLength integer;
amtMultiplier integer;

procedure debugmsg(in_msg varchar2)
is
begin
  if upper(in_debug_yn) = 'Y' then
    zut.prt(in_msg);
  end if;
exception when others then
  if upper(in_debug_yn) = 'Y' then
    zut.prt('debugmsg--' || sqlerrm);
  end if;
end;

function revenue_group(in_activity varchar2) return varchar2
is
out_revenuegroup activity.revenuegroup%type;

begin

debugmsg('begin revenue group ' || in_activity);
out_revenuegroup := '????';

select revenuegroup
  into out_revenuegroup
  from activity
 where code = in_activity;

debugmsg('end revenue group ' || nvl(out_revenuegroup,'????'));
return nvl(out_revenuegroup,'????');

exception when others then
  debugmsg(sqlerrm);
  return nvl(out_revenuegroup,'????');
end;

function revenuegroup_abbrev(in_revenuegroup varchar2) return varchar2
is
out_abbrev revenuereportgroups.abbrev%type;

begin

out_abbrev := 'Unknown';

select abbrev
  into out_abbrev
  from revenuereportgroups
 where code = in_revenuegroup;

return nvl(out_abbrev,'Unknown');

exception when others then
  return nvl(out_abbrev,'Unknown');
end;

function revenue_number(in_activity varchar2) return number
is

out_revenuenumber integer;

begin

debugmsg('begin revenue_number');
out_revenuenumber := MAXREVCAT;
revcatfound := False;

debugmsg('get revenue group ' || in_activity);
strRevenueGroup := revenue_group(in_activity);
for idxRevCat in 1 .. revcats.count
loop
  if revcats(idxRevCat).revenuegroup = strRevenueGroup then
    revcatfound := True;
    out_revenuenumber := idxRevCat;
    exit;
  end if;
end loop;

if revcatfound = False then
  debugmsg('revcat NOT found');
  if revcats.count < MAXREVCAT then
    idxRevCat := revcats.count + 1;
    revcats(idxRevCat).revenuegroup := strRevenueGroup;
    revcats(idxRevCat).revenuegroupabbrev := revenuegroup_abbrev(strRevenueGroup);
  else
    idxRevCat := MAXREVCAT;
    revcats(idxRevCat).revenuegroup := '';
    revcats(idxRevCat).revenuegroupabbrev := 'Other';
  end if;
  out_revenuenumber := idxRevCat;
end if;

debugmsg('out_revenuenumber ' || out_revenuenumber);

return out_revenuenumber;

exception when others then
  return out_revenuenumber;
end;

procedure update_rev_amt(in_facility varchar2, in_custid varchar2,
  in_revenuenumber number, in_billedamt number)
is
begin

debugmsg('begin update_rev_amt');
select count(1)
  into cntRows
  from revbycat
 where sessionid = numSessionId
   and facility = in_facility
   and custid = in_custid;

strColName := 'amt' || trim(to_char(in_revenuenumber));
if cntRows = 0 then
  cu := null;
  open curCustomer(in_custid);
  fetch curCustomer into cu;
  close curCustomer;
  debugmsg('insert activity>' || strColName || '<');
  execute immediate
   'insert into revbycat (sessionid,trantype,facility,custid,custname,' ||
   strColName || ',lastupdate) values ' ||
   '(:sessionid, ''DT'', :facility, :custid, :custname, :amt, :lastupdate)'
   using numSessionId, in_facility, in_custid, cu.name, in_billedamt, sysdate;
  debugmsg('inserted');
else
  debugmsg('update activity');
  execute immediate
    'update revbycat set ' ||
    strColName || ' = nvl(' || strColName || ',0) + :amt ' ||
    'where sessionid = :sessionid ' ||
    ' and facility = :facility' ||
    ' and custid = :custid'
    using in_billedamt, numSessionId, in_facility, in_custid;
  debugmsg('updated');
end if;
commit;

exception when others then
  debugmsg('update_rev_amt exception: ' || sqlerrm);
end;

begin

debugmsg('begin revbycatproc');
select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from revbycat
where sessionid = numSessionId;
commit;

delete from revbycat
where lastupdate < trunc(sysdate);
commit;

debugmsg('clear summary table');

revcats.delete;

wrk := null;
begin
 select reporttitle
   into wrk.reporttitle
   from reporttitleview;
exception when others then
 null;
end;

debugmsg('build rev table');
idxRevCat := 1;
for crv in curRevenueGroup(upper(in_facility),upper(in_custid))
loop
  revcats(idxRevCat).revenuegroup := crv.code;
  revcats(idxRevCat).revenuegroupabbrev := crv.abbrev;
  if idxRevCat >= 9 then
  	exit;
  else
    idxRevCat := revcats.count + 1;
  end if;
end loop;

for idx in idxRevCat..9
loop
	revcats(idx).revenuegroup := 'null';
	revcats(idx).revenuegroupabbrev := 'null';
end loop;

debugmsg('scan invoicehdr');

for hdr in curInvoiceHdr(upper(in_facility),upper(in_custid))
loop
  debugmsg('scan invoicedtl ' || hdr.facility || ' ' || hdr.custid);

  if hdr.invtype = 'C' then
  	amtMultiplier := -1;
  else
  	amtMultiplier := 1;
  end if;
  
  for dtl in curInvoiceDtl(hdr.invoice)
  loop
    debugmsg('processing dtl');
    intRevenueNumber := revenue_number(dtl.activity);
    update_rev_amt(dtl.facility,dtl.custid,intRevenueNumber,dtl.billedamt*amtMultiplier);
  end loop;
end loop;

debugmsg('insert header row');
insert into revbycat
 (sessionid, trantype,
  reporttitle, lastupdate)
values
 (numSessionId, 'AA',
  wrk.reporttitle, sysdate);
debugmsg('inserted header row');
commit;

debugmsg('updating col headings');
for idxRevCat in 1..revcats.count
loop
  strColName := 'colhead' || trim(to_char(idxRevCat));
  execute immediate
    'update revbycat set ' ||
    strColName || ' = :abbrev ' ||
    'where sessionid = :sessionid ' ||
    ' and trantype = ''AA'''
    using revcats(idxRevCat).revenuegroupabbrev, numSessionId;
end loop;
debugmsg('updated col headings');
commit;

debugmsg('opening cursor');
open rbc_cursor for
select *
  from revbycat
where sessionid = numSessionId
  order by trantype,facility,custid;

end revbycatcustdateselproc;
/

create or replace procedure revbycatcustproc
(rbc_cursor IN OUT revbycatpkg.rbc_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
  revbycatcustdateselproc(rbc_cursor,in_custid,in_facility,in_begdate,in_enddate,in_debug_yn,1);
end revbycatcustproc;
/

create or replace procedure revbycatcustpostdateproc
(rbc_cursor IN OUT revbycatpkg.rbc_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
  revbycatcustdateselproc(rbc_cursor,in_custid,in_facility,in_begdate,in_enddate,in_debug_yn,2);
end revbycatcustpostdateproc;
/

CREATE OR REPLACE procedure revbycatcustdtldateselproc
(rbc_cursor IN OUT revbycatpkg.rbc_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2
,in_datetype IN number)
as

MAXREVCAT constant integer := 9;

type revcattype is record(
  revenuegroup  varchar2(4),
  revenuegroupabbrev varchar2(12)
);

type revcattbltype is table of revcattype
   index by binary_integer;

revcats revcattbltype;

cursor curCustomer(in_custid varchar2) is
  select name
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curInvoiceHdr(in_facility IN varchar2, in_custid IN varchar2) is
  select facility,
         custid,
         masterinvoice,
         invoice,
         invtype
    from invoicehdr
   where nvl(in_datetype,1) = 1
     and (instr(','||in_facility||',', ','||facility||',', 1, 1) > 0
      or  in_facility='ALL')
     and (instr(','||in_custid||',', ','||custid||',', 1, 1) > 0
      or  in_custid='ALL')
     and invoicedate >= trunc(in_begdate)
     and invoicedate <  trunc(in_enddate)+1
     and invstatus = '3'
   union all
  select facility,
         custid,
         masterinvoice,
         invoice,
         invtype
    from invoicehdr
   where nvl(in_datetype,1) = 2
     and (instr(','||in_facility||',', ','||facility||',', 1, 1) > 0
      or  in_facility='ALL')
     and (instr(','||in_custid||',', ','||custid||',', 1, 1) > 0
      or  in_custid='ALL')
     and postdate >= trunc(in_begdate)
     and postdate <  trunc(in_enddate)+1
     and invstatus = '3';

cursor curInvoiceDtl(in_invoice number) is
  select facility,
         custid,
         billstatus,
         activity,
         nvl(billedamt,0) billedamt
    from invoicedtl
   where invoice = in_invoice
     and billstatus = '3';

cursor curRevenueGroup(in_facility IN varchar2, in_custid IN varchar2) is
  select nvl(rrg.code,'????') code,
         nvl(rrg.abbrev,'Unknown') abbrev,
         count(1) groupcount
    from invoicehdr ih, invoicedtl id, activity ac, revenuereportgroups rrg
   where nvl(in_datetype,1) = 1
     and (instr(','||in_facility||',', ','||ih.facility||',', 1, 1) > 0
      or  in_facility='ALL')
     and (instr(','||in_custid||',', ','||ih.custid||',', 1, 1) > 0
      or  in_custid='ALL')
     and ih.invoicedate >= trunc(in_begdate)
     and ih.invoicedate <  trunc(in_enddate)+1
     and ih.invstatus = '3'
     and id.invoice = ih.invoice
     and id.billstatus='3'
     and ac.code = id.activity
     and ac.revenuegroup = rrg.code (+)
   group by nvl(rrg.code,'????'),
         nvl(rrg.abbrev,'Unknown')
   union
  select nvl(rrg.code,'????') code,
         nvl(rrg.abbrev,'Unknown') abbrev,
         count(1) groupcount
    from invoicehdr ih, invoicedtl id, activity ac, revenuereportgroups rrg
   where nvl(in_datetype,1) = 2
     and (instr(','||in_facility||',', ','||ih.facility||',', 1, 1) > 0
      or  in_facility='ALL')
     and (instr(','||in_custid||',', ','||ih.custid||',', 1, 1) > 0
      or  in_custid='ALL')
     and ih.postdate >= trunc(in_begdate)
     and ih.postdate <  trunc(in_enddate)+1
     and ih.invstatus = '3'
     and id.invoice = ih.invoice
     and id.billstatus='3'
     and ac.code = id.activity
     and ac.revenuegroup = rrg.code (+)
   group by nvl(rrg.code,'????'),
         nvl(rrg.abbrev,'Unknown')
   order by 3 desc;

numSessionId number;
wrk revbycat%rowtype;
strRevenueGroup activity.revenuegroup%type;
strRevenueGroupAbbrev revenuereportgroups.abbrev%type;
intRevenueNumber integer;
idxRevCat integer;
idx integer;
revcatfound boolean;
cntRows integer;
curSql integer;
strColName varchar2(30);
numLength integer;
amtMultiplier integer;

procedure debugmsg(in_msg varchar2)
is
begin
  if upper(in_debug_yn) = 'Y' then
    zut.prt(in_msg);
  end if;
exception when others then
  if upper(in_debug_yn) = 'Y' then
    zut.prt('debugmsg--' || sqlerrm);
  end if;
end;

function revenue_group(in_activity varchar2) return varchar2
is
out_revenuegroup activity.revenuegroup%type;

begin

debugmsg('begin revenue group ' || in_activity);
out_revenuegroup := '????';

select revenuegroup
  into out_revenuegroup
  from activity
 where code = in_activity;

debugmsg('end revenue group ' || nvl(out_revenuegroup,'????'));
return nvl(out_revenuegroup,'????');

exception when others then
  debugmsg(sqlerrm);
  return nvl(out_revenuegroup,'????');
end;

function revenuegroup_abbrev(in_revenuegroup varchar2) return varchar2
is
out_abbrev revenuereportgroups.abbrev%type;

begin

out_abbrev := 'Unknown';

select abbrev
  into out_abbrev
  from revenuereportgroups
 where code = in_revenuegroup;

return nvl(out_abbrev,'Unknown');

exception when others then
  return nvl(out_abbrev,'Unknown');
end;

function revenue_number(in_activity varchar2) return number
is

out_revenuenumber integer;

begin

debugmsg('begin revenue_number');
out_revenuenumber := MAXREVCAT;
revcatfound := False;

debugmsg('get revenue group ' || in_activity);
strRevenueGroup := revenue_group(in_activity);
for idxRevCat in 1 .. revcats.count
loop
  if revcats(idxRevCat).revenuegroup = strRevenueGroup then
    revcatfound := True;
    out_revenuenumber := idxRevCat;
    exit;
  end if;
end loop;

if revcatfound = False then
  debugmsg('revcat NOT found');
  if revcats.count < MAXREVCAT then
    idxRevCat := revcats.count + 1;
    revcats(idxRevCat).revenuegroup := strRevenueGroup;
    revcats(idxRevCat).revenuegroupabbrev := revenuegroup_abbrev(strRevenueGroup);
  else
    idxRevCat := MAXREVCAT;
    revcats(idxRevCat).revenuegroup := '';
    revcats(idxRevCat).revenuegroupabbrev := 'Other';
  end if;
  out_revenuenumber := idxRevCat;
end if;

debugmsg('out_revenuenumber ' || out_revenuenumber);

return out_revenuenumber;

exception when others then
  return out_revenuenumber;
end;

procedure update_rev_amt(in_facility varchar2, in_custid varchar2,
  in_masterinvoice varchar2, in_invoice number, in_revenuenumber number, in_billedamt number)
is
begin

debugmsg('begin update_rev_amt');
select count(1)
  into cntRows
  from revbycat
 where sessionid = numSessionId
   and facility = in_facility
   and custid = in_custid
   and invoice = 0;

strColName := 'amt' || trim(to_char(in_revenuenumber));
if cntRows = 0 then
  cu := null;
  open curCustomer(in_custid);
  fetch curCustomer into cu;
  close curCustomer;
  debugmsg('insert activity>' || strColName || '<');
  execute immediate
   'insert into revbycat (sessionid,trantype,facility,custid,invoice,custname,' ||
   strColName || ',lastupdate) values ' ||
   '(:sessionid, ''DT'', :facility, :custid, 0, :custname, :amt, :lastupdate)'
   using numSessionId, in_facility, in_custid, cu.name, in_billedamt, sysdate;
  debugmsg('inserted');
else
  debugmsg('update activity');
  execute immediate
    'update revbycat set ' ||
    strColName || ' = nvl(' || strColName || ',0) + :amt ' ||
    'where sessionid = :sessionid ' ||
    ' and facility = :facility' ||
    ' and custid = :custid' ||
    ' and invoice = 0'
    using in_billedamt, numSessionId, in_facility, in_custid;
  debugmsg('updated');
end if;

select count(1)
  into cntRows
  from revbycat
 where sessionid = numSessionId
   and facility = in_facility
   and custid = in_custid
   and invoice = in_invoice
   and masterinvoice = in_masterinvoice;

strColName := 'amt' || trim(to_char(in_revenuenumber));
if cntRows = 0 then
  cu := null;
  open curCustomer(in_custid);
  fetch curCustomer into cu;
  close curCustomer;
  debugmsg('insert activity>' || strColName || '<');
  execute immediate
   'insert into revbycat (sessionid,trantype,facility,custid,masterinvoice,invoice,custname,' ||
   strColName || ',lastupdate) values ' ||
   '(:sessionid, ''DT'', :facility, :custid, :masterinvoice, :invoice, :custname, :amt, :lastupdate)'
   using numSessionId, in_facility, in_custid, in_masterinvoice, in_invoice, cu.name, in_billedamt, sysdate;
  debugmsg('inserted');
else
  debugmsg('update activity');
  execute immediate
    'update revbycat set ' ||
    strColName || ' = nvl(' || strColName || ',0) + :amt ' ||
    'where sessionid = :sessionid ' ||
    ' and facility = :facility' ||
    ' and custid = :custid' ||
    ' and masterinvoice = :masterinvoice' ||
    ' and invoice = :invoice'
    using in_billedamt, numSessionId, in_facility, in_custid, in_masterinvoice, in_invoice;
  debugmsg('updated');
end if;
commit;

exception when others then
  debugmsg('update_rev_amt exception: ' || sqlerrm);
end;

begin

debugmsg('begin revbycatproc');
select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from revbycat
where sessionid = numSessionId;
commit;

delete from revbycat
where lastupdate < trunc(sysdate);
commit;

debugmsg('clear summary table');

revcats.delete;

wrk := null;
begin
 select reporttitle
   into wrk.reporttitle
   from reporttitleview;
exception when others then
 null;
end;

debugmsg('build rev table');
idxRevCat := 1;
for crv in curRevenueGroup(upper(in_facility),upper(in_custid))
loop
  revcats(idxRevCat).revenuegroup := crv.code;
  revcats(idxRevCat).revenuegroupabbrev := crv.abbrev;
  if idxRevCat >= 9 then
  	exit;
  else
    idxRevCat := revcats.count + 1;
  end if;
end loop;

for idx in idxRevCat..9
loop
	revcats(idx).revenuegroup := 'null';
	revcats(idx).revenuegroupabbrev := 'null';
end loop;

debugmsg('scan invoicehdr');

for hdr in curInvoiceHdr(upper(in_facility),upper(in_custid))
loop
  debugmsg('scan invoicedtl ' || hdr.facility || ' ' || hdr.custid);
  
  if hdr.invtype = 'C' then
  	amtMultiplier := -1;
  else
  	amtMultiplier := 1;
  end if;
  
  for dtl in curInvoiceDtl(hdr.invoice)
  loop
    debugmsg('processing dtl');
    intRevenueNumber := revenue_number(dtl.activity);
    update_rev_amt(dtl.facility,dtl.custid,hdr.masterinvoice,hdr.invoice,intRevenueNumber,dtl.billedamt*amtMultiplier);
  end loop;
end loop;

debugmsg('insert header row');
insert into revbycat
 (sessionid, trantype,
  reporttitle, lastupdate)
values
 (numSessionId, 'AA',
  wrk.reporttitle, sysdate);
debugmsg('inserted header row');
commit;

debugmsg('updating col headings');
for idxRevCat in 1..revcats.count
loop
  strColName := 'colhead' || trim(to_char(idxRevCat));
  execute immediate
    'update revbycat set ' ||
    strColName || ' = :abbrev ' ||
    'where sessionid = :sessionid ' ||
    ' and trantype = ''AA'''
    using revcats(idxRevCat).revenuegroupabbrev, numSessionId;
end loop;
debugmsg('updated col headings');
commit;

debugmsg('opening cursor');
open rbc_cursor for
select *
  from revbycat
where sessionid = numSessionId
  order by trantype,facility,custid,masterinvoice,invoice;

end revbycatcustdtldateselproc;
/

create or replace procedure revbycatcustdtlproc
(rbc_cursor IN OUT revbycatpkg.rbc_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
  revbycatcustdtldateselproc(rbc_cursor,in_custid,in_facility,in_begdate,in_enddate,in_debug_yn,1);
end revbycatcustdtlproc;
/

create or replace procedure revbycatcustdtlpostdateproc
(rbc_cursor IN OUT revbycatpkg.rbc_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
  revbycatcustdtldateselproc(rbc_cursor,in_custid,in_facility,in_begdate,in_enddate,in_debug_yn,2);
end revbycatcustdtlpostdateproc;
/

show errors package revbycatpkg;
show errors package body revbycatpkg;
show errors procedure revbycatdateselproc;
show errors procedure revbycatproc;
show errors procedure revbycatpostdateproc;
show errors procedure revbycatcustdateselproc;
show errors procedure revbycatcustproc;
show errors procedure revbycatcustpostdateproc;
show errors procedure revbycatcustdtldateselproc;
show errors procedure revbycatcustdtlproc;
show errors procedure revbycatcustdtlpostdateproc;
exit;
