create or replace PACKAGE BODY alps.ztable_maintenance
IS

--
-- $Id: ztblbody.sql 3726 2009-08-07 18:35:24Z ed $
--

PROCEDURE disable_fk_references
(in_table_name varchar2
)
is pragma autonomous_transaction;

begin

  for uc in (select uc1.table_name as table_name, uc1.constraint_name as constraint_name
               from user_constraints uc2, user_constraints uc1
              where uc1.constraint_type = 'R'
                and uc1.owner = uc2.owner
                and uc2.constraint_name = uc1.r_constraint_name
                and uc2.table_name = upper(in_table_name)
                and uc1.status = 'ENABLED'
              order by uc1.constraint_name
            )
  loop
    execute immediate 'alter table ' || uc.table_name || ' disable constraint ' ||
                      uc.constraint_name;
  end loop;

end disable_fk_references;

PROCEDURE enable_fk_references
(in_table_name varchar2
)
is pragma autonomous_transaction;
begin

  for uc in (select uc1.table_name as table_name, uc1.constraint_name as constraint_name
               from user_constraints uc2, user_constraints uc1
              where uc1.constraint_type = 'R'
                and uc1.owner = uc2.owner
                and uc2.constraint_name = uc1.r_constraint_name
                and uc2.table_name = upper(in_table_name)
                and uc1.status = 'DISABLED'
              order by uc1.constraint_name
            )
  loop
      execute immediate 'alter table ' || uc.table_name || ' enable novalidate constraint ' ||
                       uc.constraint_name;
  end loop;

end enable_fk_references;

PROCEDURE disable_triggers
(in_table_name varchar2
)
is
begin

  for trig in (select trigger_name
                 from user_triggers
                where table_name = upper(in_table_name)
                  and status = 'ENABLED')
  loop

    execute immediate 'alter trigger ' || trig.trigger_name || ' disable';

  end loop;

end disable_triggers;

PROCEDURE enable_triggers
(in_table_name varchar2
)
is
begin

  for trig in (select trigger_name
                 from user_triggers
                where table_name = upper(in_table_name)
                  and status = 'DISABLED')
  loop

    execute immediate 'alter trigger ' || trig.trigger_name || ' enable';

  end loop;

end enable_triggers;

PROCEDURE delete_validation_table_code
(in_table_name varchar2
,in_code_value varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

begin

out_errorno := 0;
out_msg := null;

execute immediate 'delete from ' || in_table_name || ' where code = ''' ||
                  in_code_value || '''';

exception when others then
  out_msg := substr(sqlerrm,1,80);
  out_errorno := sqlcode;
  ztbl.enable_fk_references(in_table_name);
end delete_validation_table_code;

PROCEDURE purge_userheader
(in_userid varchar2
)
is

l_msg varchar2(255);
l_tot pls_integer;

begin

l_tot := 0;

zms.log_autonomous_msg('PURGE', null, null, 'Begin User Id Purge...',
                       'E', 'SYNAPSE', l_msg);

ztbl.disable_fk_references('USERHEADER');

for uh in (select nameid
             from userheader
            where groupid != 'SYNADMIN'
          )
loop

  delete from usercustomer
   where nameid = uh.nameid;

  delete from userfacility
   where nameid = uh.nameid;

  delete from usergrids
   where nameid = uh.nameid;

  delete from userforms
   where nameid = uh.nameid;

  delete from userdetail
   where nameid = uh.nameid;

  delete from userheader
   where nameid = uh.nameid;

  l_tot := l_tot + 1;

end loop;

commit;

zms.log_autonomous_msg('PURGE', null, null, 'End User Id Purge - Count: ' || l_tot,
                       'E', 'SYNAPSE', l_msg);

ztbl.enable_fk_references('USERHEADER');

exception when others then
  zms.log_autonomous_msg('PURGE', null, null, sqlerrm,
                         'E', 'SYNAPSE', l_msg);
  rollback;
  ztbl.enable_fk_references('USERHEADER');
end;

end ztable_maintenance;
/
show error package body ztable_maintenance;
exit;
