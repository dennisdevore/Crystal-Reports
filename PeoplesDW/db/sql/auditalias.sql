--
-- $Id$
--
set serveroutput on;
select count(1)
from custitemalias;
select custid,item,itemalias
from custitemalias
where not exists
(select * from custitem
  where custitemalias.custid = custitem.custid
    and custitemalias.item = custitem.item);
delete
from custitemalias
where not exists
(select * from custitem
  where custitemalias.custid = custitem.custid
    and custitemalias.item = custitem.item);

--exit;

