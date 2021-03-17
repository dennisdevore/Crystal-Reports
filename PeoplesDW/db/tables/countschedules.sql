--
-- $Id$
--
create table countschedules
(
   schedid 	number(*) not null,
   countid 	varchar2(36) not null,
  	period 	varchar2(22),
   datetime date,
   jobid    number(*),
   active 	char(1) default 'N'
);

exit;
