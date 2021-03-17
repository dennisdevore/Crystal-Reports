--
-- $Id$
--
alter table caselabels add
(
   changeproc  varchar2(255),
   matched     char(1)
);

exit;
