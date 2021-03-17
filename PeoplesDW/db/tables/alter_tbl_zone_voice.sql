--
-- $Id$
--
alter table zone add
(
   allow_voice_picking  char(1) default 'F'
);

exit;
