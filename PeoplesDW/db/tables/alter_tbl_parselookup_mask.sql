--
-- $Id: alter_tbl_parselookup_mask.sql 9643 2013-03-06 18:50:44Z ed $
--
alter table parselookup modify
(
    lookupid            varchar2(12),
    mask                varchar2(50)
);

exit;
