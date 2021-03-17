--
-- $Id$
--
declare
function digest(p_username in varchar2, p_password in varchar2)
return varchar2
is
begin
return ltrim(to_char(dbms_utility.get_hash_value(
      upper(p_username) || '/' || upper(p_password), 1000000000,
      power(2, 30)), rpad('X', 30, 'X')));
end digest;
begin
for x in (select username from all_users)
loop
dbms_output.put_line('User: ' || rpad(x.username, 30) ||
      ' digest: ' || digest(x.username, 'TIGER'));
end loop;
end;
/
