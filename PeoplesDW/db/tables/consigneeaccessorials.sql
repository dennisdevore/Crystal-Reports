--
-- $Id: consigneecarriers.sql 1 2005-05-26 12:20:03Z ed $
--
create table consigneeaccessorials ( 
  consignee            varchar2(10)  not null, 
  tariff               varchar2(12)  not null,
  freight_accessorials varchar2(4000),
  lastuser             varchar2(12), 
  lastupdate           date
); 

create unique index consigneeaccessorials_idx on 
  consigneeaccessorials(consignee, tariff); 

alter table consigneeaccessorials add constraint
  pk_consigneeaccessorials primary key (consignee, tariff)
  using index consigneeaccessorials_idx;

exit;
