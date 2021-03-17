--
-- $Id$
--
alter table facility add
(
   use_location_checkdigit char(1)
);

update facility
   set use_location_checkdigit = 'Y'
   where use_location_checkdigit is null;

exit;
