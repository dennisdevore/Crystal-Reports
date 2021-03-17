--
-- $Id$
--
alter table customer_aux add
(
   expanded_websynapse_fields   char(1) default 'N'
);

exit;
