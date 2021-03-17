--
-- $Id$
--
alter table waves add
(
	mass_manifest_labels  char(1)
);

update waves
   set mass_manifest_labels = 'N'
   where mass_manifest_labels is null;

exit;
