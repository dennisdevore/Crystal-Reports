create or replace view ws_useraccess
as
select a.nameid, b.custid, c.facility
from ws_userheader a, customer b, facility c
where (a.allcusts = 'A' or exists(select 1 from ws_usercustomer where nameid = a.nameid and custid = b.custid))
  and (a.chgfacility = 'A' or a.facility = c.facility or exists(select 1 from ws_userfacility where nameid = a.nameid and facility = c.facility));

exit;
