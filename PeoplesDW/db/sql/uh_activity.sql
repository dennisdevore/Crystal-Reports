set serveroutput on
set heading off
set pagesize 0
set linesize 32000
set trimspool on
spool uh_activity.out

declare
l_prev userhistory%rowtype := null;
l_diff number;

begin

for uh in (select distinct begtime, endtime
             from userhistory
            where begtime is not null
              and endtime is not null
              and begtime > '01-JUN-14'
            order by begtime)
loop

  if uh.begtime > l_prev.endtime then
    l_diff := (uh.begtime - l_prev.endtime) * 24;
    if l_diff > 8 then
      dbms_output.put_line(to_char(l_prev.endtime, 'DAY') || ' ' ||
                           to_char(l_prev.endtime, 'mm/dd/yy hh24:mi') || ' ' ||
                           to_char(uh.begtime, 'DAY') || ' ' ||
                           to_char(uh.begtime, 'mm/dd/yy hh24:mi') || ' ' ||
                           substr(zlb.formatted_staffhrs(l_diff),1,length(zlb.formatted_staffhrs(l_diff))-3));
    end if;    
  end if;
  
  l_prev.begtime := uh.begtime;
  l_prev.endtime := uh.endtime;
  
end loop;

end;
/
/*
select to_char(begtime, 'mm/dd/yy hh24:mi'),
       to_char(endtime, 'mm/dd/yy hh24:mi'),
       nameid,
       event
  from userhistory
 where begtime >= to_date('09/14/14 09:34:00', 'mm/dd/yy hh24:mi:ss')
   and begtime <= to_date('09/14/14 12:00:59', 'mm/dd/yy hh24:mi:ss');
*/
spool off;
exit;
