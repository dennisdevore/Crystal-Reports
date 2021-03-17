--
-- $Id$
--
alter table orderhdr add
(
	hdrpassthrudate01		date,
	hdrpassthrudate02		date,
	hdrpassthrudate03		date,
	hdrpassthrudate04		date,
	hdrpassthrudoll01		number(10,2),
	hdrpassthrudoll02		number(10,2)
);

exit;
