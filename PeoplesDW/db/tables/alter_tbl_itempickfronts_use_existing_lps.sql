--
-- $Id$
--
alter table itempickfronts add
(
   use_existing_lps  char(1) default 'N'
);


exit;
