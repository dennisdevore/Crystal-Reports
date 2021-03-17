--
-- $Id$
--
drop function dt;
create function dt(in_datetime in date)
return varchar2 is
out_datetimestr varchar2(20);
begin
select to_char(in_datetime,'mm/dd/yy hh24:mi:ss')
into out_datetimestr
from dual;
return out_datetimestr;
exception when others then
return '???';
end dt;
/
exit;

