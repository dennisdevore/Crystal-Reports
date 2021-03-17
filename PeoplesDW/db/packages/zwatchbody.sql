create or replace package body alps.zwatch as
--
-- $Id$
--


-- Cursors


cursor c_ses is
   select lower(program) as module
   from v$session
   where audsid = sys_context('USERENV','SESSIONID');
ses c_ses%rowtype;


-- Private functions


function is_watchable
   (in_module in varchar2)
return boolean
is
begin
   if in_module = 'synapse.exe'
   or in_module = 'impexp.exe'
   or in_module like 'rfwhse@%'
   or in_module like 'genpicks@%'
   or in_module like 'putaway@%'
   or in_module like 'work@%'
   or in_module like 'replenish@%' then
      return false;
   end if;

   return true;
end is_watchable;


-- Public procedures


procedure check_val
   (in_tbl_name  in varchar2,
    in_col_name  in varchar2,
    in_userid    in varchar2,
    in_new_value in varchar2,
    in_old_value in varchar2,
    in_origin    in varchar2)
is
   ses c_ses%rowtype;
begin
   open c_ses;
   fetch c_ses into ses;
   close c_ses;

   if is_watchable(ses.module)
   and (in_new_value <> in_old_value
   or   (in_new_value is null and in_old_value is not null)
   or   (in_new_value is not null and in_old_value is null)) then
      insert into watch_table
         (origin, occurred, userid, tbl_name, col_name, old_value, new_value,
          module, host, ip_address,
          os_user)
      values
         (in_origin, sysdate, in_userid, in_tbl_name, in_col_name, in_old_value, in_new_value,
          ses.module, sys_context('USERENV','HOST'), sys_context('USERENV','IP_ADDRESS'),
          sys_context('USERENV','OS_USER'));
   end if;
end check_val;


procedure check_val
   (in_tbl_name  in varchar2,
    in_col_name  in varchar2,
    in_userid    in varchar2,
    in_new_value in number,
    in_old_value in number,
    in_origin    in varchar2)
is
   ses c_ses%rowtype;
begin
   open c_ses;
   fetch c_ses into ses;
   close c_ses;

   if is_watchable(ses.module)
   and (in_new_value <> in_old_value
   or   (in_new_value is null and in_old_value is not null)
   or   (in_new_value is not null and in_old_value is null)) then
      insert into watch_table
         (origin, occurred, userid, tbl_name, col_name, old_value, new_value,
          module, host, ip_address,
          os_user)
      values
         (in_origin, sysdate, in_userid, in_tbl_name, in_col_name, in_old_value, in_new_value,
          ses.module, sys_context('USERENV','HOST'), sys_context('USERENV','IP_ADDRESS'),
          sys_context('USERENV','OS_USER'));
   end if;
end check_val;


procedure check_val
   (in_tbl_name  in varchar2,
    in_col_name  in varchar2,
    in_userid    in varchar2,
    in_new_value in date,
    in_old_value in date,
    in_origin    in varchar2)
is
   ses c_ses%rowtype;
begin
   open c_ses;
   fetch c_ses into ses;
   close c_ses;

   if is_watchable(ses.module)
   and (in_new_value <> in_old_value
   or   (in_new_value is null and in_old_value is not null)
   or   (in_new_value is not null and in_old_value is null)) then
      insert into watch_table
         (origin, occurred, userid, tbl_name, col_name, old_value, new_value,
          module, host, ip_address,
          os_user)
      values
         (in_origin, sysdate, in_userid, in_tbl_name, in_col_name,
          to_char(in_old_value, 'dd-mon-yyyy hh24:mi:ss'),
          to_char(in_new_value, 'dd-mon-yyyy hh24:mi:ss'),
          ses.module, sys_context('USERENV','HOST'), sys_context('USERENV','IP_ADDRESS'),
          sys_context('USERENV','OS_USER'));

   end if;
end check_val;


end zwatch;
/

show errors package body zwatch;
exit;
