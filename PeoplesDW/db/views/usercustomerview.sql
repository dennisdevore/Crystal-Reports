CREATE OR REPLACE VIEW USERCUSTOMERVIEW
(
CUSTID,
NAMEID,
NAME )
AS
select
usercustomer.CUSTID,
usercustomer.NAMEID,
customer.NAME
from usercustomer, customer
where usercustomer.custid = customer.custid (+);

comment on table USERCUSTOMERVIEW is '$Id$';

exit;
