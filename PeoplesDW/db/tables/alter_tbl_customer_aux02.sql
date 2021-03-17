--
-- $Id$
--
alter table customer_aux add
(
   allow_overpicking    char(1) default 'N'
);

exit;
