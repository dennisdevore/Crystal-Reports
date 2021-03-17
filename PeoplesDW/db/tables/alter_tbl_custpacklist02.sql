--
-- $Id$
--
alter table custpacklist add
(
   packlistafteraudityn    char(1) default 'N'
);
exit;
