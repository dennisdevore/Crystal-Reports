create or replace PACKAGE BODY alps.zapplocks
IS
--
-- $Id$
--

PROCEDURE get_app_lock
(in_lockid IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
)
is

cursor Capplocks is
  select lockid,
         lastuser,
         lastupdate
    from applocks
   where lockid = in_lockid;
lk Capplocks%rowtype;

begin

out_msg := '';

while (1=1) loop
begin
  insert into applocks
    (lockid, lastuser, lastupdate)
  values
    (in_lockid, in_userid, sysdate);
  exit;
exception when dup_val_on_index then
  open Capplocks;
  fetch Capplocks into lk;
  if Capplocks%notfound then
    close Capplocks;
  else
    close Capplocks;
    out_msg := 'Please retry - ' || in_lockid || ' locked by user ' ||
               lk.lastuser || ' at ' ||
               to_char(lk.lastupdate, 'mm/dd/yy hh24:mi:ss');
    return;
  end if;
end;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := sqlerrm;
end get_app_lock;

PROCEDURE release_app_lock
(in_lockid IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
)
is
strMsg varchar2(256);
begin

out_msg := '';

delete from applocks
 where lockid = in_lockid;
if sql%rowcount = 0 then
  out_msg := 'Unable to find lock: ' || in_lockid;
  zms.log_autonomous_msg('RLOCK', null, null,
    out_msg, 'E', 'RLOCK', strMsg);
  return;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := sqlerrm;
  zms.log_autonomous_msg('RLOCK', null, null,
    'Unable to release lock ' || in_lockid || ' : ' || out_msg, 'E', 'RLOCK', strMsg);
end release_app_lock;

PROCEDURE get_waveplan_app_lock
(in_lockid IN varchar2
,in_facility IN varchar2
,in_wave IN number
,in_orderid IN number
,in_shipid IN number
,in_custid IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
)
is

cursor CCustsByWave is
  select distinct custid
    from orderhdr
   where wave=in_wave;
cbw CCustsByWave%rowtype;

cursor CCustsByOrder is
  select custid
    from orderhdr
   where orderid=in_orderid
     and shipid=in_shipid;
cbo CCustsByOrder%rowtype;

cursor Ccust(in_custid varchar2) is
  select custid
    from customer
   where custid = in_custid;
cu Ccust%rowtype;

custcount integer;

begin

out_msg := '';

if ((nvl(in_orderid,0) <> 0) and (nvl(in_shipid,0) <> 0)) then
  cbo:=null;
  open CCustsByOrder;
  fetch CCustsByOrder into cbo;
  close CCustsByOrder;

  cu:=null;
  open Ccust(cbo.custid);
  fetch Ccust into cu;
  close Ccust;
  if (cu.custid is null) then
    out_msg := 'Customer not found, order: '||in_orderid||'-'||in_shipid;
    return;
  end if;
  
  get_app_lock(in_lockid||cu.custid,in_facility,in_userid,out_msg);
  if out_msg <> 'OKAY' then
    return;
  end if;
elsif nvl(in_wave,0) <> 0 then
  get_app_lock(to_char(in_wave)||in_lockid,in_facility,in_userid,out_msg);
  if out_msg <> 'OKAY' then
    return;
  end if;
    
  custcount := 0;
  cbw:=null;
  for cbw in CCustsByWave
  loop
    cu:=null;
    open Ccust(cbw.custid);
    fetch Ccust into cu;
    close Ccust;
    if (cu.custid is null) then
      out_msg := 'Customer not found, wave: '||in_wave;
      return;
    end if;
  
    get_app_lock(in_lockid||cu.custid,in_facility,in_userid,out_msg);
    if out_msg <> 'OKAY' then
      return;
    end if;
    
    custcount := custcount + 1;
  end loop;
  
  if (custcount = 0) then
    out_msg := 'Customer not found, wave: '||in_wave;
    return;
  end if;
elsif (nvl(in_custid,'(none)') <> '(none)') then
  cu:=null;
  open Ccust(in_custid);
  fetch Ccust into cu;
  close Ccust;
  if (cu.custid is null) then
    out_msg := 'Customer not found: '||in_custid;
    return;
  end if;
  
  get_app_lock(in_lockid||cu.custid,in_facility,in_userid,out_msg);
  if out_msg <> 'OKAY' then
    return;
  end if;
else
  get_app_lock(in_lockid,in_facility,in_userid,out_msg);
  if out_msg <> 'OKAY' then
    return;
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := sqlerrm;
end get_waveplan_app_lock;

PROCEDURE release_waveplan_app_lock
(in_lockid IN varchar2
,in_facility IN varchar2
,in_wave IN number
,in_orderid IN number
,in_shipid IN number
,in_custid IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
)
is
cursor CCustsByWave is
  select distinct custid
    from orderhdr
   where wave=in_wave;
cbw CCustsByWave%rowtype;

cursor CCustsByOrder is
  select custid
    from orderhdr
   where orderid=in_orderid
     and shipid=in_shipid;
cbo CCustsByOrder%rowtype;

cursor Ccust(in_custid varchar2) is
  select custid
    from customer
   where custid = in_custid;
cu Ccust%rowtype;

custcount integer;

begin

out_msg := '';

if ((nvl(in_orderid,0) <> 0) and (nvl(in_shipid,0) <> 0)) then
  cbo:=null;
  open CCustsByOrder;
  fetch CCustsByOrder into cbo;
  close CCustsByOrder;

  cu:=null;
  open Ccust(cbo.custid);
  fetch Ccust into cu;
  close Ccust;
  if (cu.custid is null) then
    out_msg := 'Customer not found, order: '||in_orderid||'-'||in_shipid;
    return;
  end if;
  
  release_app_lock(in_lockid||cu.custid,in_facility,in_userid,out_msg);
  if out_msg <> 'OKAY' then
    return;
  end if;
elsif nvl(in_wave,0) <> 0 then
  release_app_lock(to_char(in_wave)||in_lockid,in_facility,in_userid,out_msg);
  if out_msg <> 'OKAY' then
    return;
  end if;
    
  custcount := 0;
  cbw:=null;
  for cbw in CCustsByWave
  loop
    cu:=null;
    open Ccust(cbw.custid);
    fetch Ccust into cu;
    close Ccust;
    if (cu.custid is null) then
      out_msg := 'Customer not found, wave: '||in_wave;
      return;
    end if;
  
    release_app_lock(in_lockid||cu.custid,in_facility,in_userid,out_msg);
    if out_msg <> 'OKAY' then
      return;
    end if;
    
    custcount := custcount + 1;
  end loop;
  
  if (custcount = 0) then
    out_msg := 'Customer not found, wave: '||in_wave;
    return;
  end if;
elsif (in_custid is not null) then
  cu:=null;
  open Ccust(in_custid);
  fetch Ccust into cu;
  close Ccust;
  if (cu.custid is null) then
    out_msg := 'Customer not found: '||in_custid;
    return;
  end if;
  
  release_app_lock(in_lockid||cu.custid,in_facility,in_userid,out_msg);
  if out_msg <> 'OKAY' then
    return;
  end if;
else
  release_app_lock(in_lockid,in_facility,in_userid,out_msg);
  if out_msg <> 'OKAY' then
    return;
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := sqlerrm;
end release_waveplan_app_lock;

end zapplocks;
/
show error package body zapplocks;
exit;
