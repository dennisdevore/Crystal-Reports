--
-- $Id$
--
alter table caselabels add
(
   auxtable    varchar2(30),
   auxkey      varchar2(30),
   quantity    number(7)
);

exit;
