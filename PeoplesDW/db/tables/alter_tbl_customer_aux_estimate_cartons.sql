--
-- $Id$
--
alter table customer_aux add
(
   estimate_cartons  char(1) default 'N'
);

exit;
