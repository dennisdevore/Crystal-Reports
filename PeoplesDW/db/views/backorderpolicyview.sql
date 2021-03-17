create or replace view backorderpolicyview
(code
,abbrev
)
as
select
code,
abbrev
from backorderpolicy
union
select
'C',
'Cust Default'
from dual;

comment on table backorderpolicyview is '$Id$';

exit;
