/*
 * @version $Id$
 */

create table custitemconsignee
(
  custid                   varchar2(10) not null,
  item varchar2(50) not null,
  consignee                varchar2(10) not null,
  min_days_to_expiration   number(4),
  lastuser                 varchar2(12),
  lastupdate               date
);

create unique index custitemconsignee_unique on 
    custitemconsignee(custid, item, consignee);
    
alter table custitemconsignee add (
  constraint pk_custitemconsignee
 primary key
 (custid, item, consignee));

exit;
