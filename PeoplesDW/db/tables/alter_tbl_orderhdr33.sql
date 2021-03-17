--
-- $Id: alter_tbl_orderhdr33.sql 606 2006-08-09 00:00:00Z eric $
--
alter table orderhdr add
(
   trailernosetemp      number(16,4),
   trailermiddletemp    number(16,4),
   trailertailtemp      number(16,4)
);

exit;
