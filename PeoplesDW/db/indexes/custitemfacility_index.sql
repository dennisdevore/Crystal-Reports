--
-- $Id$
--
drop index custitemfacility_unique;
drop index custprodgroupfacility_unique;
drop index customerfacility_unique;
drop index custfacility_unique;

create unique index custitemfacility_unique
   on custitemfacility(custid,item,facility);
create unique index custprodgroupfacility_unique
   on custproductgroupfacility(custid,productgroup,facility);
create unique index custfacility_unique
   on custfacility(custid,facility);
exit;
