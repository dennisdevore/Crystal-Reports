--
-- $Id$
--
alter table asofinventory add(
   previousweight    number(13,4),
   currentweight     number(13,4)
);

exit;
