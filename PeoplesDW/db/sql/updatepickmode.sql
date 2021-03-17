--
-- $Id$
--
update userheader
	set pickmode = 'S'
	where usertype = 'U';
commit;
exit;

