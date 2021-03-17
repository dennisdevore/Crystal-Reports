create or replace PACKAGE BODY alps.zappmsgs
IS
--
-- $Id$
--

PROCEDURE log_autonomous_msg
   (in_author   in varchar2,
    in_facility in varchar2,
    in_custid   in varchar2,
    in_msgtext  in varchar2,
    in_msgtype  in varchar2,
    in_userid   in varchar2,
    out_msg     in out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   l_start pls_integer := 1;
   l_remain pls_integer := nvl(length(in_msgtext),0);
   l_len pls_integer;
begin
   out_msg := '';

   loop
      l_len := least(l_remain, 255);
      insert into appmsgs
         (created,
          author,
          facility,
          custid,
          msgtext,
          status,
          lastuser,
          lastupdate,
          msgtype)
      values
         (sysdate,
          upper(in_author),
          in_facility,
          in_custid,
          substr(in_msgtext, l_start, l_len),
          'UNRV',
          in_userid,
          sysdate,
          in_msgtype);

      exit when (l_len >= l_remain) or (l_remain <= 0);
      l_start := l_start+l_len;
      l_remain := l_remain-l_len;
   end loop;

   commit;
   out_msg := 'OKAY';

exception when others then
  out_msg := 'zmslm ' || substr(sqlerrm,1,80);
  rollback;
end log_autonomous_msg;

PROCEDURE log_msg
   (in_author   in varchar2,
    in_facility in varchar2,
    in_custid   in varchar2,
    in_msgtext  in varchar2,
    in_msgtype  in varchar2,
    in_userid   in varchar2,
    out_msg     in out varchar2)
is
   l_start pls_integer := 1;
   l_remain pls_integer := nvl(length(in_msgtext),0);
   l_len pls_integer;
begin
   out_msg := '';

   loop
      l_len := least(l_remain, 255);
      insert into appmsgs
         (created,
          author,
          facility,
          custid,
          msgtext,
          status,
          lastuser,
          lastupdate,
          msgtype)
      values
         (sysdate,
          upper(in_author),
          in_facility,
          in_custid,
          substr(in_msgtext, l_start, l_len),
          'UNRV',
          in_userid,
          sysdate,
          in_msgtype);

      exit when (l_len >= l_remain) or (l_remain <= 0);
      l_start := l_start+l_len;
      l_remain := l_remain-l_len;
   end loop;

   out_msg := 'OKAY';

exception when others then
  out_msg := 'zmslm ' || substr(sqlerrm,1,80);
end log_msg;

PROCEDURE reset_profile_sequence
(in_facility varchar2
,in_profid varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
) is

cursor curProfId is
  select facility, profid, priority
    from putawayprofline
   where facility = in_facility
     and profid = in_profid
   order by priority desc;

newpriority number(4);

begin

out_msg := '';

update putawayprofline
   set priority = priority * -1
 where facility = in_facility
   and profid = in_profid;
if sql%rowcount = 0 then
  out_msg := 'Profile Zones not found: ' ||
             in_facility || ' ' || in_profid;
  return;
end if;

newpriority := 10;

for p in curProfId
loop
  update putawayprofline
     set priority = newpriority,
         lastuser = in_userid,
         lastupdate = sysdate
   where facility = p.facility
     and profid = p.profid
     and priority = p.priority;
  newpriority := newpriority + 10;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := 'zmsrps ' || substr(sqlerrm,1,80);
end reset_profile_sequence;

PROCEDURE set_to_reviewed
(in_rowid varchar2
,in_userid varchar2
,out_msg  IN OUT varchar2
) is

begin

update appmsgs
   set status = 'REVW',
       lastuser = in_userid,
       lastupdate = sysdate
 where rowid = chartorowid(in_rowid)
   and status = 'UNRV';

if sql%rowcount = 0 then
  out_msg := 'Message not updated';
else
  out_msg := 'OKAY--message set to reviewed';
end if;

exception when others then
  out_msg := 'zmsstr ' || substr(sqlerrm,1,80);
end set_to_reviewed;

PROCEDURE set_alert_to_reviewed
(in_alertid number
,in_userid varchar2
,out_msg  IN OUT varchar2
) is

begin

update alert_manager
   set status = 'REVW',
       lastuser = in_userid,
       lastupdate = sysdate
 where alertid = in_alertid
   and status in ('UNRV','NOTI');

if sql%rowcount = 0 then
  out_msg := 'Alert not updated';
else
  out_msg := 'OKAY--alert set to reviewed';
end if;

exception when others then
  out_msg := 'zmsstr ' || substr(sqlerrm,1,80);
end set_alert_to_reviewed;

PROCEDURE compute_shipdate
(in_facility varchar2
,in_shipto varchar2
,in_arrivaldate varchar2
,out_shipdate  OUT date
,out_msg OUT varchar2
) is

c consignee%rowtype;
s shipdays%rowtype;
loopcnt integer;

begin

begin
select postalcode
  into c.postalcode
  from consignee
 where consignee = in_shipto;
exception when no_data_found then
  c.postalcode := '';
end;

if c.postalcode is null then
  goto use_systemdefault;
end if;

s.shipdays := -1;
loopcnt := length(c.postalcode);
while(loopcnt > 0)
loop
  begin
    select shipdays
      into s.shipdays
      from shipdays
     where facility = in_facility
       and postalkey = substr(c.postalcode,1,loopcnt);
  exception when no_data_found then
    loopcnt := loopcnt - 1;
  end;
  if sql%rowcount <> 0 then
    exit;
  end if;
end loop;

if s.shipdays > -1 then
  goto calc_shipdate;
end if;

<<use_systemdefault>>

begin
  select to_number(defaultvalue)
    into s.shipdays
    from systemdefaults
   where defaultid = 'SHIPDAYS';
exception when others then
  s.shipdays := 0;
end;

<<calc_shipdate>>

out_shipdate := to_date(in_arrivaldate, 'yyyymmdd') - s.shipdays;
out_msg := 'OKAY';

exception when others then
  out_msg := 'zmscs ' || substr(sqlerrm,1,80);
end compute_shipdate;

PROCEDURE compute_arrivaldate
(in_facility varchar2
,in_shipto varchar2
,in_shipdate varchar2
,out_arrivaldate IN OUT date
,out_msg IN OUT varchar2
) is

c consignee%rowtype;
s shipdays%rowtype;
loopcnt integer;

begin

begin
select postalcode
  into c.postalcode
  from consignee
 where consignee = in_shipto;
exception when no_data_found then
  c.postalcode := '';
end;

if c.postalcode is null then
  goto use_systemdefault;
end if;

s.shipdays := -1;
loopcnt := length(c.postalcode);
while(loopcnt > 0)
loop
  begin
    select shipdays
      into s.shipdays
      from shipdays
     where facility = in_facility
       and postalkey = substr(c.postalcode,1,loopcnt);
  exception when no_data_found then
    loopcnt := loopcnt - 1;
  end;
  if sql%rowcount <> 0 then
    exit;
  end if;
end loop;

if s.shipdays > -1 then
  goto calc_arrivaldate;
end if;

<<use_systemdefault>>

begin
  select to_number(defaultvalue)
    into s.shipdays
    from systemdefaults
   where defaultid = 'SHIPDAYS';
exception when others then
  s.shipdays := 0;
end;

<<calc_arrivaldate>>

out_arrivaldate := to_date(in_shipdate, 'yyyymmdd') + s.shipdays;
out_msg := 'OKAY';

exception when others then
  out_msg := 'zmsca ' || substr(sqlerrm,1,80);
end compute_arrivaldate;

PROCEDURE rf_debug_msg
   (in_author   in varchar2,
    in_facility in varchar2,
    in_custid   in varchar2,
    in_msgtext  in varchar2,
    in_msgtype  in varchar2,
    in_userid   in varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   l_start pls_integer := 1;
   l_remain pls_integer := nvl(length(in_msgtext),0);
   l_len pls_integer;
begin
   if nvl(zci.default_value('RFDEBUG'),'N') = 'N' then
     return;
   end if;
   loop
      l_len := least(l_remain, 255);
      insert into appmsgs
         (created,
          author,
          facility,
          custid,
          msgtext,
          status,
          lastuser,
          lastupdate,
          msgtype)
      values
         (sysdate,
          upper(in_author),
          in_facility,
          in_custid,
          substr(in_msgtext, l_start, l_len),
          'UNRV',
          in_userid,
          sysdate,
          in_msgtype);
      exit when (l_len >= l_remain) or (l_remain <= 0);
      l_start := l_start+l_len;
      l_remain := l_remain-l_len;
   end loop;
   commit;
exception when others then
  rollback;
end rf_debug_msg;
end zappmsgs;

/
show error package body zappmsgs;
exit;
