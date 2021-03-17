set serveroutput on;
set heading off;
set pagesize 0;
spool last_analyzed.out

select trunc(last_analyzed), count(1)
 from user_tables
where temporary = 'N'
group by trunc(last_analyzed)
order by trunc(last_analyzed);
select table_name, trunc(last_analyzed)
 from user_tables
where temporary = 'N'
order by trunc(last_analyzed);
exit;
