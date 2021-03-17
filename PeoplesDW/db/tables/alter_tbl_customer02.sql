--
-- $Id$
--
alter table customer add
(shortshipsmallpkgyn varchar2(1)
);
update customer
   set shortshipsmallpkgyn = 'N'
 where shortshipsmallpkgyn is null;
commit;
exit;
