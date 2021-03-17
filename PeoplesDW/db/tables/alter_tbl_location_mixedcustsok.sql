--
-- $Id$
--
alter table location add
(
   mixedcustsok   char(1)
);

update location
   set mixedcustsok = 'Y'
   where mixedcustsok is null;

update location
   set mixeditemsok = 'Y'
   where mixeditemsok is null;

update location
   set mixedlotsok = 'Y'
   where mixedlotsok is null;

exit;
