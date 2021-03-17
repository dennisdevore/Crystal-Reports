--
-- $Id$
--
alter table custworkorderinstructions drop column destfacility;
alter table custworkorderinstructions drop column destlocation;
alter table custworkorderinstructions drop column destloctype;

exit;
