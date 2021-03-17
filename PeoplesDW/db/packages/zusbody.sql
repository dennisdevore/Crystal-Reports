create or replace package body alps.zuser
is
--
-- $Id$
--

procedure drop_user
(in_dropuserid IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2)
is

strMsg varchar2(255);
begin

out_errorno := 0;
out_msg := '';

delete from userforms
 where nameid = in_dropuserid;
delete from usergrids
 where nameid = in_dropuserid;

zms.log_msg('DropUser', null, null,
 'User ' || in_dropuserid || ' dropped by ' || in_userid,
 'I', in_userid, strMsg);

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end drop_user;

procedure get_setting
(in_userid IN varchar2
,in_groupid IN varchar2
,in_formid IN varchar2
,in_facility IN varchar2
,out_setting IN OUT varchar2
) is

cursor curUserFormFacilitySetting is
  select setting
    from userdetail
   where nameid = in_userid
     and formid = in_formid
     and facility = in_facility;

cursor curUserFormSetting is
  select setting
    from userdetail
   where nameid = in_userid
     and formid = in_formid;

cursor curUserGroupSetting is
  select setting
    from userdetail
   where nameid = in_groupid
     and formid = in_formid;

begin

out_setting := null;
open curUserFormFacilitySetting;
fetch curUserFormFacilitySetting into out_setting;
close curUserFormFacilitySetting;

if out_setting is null then
  open curUserFormSetting;
  fetch curUserFormSetting into out_setting;
  close curUserFormSetting;
end if;

if out_setting is null then
  open curUserGroupSetting;
  fetch curUserGroupSetting into out_setting;
  close curUserGroupSetting;
end if;

if out_setting is null then
  if in_groupid = 'SUPER' then
    out_setting := 'SUPERVISOR';
  else
    out_setting := 'ACCESSDENIED';
  end if;
end if;

exception when others then
  out_setting := 'ACCESSDENIED';
end get_setting;

function user_setting
(in_userid IN varchar2
,in_groupid IN varchar2
,in_formid IN varchar2
,in_facility IN varchar2
) return varchar2 is

cursor curUserFormFacilitySetting is
  select setting
    from userdetail
   where nameid = in_userid
     and formid = in_formid
     and facility = in_facility;

cursor curUserFormSetting is
  select setting
    from userdetail
   where nameid = in_userid
     and formid = in_formid;

cursor curUserGroupSetting is
  select setting
    from userdetail
   where nameid = in_groupid
     and formid = in_formid;

out_setting userdetail.setting%type;

begin

out_setting := null;
open curUserFormFacilitySetting;
fetch curUserFormFacilitySetting into out_setting;
close curUserFormFacilitySetting;

if out_setting is null then
  open curUserFormSetting;
  fetch curUserFormSetting into out_setting;
  close curUserFormSetting;
end if;

if out_setting is null then
  open curUserGroupSetting;
  fetch curUserGroupSetting into out_setting;
  close curUserGroupSetting;
end if;

if out_setting is null then
  if in_groupid = 'SUPER' then
    out_setting := 'SUPERVISOR';
  else
    out_setting := 'ACCESSDENIED';
  end if;
end if;

return out_setting;

exception when others then
  return 'ACCESSDENIED';
end user_setting;

function blenderize_user
   (in_u1 in varchar2,
    in_u2 in varchar2)
return varchar2
is
   pragma autonomous_transaction;
   l_result varchar2(32);
begin
   l_result := dbms_obfuscation_toolkit.md5(input => utl_raw.cast_to_raw(in_u1||in_u2));
   commit;
   return l_result;
end blenderize_user;

function user_form_setting
(in_userid IN varchar2
,in_formid IN varchar2
,in_facility IN varchar2
) return varchar2 is

cursor curUserFormFacilitySetting is
  select setting
    from userdetail
   where nameid = in_userid
     and formid = in_formid
     and facility = in_facility;

cursor curUserFormSetting is
  select setting
    from userdetail
   where nameid = in_userid
     and formid = in_formid;

cursor curUserHeader is
  select groupid
    from userheader
   where nameid = in_userid;

strgroupid userheader.groupid%type;

cursor curUserGroupSetting is
  select setting
    from userdetail
   where nameid = strGroupid
     and formid = in_formid;

out_setting userdetail.setting%type;

begin

out_setting := null;

open curUserHeader;
fetch curUserHeader into strgroupid;
close curUserHeader;

open curUserFormFacilitySetting;
fetch curUserFormFacilitySetting into out_setting;
close curUserFormFacilitySetting;

if out_setting is null then
  open curUserFormSetting;
  fetch curUserFormSetting into out_setting;
  close curUserFormSetting;
end if;

if out_setting is null then
  open curUserGroupSetting;
  fetch curUserGroupSetting into out_setting;
  close curUserGroupSetting;
end if;

if out_setting is null then
  if strgroupid = 'SUPER' then
    out_setting := 'SUPERVISOR';
  else
    out_setting := 'ACCESSDENIED';
  end if;
end if;

return out_setting;

exception when others then
  return 'ACCESSDENIED';
end user_form_setting;

procedure upsert_setting
(in_nameid in varchar2
,in_formid in varchar2
,in_facility in varchar2
,in_setting in varchar2
,in_userid in varchar2
,out_msg IN OUT varchar2)
is
  v_count number;
begin
  out_msg := 'OKAY';
  
  if (in_nameid is null or in_formid is null or in_setting is null) then
    out_msg := 'Userid, formid, and setting are all required';
    return;
  end if;
  
  select count(1)
  into v_count
  from userheader
  where nameid = in_nameid;
  
  if (v_count < 1) then
    out_msg := 'User ' || in_nameid || ' not found';
    return;
  end if;
  
  if (in_setting not in ('EDIT','ACCESSDENIED','DISPLAY','SUPERVISOR')) then
    out_msg := 'Invalid setting given: ' || in_setting;
    return;
  end if;
  
  if (in_facility is not null) then
    select count(1)
    into v_count
    from facility
    where facility = in_facility;
    
    if (v_count < 1) then
      out_msg := 'Invalid facility given: ' || in_facility;
      return;
    end if;
  end if;
  
  select count(1)
  into v_count
  from userdetail
  where nameid = in_nameid and formid = in_formid and nvl(facility,'XXX') = nvl(in_facility,'XXX');
  
  if (v_count = 0) then
    insert into userdetail (nameid, formid, facility, setting, lastuser, lastupdate)
    values (in_nameid, in_formid, in_facility, in_setting, in_userid, sysdate);
  else
    update userdetail
    set setting = in_setting, lastuser = in_userid, lastupdate = sysdate
    where nameid = in_nameid and formid = in_formid and nvl(facility,'XXX') = nvl(in_facility,'XXX');
  end if;
  
end upsert_setting;

function max_begtime
(in_userid in varchar2
) return date
is

l_date userhistory.begtime%type;

begin

select max(begtime)
  into l_date
  from userhistory
 where nameid = upper(in_userid);

return l_date;

exception when others then
  return null;
end max_begtime;

function max_endtime
(in_userid in varchar2
) return date
is

l_date userhistory.endtime%type;

begin

select max(endtime)
  into l_date
  from userhistory
 where nameid = upper(in_userid);

return l_date;

exception when others then
  return null;
end max_endtime;

procedure close_user_events (
  in_userid in varchar2,
  in_event in varchar2
)
as
  strMsg varchar2(255);
begin
  
  for rec in (select rowid, a.*
              from userhistory a
              where nameid = in_userid and endtime is null)
  loop
   
    if ((in_event != 'LGIN' and rec.event = 'LGIN') or (in_event = 'LGIN' and rec.event != 'LGIN'))
    then
      goto continue_loop;
    end if;

    if ((in_event = '1LIP' and rec.event = '1STP') or 
        (in_event = 'PICK' and rec.event = 'SOPK')) 
    then
      goto continue_loop;
    end if;
    
    update userhistory
    set endtime = sysdate
    where rowid = rec.rowid;
    
  << continue_loop >>
    null;
  end loop;
  
exception
  when others then
    zms.log_msg('CloseEvents', null, null,sqlerrm(sqlcode),'W', in_userid, strMsg);
end close_user_events;

end zuser;
/
show error package body zuser;
exit;

