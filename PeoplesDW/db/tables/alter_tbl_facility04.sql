--
-- $Id$
--
alter table facility add
(
   restrict_putaway char(1) default 'N'
);

update facility
   set restrict_putaway = 'N'
   where restrict_putaway is null;
  
commit;

exit;
