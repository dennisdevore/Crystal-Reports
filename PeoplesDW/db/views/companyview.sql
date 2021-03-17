create or replace view companyview
(
company,
name,
state,
phone,
manager,
companystatus,
companystatusabbrev
)
as
select
company,
name,
state,
phone,
manager,
companystatus,
facilitystatus.abbrev
from company, facilitystatus
where company.companystatus = facilitystatus.code (+);

comment on table companyview is '$Id: companyview.sql 1 2005-05-26 12:20:03Z ed $';

exit;
