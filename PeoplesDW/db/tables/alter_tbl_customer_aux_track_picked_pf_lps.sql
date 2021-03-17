--
-- $Id$
--
alter table customer_aux add
(
   track_picked_pf_lps  char(1)
);
update customer_aux
   set track_picked_pf_lps = 'N'
   where track_picked_pf_lps is null;

exit;
