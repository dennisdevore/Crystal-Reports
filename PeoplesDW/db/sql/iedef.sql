select
definc,
name,
beforeprocessproc
from impexp_definitions
where upper(name) like '%DIRECT%'
order by name;
select
procname,count(1)
from impexp_lines
where upper(name) like '%iDirect%'
group by procname
order by procname;
exit;
