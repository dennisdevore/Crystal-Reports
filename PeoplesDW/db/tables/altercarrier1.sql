--
-- $Id$
--
alter table carrier add(
	enableonetimeshipto char(1)
);

update carrier
set enableonetimeshipto = 'Y';

commit;

-- exit;
