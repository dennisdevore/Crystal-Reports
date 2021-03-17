--
-- $Id$
--
alter table labelprofileline add
(
   lpspath     varchar2(255)
)
modify
(
   scfpath     null
);
exit;
