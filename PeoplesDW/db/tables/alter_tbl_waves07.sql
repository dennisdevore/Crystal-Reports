--
-- $Id$
--
alter table waves add
(
	consolidated		varchar2(1),
   shiptype				varchar2(1),
   carrier				varchar2(4),
   servicelevel		varchar2(4),
 	shipcost          number(10,2),
 	weight  				number(13,4)
);

exit;
