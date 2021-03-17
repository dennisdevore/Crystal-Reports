create or replace PACKAGE BODY alps.zallocrules
IS
--
-- $Id$
--

PROCEDURE reset_allocrule_sequence
(in_facility varchar2
,in_allocrule varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
) is

cursor curallocrule is
  select facility, allocrule, priority
    from allocrulesdtl
   where facility = in_facility
     and allocrule = in_allocrule
   order by priority desc;

newpriority number(4);

begin

out_msg := '';

update allocrulesdtl
   set priority = priority * -1
 where facility = in_facility
   and allocrule = in_allocrule;

if sql%rowcount = 0 then
  out_msg := 'Allocation Rule Detail not found: ' ||
             in_facility || ' ' || in_allocrule;
  return;
end if;

newpriority := 10;

for p in curallocrule
loop
  update allocrulesdtl
     set priority = newpriority,
         lastuser = in_userid,
         lastupdate = sysdate
   where facility = p.facility
     and allocrule = p.allocrule
     and priority = p.priority;
  newpriority := newpriority + 10;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := 'zmsrps ' || substr(sqlerrm,1,80);
end reset_allocrule_sequence;

end zallocrules;

/
show error package body zallocrules;
exit;
