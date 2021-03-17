--
-- $Id$
--
create table facilitycarrierpronozone
(
  facility				varchar2(3) not null,
  carrier					varchar2(4) not null,
  zone          	varchar2(32),
  lastuser        varchar2(12),
  lastupdate      date
);
--exit;