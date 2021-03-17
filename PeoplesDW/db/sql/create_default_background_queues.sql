set serveroutput on;
declare
cntrows integer;

begin

select count(1)
  into cntrows
  from pickrequestqueues;
if cntrows = 0 then
  zut.prt('inserting pickrequestqueues entry');
  insert into pickrequestqueues values
    ('ALL','Default Queue','Q1','Y','SYNAPSE',sysdate);
else
  zut.prt('pickrequestqueues count ' || cntrows);
end if;

select count(1)
  into cntrows
  from putawayqueues;
if cntrows = 0 then
  zut.prt('inserting putawayqueues entry');
  insert into putawayqueues values
    ('ALL','Default Queue','Q1','Y','SYNAPSE',sysdate);
else
  zut.prt('putawayqueues count ' || cntrows);
end if;

select count(1)
  into cntrows
  from replenishrequestqueues;
if cntrows = 0 then
  zut.prt('inserting replenishrequestqueues entry');
  insert into replenishrequestqueues values
    ('ALL','Default Queue','Q1','Y','SYNAPSE',sysdate);
else
  zut.prt('replenishrequestqueues count ' || cntrows);
end if;

select count(1)
  into cntrows
  from taskrequestqueues;
if cntrows = 0 then
  zut.prt('inserting taskrequestqueues entry');
  insert into taskrequestqueues values
    ('ALL','Default Queue','Q1','Y','SYNAPSE',sysdate);
else
  zut.prt('taskrequestqueues count ' || cntrows);
end if;

select count(1)
  into cntrows
  from spoolerqueues;
if cntrows = 0 then
  zut.prt('inserting spoolerqueues entry');
  insert into spoolerqueues values
    ('DEFAULT','Default Queue','Q1','SYNAPSE',sysdate);
else
  zut.prt('spoolerqueues count ' || cntrows);
end if;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
