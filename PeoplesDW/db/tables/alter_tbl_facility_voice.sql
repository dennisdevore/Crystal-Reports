--
-- $Id$
--
alter table facility add
(
   allow_voice_picking  char(1) default 'N'
);

exit;
