--
-- $Id$
--
alter table custpacklist add(
    masterpacklist  char(1),
    masterpacklistrptfile   varchar2(255)
);
exit;
