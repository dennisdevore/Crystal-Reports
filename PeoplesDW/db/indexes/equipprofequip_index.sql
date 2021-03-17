--
-- $Id$
--
drop index pk_equipprofequip;
drop index equipprofequip_unique;

create unique index equipprofequip_unique on
  equipprofequip(profid,equipid);

exit;

