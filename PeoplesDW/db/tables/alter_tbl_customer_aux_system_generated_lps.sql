--
-- $Id$
--
alter table customer_aux add
(
   system_generated_lps char(1) default 'N'
);

exit;
