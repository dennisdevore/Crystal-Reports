--
-- $Id$
--
create table custfacilityemail
(
  custid           varchar2(10) not null,
  facility         varchar2(3) not null,
  email            varchar2(255),
  lastuser         varchar2(12), 
  lastupdate       date
);

create unique index custfacilityemail_unique
  on custfacilityemail(custid, facility);
  
exit;  
