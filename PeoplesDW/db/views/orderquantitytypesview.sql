create or replace view orderquantitytypesview
(code
,abbrev
)
as
select
code,
abbrev
from orderquantitytypes
union
select
'C',
'Cust Default'
from dual;

comment on table orderquantitytypesview is '$Id$';

exit;
