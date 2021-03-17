--
-- $Id$
--
alter table impexp_definitions add
(separatefiles char(1)
);
alter table oldexp_definitions add
(separatefiles char(1)
);
update impexp_definitions
   set separatefiles = 'N'
 where separatefiles is null;
commit;
exit;
