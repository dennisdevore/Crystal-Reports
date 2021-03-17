--
-- $Id$
--
alter table impexp_chunks
add
(no_fieldprefix_on_null_value char(1)
);
alter table oldexp_chunks
add
(no_fieldprefix_on_null_value char(1)
);
alter table oldexp_chunks
modify
(fieldprefix varchar2(255)
);
update impexp_chunks
   set no_fieldprefix_on_null_value = 'Y'
 where no_fieldprefix_on_null_value is null;
commit;
--exit;
