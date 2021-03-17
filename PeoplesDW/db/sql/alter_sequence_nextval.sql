set serveroutput on
set verify off

accept p_sequence_name prompt 'Enter sequence name: '
accept p_new_next_value prompt 'Enter new next value: '

declare
l_cmd varchar2(4000);
l_max_value pls_integer;
l_new_next_value pls_integer;
l_curr_next_value pls_integer;
l_sequence_name user_sequences.sequence_name%type;
l_increment_by pls_integer;

begin

l_sequence_name := upper('&&p_sequence_name');
begin
  l_new_next_value := &&p_new_next_value;
exception when others then
  zut.prt('Tne new next value must be numeric');
  return;
end;

l_cmd := 'select max_value from user_sequences where sequence_name = ''' || 
         l_sequence_name || '''';
execute immediate l_cmd into l_max_value;

zut.prt('Max value is ' || l_max_value);
if l_new_next_value > l_max_value then
  zut.prt('New next value of ' || l_new_next_value || ' exceeds max value of ' || l_max_value);
  return;
end if;

l_cmd := 'select last_number from user_sequences where sequence_name = ''' ||
          l_sequence_name || '''';
execute immediate l_cmd into l_curr_next_value;

zut.prt('Next number is ' || l_curr_next_value);

l_increment_by := l_new_next_value - l_curr_next_value;
if l_increment_by = 0 then
  zut.prt('No change is needed');
  return;
end if;

l_cmd := 'alter sequence ' || l_sequence_name || ' increment by ' || l_increment_by;
zut.prt(l_cmd);
execute immediate l_cmd;

l_cmd := 'select ' || l_sequence_name || '.nextval from dual';
zut.prt(l_cmd);
execute immediate l_cmd into l_new_next_value;
zut.prt('Reset value is ' || l_new_next_value);

l_cmd := 'alter sequence ' || l_sequence_name || ' increment by 1';
zut.prt(l_cmd);
execute immediate l_cmd;

commit;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
