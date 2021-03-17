--
-- $Id$
--
alter table customer_aux add
(
   allow_lineitem_weights  char(1) default 'N'
);

exit;
