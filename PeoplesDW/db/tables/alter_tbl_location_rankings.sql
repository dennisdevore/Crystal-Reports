--
-- $Id: alter_tbl_location_rankings.sql 6238 2011-03-04 20:05:13Z ed $
--
alter table location add
(
   lastranked     date,
   pickrank       char(1),
   putawayrank    char(1)
);

exit;
