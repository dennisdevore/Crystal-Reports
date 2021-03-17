--
-- $Id$
--
alter table customer_aux add
(
   ignore_anvdate_for_ret_cons   char(1) default 'N'
);

exit;
