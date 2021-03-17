set heading off
select
name,
beforeprocessprocparams
from impexp_definitions
where instr(beforeprocessprocparams,'''') != 0
order by name;
exit;
