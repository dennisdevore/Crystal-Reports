--
-- $Id$
--
alter table orderdtlline add
(
dtlpassthrudate01		date,
dtlpassthrudate02		date,
dtlpassthrudate03		date,
dtlpassthrudate04		date,
dtlpassthrudoll01		number(10,2),
dtlpassthrudoll02		number(10,2),
qtyapproved         number(10)
);

exit;
