create or replace PACKAGE BODY alps.zempactv
IS
--
-- $Id$
--

PROCEDURE summarize_time
(in_nameid varchar2
,in_custid varchar2
,in_facility varchar2
,in_event varchar2
,in_begtime date
,in_endtime date
,out_days IN OUT number
,out_hours IN OUT number
,out_minutes IN OUT number
,out_seconds IN OUT number
,out_msg  IN OUT varchar2
) is

sumSeconds number(16,8);
curActv integer;
cmdSql varchar2(2000);
qryDays number(16,8);
cntRows integer;
begtimestr varchar2(14);
endtimestr varchar2(14);

begin

out_msg := '';
out_days := 0;
out_hours := 0;
out_minutes := 0;
out_seconds := 0;

if in_begtime is null then
  begtimestr := '19000101000000';
else
  begtimestr := to_char(in_begtime,'yyyymmddhh24miss');
end if;

if in_endtime is null then
  endtimestr := '20891231000000';
else
  endtimestr := to_char(in_endtime,'yyyymmddhh24miss');
end if;

begin
  cmdSql := 'select nvl(sum(endtime - begtime),0) ' ||
    'from userhistory where begtime >= to_date(''' ||
    begtimestr || ''',''yyyymmddhh24miss'')' ||
    ' and begtime < to_date(''' ||
    endtimestr || ''',''yyyymmddhh24miss'')';
  if rtrim(in_nameid) is not null then
    cmdSql := cmdSql || ' and nameid = ''' || in_nameid || '''';
  end if;
  if rtrim(in_custid) is not null then
    cmdSql := cmdSql || ' and custid = ''' || in_custid || '''';
  end if;
  if rtrim(in_facility) is not null then
    cmdSql := cmdSql || ' and facility = ''' || in_facility || '''';
  end if;
  if rtrim(in_event) is not null then
    cmdSql := cmdSql || ' and event = ''' || in_event || '''';
  end if;
  curActv := dbms_sql.open_cursor;
  dbms_sql.parse(curActv, cmdsql, dbms_sql.native);
  dbms_sql.define_column(curActv,1,qryDays);
  cntRows := dbms_sql.execute_and_fetch(curActv);
  dbms_sql.column_value(curActv,1,qryDays);
  dbms_sql.close_cursor(curActv);
exception when no_data_found then
  qryDays := 0;
  dbms_sql.close_cursor(curActv);
end;


out_days := floor(qryDays);
sumSeconds := (qryDays - floor(qryDays)) * 86400;
out_hours := floor(sumSeconds / 3600);
sumSeconds := sumSeconds - out_hours * 3600;
out_minutes := floor(sumSeconds / 60);
out_seconds := sumSeconds - (out_minutes * 60);

out_msg := 'OKAY';

exception when others then
  out_msg := 'east ' || substr(sqlerrm,1,80);
end summarize_time;

end zempactv;
/
show error package body zempactv;
exit;
